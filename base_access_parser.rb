require 'forwardable'

class BaseAccessParser
  extend Forwardable

  def_delegators :@reader, :read, :endpoints

  def initialize(reader)
    @reader = reader
  end

  private

  def line_to_hash(line)
    # using split because it's faster than regex
    Hash[line.split.each.map { |a| a.split('=') }]
  end

end

