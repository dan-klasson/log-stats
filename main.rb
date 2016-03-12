#!/usr/bin/env ruby


class FileReader

  def initialize(filename)
    @filename = filename
  end

  def read
    content = []
    File.foreach(@filename) do |line|
      content << line
    end
    content
  end

end

class AccessParser

  attr_accessor :uri

  REGEX_MATCH_VARIABLES = /[^\s=]+=/
  REGEX_MATCH_QUOTES = /['"]+/

  Stats = Struct.new(:uri, :stats)
  Stat = Struct.new(:access_datetime, :type, :info, :method, :uri, :host,
                           :ip, :dyno, :connect, :service, :status, :bytes)

  def initialize(endpoints)
    @endpoints = endpoints
    @parsed_data = []
  end

  def parse(line)
    line = line.gsub(REGEX_MATCH_VARIABLES, '')
    line = line.gsub(REGEX_MATCH_QUOTES, '')
    data = line.split

    uri = data[4]

    stats = Stats.new
    stats.uri = uri
    (stats.stats ||= []) << assign_stat(data)
    stats

  end

  private

  def assign_stat(data)
    stat = Stat.new

    stat.access_datetime = data[0]
    stat.type = data[1]
    stat.info = data[2]
    stat.method = data[3]
    stat.host = data[5]
    stat.ip = data[6]
    stat.dyno = data[7]
    stat.connect = data[8]
    stat.service = data[9]
    stat.status = data[10]
    stat.bytes = data[11]

    stat
  end



end

class AccessConsoleWriter

  def write(data)
    data.each do |d|
      puts d.stats[0].ip
    end
  end

end

require 'forwardable'

class LogStat
  extend Forwardable

  def_delegators :@reader, :read
  def_delegators :@parser, :parse

  def initialize(reader, parser, writer)
    @reader = reader
    @parser = parser
    @writer = writer
  end

  def output
    data = read.map { |line| parse(line) }
    @writer.write data
  end

end

endpoints = %w(
GET /api/users/{user_id}/count_pending_messages
GET /api/users/{user_id}/get_messages
GET /api/users/{user_id}/get_friends_progress
GET /api/users/{user_id}/get_friends_score
POST /api/users/{user_id}
GET /api/users/{user_id}
)

reader = FileReader.new('/home/dan/Downloads/sample.log')
parser = AccessParser.new(endpoints)
writer = AccessConsoleWriter.new
LogStat.new(reader, parser, writer).output

