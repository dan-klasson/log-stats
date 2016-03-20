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

