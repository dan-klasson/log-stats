#!/usr/bin/env ruby

require 'forwardable'

class FileReader

  Endpoint = Struct.new(:uri, :method, :stats)
  STAT_COLUMNS = [:access_datetime, :type, :info, :method, :uri, :host,
         :ip, :dyno, :connect, :service, :status, :bytes, :response_time]
  Stats = Struct.new(*STAT_COLUMNS)

  def initialize(filename, start_at = nil, end_at = nil, endpoints = nil)
    @filename = filename
    @start_at = start_at
    @end_at = end_at
    @endpoints = endpoints
  end

  def read
    content = []
    File.foreach(@filename) do |l|
      # we save some memory here by only loading data into memory that we need
      unless @start_at.nil? or @end_at.nil?
        start = l.index(@start_at)
        finish = l.index(@end_at) - 2
        content << l[start..finish]
      else
        content << l
      end
    end
    content
  end

  def endpoints
    content = []
    File.foreach(@endpoints) do |line|
      endpoint = Endpoint.new
      endpoint.method, endpoint.uri = line.split
      endpoint.stats = Stats.new
      content << endpoint
    end
    content
  end

end

class AccessParser
  extend Forwardable

  def_delegators :@reader, :read, :endpoint

  REGEX_MATCH_VARIABLES = /[^\s=]+=/
  REGEX_MATCH_QUOTES = /['"]+/
  REGEX_MATCH_DIGITS = /\d+/
  PLACEHOLDER = '{user_id}'

  STAT_COLUMNS = [:method, :host, :dyno, :connect, :service, :response_time]
  Stats = Struct.new(*STAT_COLUMNS)
  Uris = Struct.new(:method, :uri, :stats)

  def initialize(reader)
    @reader = reader
    @data = @reader.read
    @content = {}
  end

  def parse

    uris = []
    uris << Uris.new('GET', '/api/users/{user_id}/count_pending_messages', Stats.new)
    uris << Uris.new('GET', '/api/users/{user_id}/get_messages', Stats.new)

    @data.each do |d|
      arr = d.split
      puts arr[0].split('=')
      puts arr[1].split('=')
      puts arr[2].split('=')
      puts arr[3].split('=')
      puts arr[4].split('=')
      puts arr[5].split('=')
      abort
      method = parse_column(arr[0])
      uri = parse_column(arr[1]).sub(REGEX_MATCH_DIGITS, PLACEHOLDER)
      uris.each do |e|
        if uri == e.uri.to_s and method == e.method
          line = parse_column(d)
          data = line.split
          stat = e.stats
          (stat.method ||= []) << data[0]
          (stat.dyno ||= []) << data[4]
          (stat.connect ||= []) << data[5].to_i
          (stat.service ||= []) << data[6].to_i
          (stat.response_time ||= []) << data[5].to_i + data[6].to_i
        end
      end
    end
    #puts uris
    uris

  end

  private

  def parse_column(column)
    column = column.gsub(REGEX_MATCH_VARIABLES, '')
    column = column.gsub(REGEX_MATCH_QUOTES, '')
    column
  end

end

require 'simple_stats'
class AccessConsoleWriter

  def write(data)
    data.each do |d|
      puts "# #{d.uri}"
      puts "# " + "-" * d.uri.length
      puts "# Calls: #{d.uri.sum}"
      puts "# Mean: #{d.stats.response_time.mean.round(2)}"
      puts "# Median: #{d.stats.response_time.median.round(2)}"
      puts "# Mode: #{d.stats.response_time.modes[0]}"
      puts "# Dyno: #{d.stats.dyno.modes[0]}"
      puts ""

    end
  end

end


class LogStat
  extend Forwardable

  def_delegators :@parser, :parse

  def initialize(parser, writer)
    @parser = parser
    @writer = writer
    process
  end

  def process

  end

  def output
    @writer.write @parser.parse
  end

end

reader = FileReader.new('sample.log', 'method=', 'status=', 'endpoints.txt')
parser = AccessParser.new(reader)
writer = AccessConsoleWriter.new
LogStat.new(parser, writer).output


