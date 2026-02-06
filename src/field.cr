require "json"

module LibSQL
  struct Field
    include JSON::Serializable

    getter type : Type
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
end
