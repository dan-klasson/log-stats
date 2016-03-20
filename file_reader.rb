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

