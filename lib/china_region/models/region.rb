module ChinaRegion
  # Main model, stores all information about what happened
  class Region < inherit_orm("Region")
    include Query

    def type
      @type ||= Match.type_of(code)
    end
    # 获取父级行政区的 code
    def parent_code
      Match.upper_level(code)
    end
    # 补全 code 12位
    # example:
    #  1101 => 110100000000
    def full_code
      code.ljust(12, '0')
    end

    def ==(other)
      code == other.code
    end
  end
end
