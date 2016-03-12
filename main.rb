#!/usr/bin/env ruby


class AccessParser

  attr_accessor :uri

  REGEX_MATCH_VARIABLES = /[^\s=]+=/
  REGEX_MATCH_QUOTES = /['"]+/

  Stats = Struct.new(:uri, :stats)
  Stat = Struct.new(:access_datetime, :type, :info, :request, :uri, :domain,
                                      :ip, :dyno, :connect, :service, :bytes)

  def initialize
    @parsed_data = []
  end

  def parse(line)
    line = line.gsub(REGEX_MATCH_VARIABLES, '')
    line = line.gsub(REGEX_MATCH_QUOTES, '')
    data = line.split

    uri = data[4]

    stat = Stat.new
    stat.access_datetime, stat.type, stat.info = data


    stats = Stats.new
    stats.uri = uri
    (stats.stats ||= []) << stat
    @parsed_data << stats

  end

end


class LogStat

  def initialize(parser)
    @parser = parser
  end

  #@todo: delegate this
  def parse(line)
    @parser.parse(line)
  end

  def output
  end
end

log = []
log << '012-02-07T09:43:06.123456+00:00 heroku[router]: at=info method=GET path="/stylesheets/dev-center/library.css" host=devcenter.heroku.com fwd="204.204.204.204" dyno=web.5 connect=1ms service=18ms status=200 bytes=13'
log << '012-02-07T09:43:06.123456+00:00 heroku[router]: at=info method=GET path="/stylesheets/dev-center/library.css" host=devcenter.heroku.com fwd="204.204.204.204" dyno=web.5 connect=1ms service=18ms status=200 bytes=13'
log << '012-02-07T09:43:06.123456+00:00 heroku[router]: at=info method=GET path="/stylesheets/dev-center/library.css" host=devcenter.heroku.com fwd="204.204.204.204" dyno=web.5 connect=1ms service=18ms status=200 bytes=13'
log << '012-02-07T09:43:06.123456+00:00 heroku[router]: at=info method=GET path="/stylesheets/dev-center/library.css" host=devcenter.heroku.com fwd="204.204.204.204" dyno=web.5 connect=1ms service=18ms status=200 bytes=13'

parser = AccessParser.new
has = LogStat.new(parser)


log.each do |line|
  has.parse line
end

has.output
