require "json"

module LibSQL
  struct Field
    include JSON::Serializable

    getter type : Type
    @[JSON::Field(converter: LibSQL::AnyToNilableStringConverter)]
    getter value : String?
    getter base64 : String?

    enum Type
      Null
      Integer
      Float
      Text
      Blob
    end
  end

  module AnyToNilableStringConverter
    def self.from_json(pull : JSON::PullParser) : String?
      case pull.kind
      when .null?
        pull.read_null
        nil
      when .bool?
        pull.read_bool.to_s
      when .int?
        pull.read_int.to_s
      when .float?
        pull.read_float.to_s
      when .string?
        pull.read_string
      else
        pull.skip
        nil
      end
    end

    def self.to_json(value : String?, json : JSON::Builder)
      if value
        json.string(value)
      else
        json.null
      end
    end
  end
end
