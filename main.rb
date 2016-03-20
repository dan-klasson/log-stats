#!/usr/bin/env ruby

class FileReader

  def initialize(filename, start_at = nil, end_at = nil, endpoints = nil)
    @filename = filename
    @start_at = start_at
    @end_at = end_at
    @endpoints = endpoints
  end

  def read
    File.foreach(@filename).map { |l|
      # saving some memory here by only loading data into memory that we need
      unless @start_at.nil? or @end_at.nil?
        start = l.index(@start_at)
        finish = l.index(@end_at) - 2
        l[start..finish]
      else
        l
      end
    }
  end

  def endpoints
    File.foreach(@endpoints).map { |line| line.split }
  end

end


require 'forwardable'

class AccessParser
  extend Forwardable

  def_delegators :@reader, :read, :endpoints

  REGEX_MATCH_DIGITS = /\d+/
  PLACEHOLDER = '{user_id}'

  Uris = Struct.new(:method, :uri, :stats)
  Stats = Struct.new(:dyno, :response_time)

  def initialize(reader)
    @reader = reader
  end

  def parse

    uris = endpoints_to_uris

    read.each.map { |line|

      data = line_to_hash line

      method = data['method']
      uri = data['path'].sub(REGEX_MATCH_DIGITS, PLACEHOLDER)

      uris.each.map { |e|
        if uri == e.uri.to_s and method == e.method
          (e.stats.dyno ||= []) << data['dyno']
          response_time = data['connect'].to_i + data['service'].to_i
          (e.stats.response_time ||= []) << response_time
        end
      }
    }
    uris

  end

  private

  def endpoints_to_uris
    # using structs because it's faster than hashes
    endpoints.each.map { |e| Uris.new(*e, Stats.new) }
  end

  def line_to_hash(line)
    # using split because it's faster than regex
    Hash[line.split.each.map { |a| a.split('=') }]
  end

end

module Enumerable

  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean
    sum / size
  end

  def median
    len = sort.length
    (sort[(len - 1) / 2] + sort[len / 2]) / 2.0
  end

  def mode
    counter = Hash.new(0)
    entries.each.map { |i| counter[i] += 1 }
    mode_array = []
    counter.each.map { |k, v|  mode_array << k if v == counter.values.max }
    mode_array.sort.first
  end
end

class AccessConsoleWriter
  extend Forwardable

  def_delegators :@parser, :parse

  def initialize(parser)
    @parser = parser
  end

  def call
    parse.each do |d|
      puts "# #{d.method} #{d.uri}"
      puts "# " + "-" * (d.uri.length + d.method.length + 1)
      if d.stats.dyno.nil?
        puts "# Calls: 0"
      else
        puts "# Calls: #{d.stats.dyno.count}"
        puts "# Mean: #{d.stats.response_time.mean.round(2)}"
        puts "# Median: #{d.stats.response_time.median.round(2)}"
        puts "# Mode: #{d.stats.response_time.mode}"
        puts "# Dyno: #{d.stats.dyno.mode}"
      end
      puts ""

    end
  end

end


reader = FileReader.new('sample.log', 'method=', 'status=', 'endpoints.txt')
parser = AccessParser.new(reader)
AccessConsoleWriter.new(parser).call


