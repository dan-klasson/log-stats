#!/usr/bin/env ruby

require_relative 'file_reader'
require_relative 'heroku_access_parser'
require_relative 'enumerable'
require_relative 'access_control_writer'

reader = FileReader.new('sample.log', 'method=', 'status=', 'endpoints.txt')
parser = HerokuAccessParser.new(reader)
AccessConsoleWriter.new(parser).call


