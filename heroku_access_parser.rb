require_relative 'base_access_parser'

class HerokuAccessParser < BaseAccessParser

  REGEX_MATCH_DIGITS = /\d+/
  PLACEHOLDER = '{user_id}'

  Uris = Struct.new(:method, :uri, :stats)
  Stats = Struct.new(:dyno, :response_time)

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

end

