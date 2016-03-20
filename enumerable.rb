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


