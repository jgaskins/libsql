require "json"

module LibSQL
  module StringToInt64Converter
    extend self

    def from_json(json : JSON::PullParser)
      if json.kind.string?
        json.read_string.to_i64
      else
        json.read_int
      end
    end

    def to_json(value : Int64, json : JSON::Builder)
      json.number value
    end
  end

  module NilableStringToInt64Converter
    extend self

    def from_json(json : JSON::PullParser)
      if json.kind.null?
        json.read_null
        nil
      elsif json.kind.string?
        json.read_string.to_i64
      else
        json.read_int
      end
    end

    def to_json(value : Int64?, json : JSON::Builder)
      if value.nil?
        json.null
      else
        json.number value
      end
    end
  end
end
