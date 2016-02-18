require "active_support/core_ext/array"

module Susanin

  class Pattern
    include Enumerable

    def initialize(arr)
      @arr = Array.wrap(arr)
    end

    def each(&block)
      shifts.map do |s|
        a = @arr.slice(*s)
        block.call(a.size == 1 ? a[0] : a)
      end
    end

    def arr_size
      @arr.size
    end

    def shifts
      arr_size.downto(1).flat_map do |shift|
        (arr_size-shift).downto(0).map do |i|
          [0+i, shift]
        end
      end
    end

  end

end
