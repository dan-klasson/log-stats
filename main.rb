#!/usr/bin/env ruby

class FileReader

  Endpoint = Struct.new(:uri, :method)

  def initialize(filename, endpoints = nil)
    @filename = filename
    @endpoints = endpoints
  end

  def read
    content = []
    File.foreach(@filename) do |line|
      content << line
    end
    content
  end

  def endpoint
    content = []
    endpoint = Endpoint.new
    File.foreach(@endpoints) do |line|
      endpoint.method, endpoint.uri = line.split
      content << endpoint
    end
    content
  end

end

class AccessParser

  REGEX_MATCH_VARIABLES = /[^\s=]+=/
  REGEX_MATCH_QUOTES = /['"]+/
  REGEX_MATCH_DIGITS = /\d+/
  PLACEHOLDER = '{user_id}'

  Stats = Struct.new(:uri, :stats)
  Stat = Struct.new(:access_datetime, :type, :info, :method, :uri, :host,
                           :ip, :dyno, :connect, :service, :status, :bytes)

  def initialize
    @content = {}
  end

  def parse(line)
    line = line.gsub(REGEX_MATCH_VARIABLES, '')
    line = line.gsub(REGEX_MATCH_QUOTES, '')
    line = line.sub(REGEX_MATCH_DIGITS, PLACEHOLDER)
    data = line.split

    assign_stat(data)

    stats = Stats.new
    stats.uri = @stat.uri
    (stats.stats ||= []) << @stat
    stats

  end

  private

  def assign_stat(data)
    stat = Stat.new

    stat.access_datetime = data[0]
    stat.type = data[1]
    stat.info = data[2]
    stat.method = data[3]
    stat.uri = data[4]
    stat.host = data[5]
    stat.ip = data[6]
    stat.dyno = data[7]
    stat.connect = data[8]
    stat.service = data[9]
    stat.status = data[10]
    stat.bytes = data[11]

    @stat = stat
  end

end

class AccessConsoleWriter

  def write(data)
    data.each do |d|
      #puts d.stats[0].uri
    end
  end

end

require 'forwardable'

class LogStat
  extend Forwardable

  def_delegators :@reader, :read, :endpoint
  def_delegators :@parser, :parse

  def initialize(reader, parser, writer)
    @reader = reader
    @parser = parser
    @writer = writer
    process
  end

  def process
    @data = read.map { |line| parse line }

    @data.each do |d|
      endpoint.each do |e|
        puts d
        if d.uri == e.uri and d.stats.method == e.method
          puts d.uri
        end
      end
    end
  end

  def output
    @writer.write @data
  end

end

reader = FileReader.new('sample.log', 'endpoints.txt')
parser = AccessParser.new
writer = AccessConsoleWriter.new
LogStat.new(reader, parser, writer).output

