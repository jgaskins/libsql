require "json"

module LibSQL
  struct Column
    include JSON::Serializable

    getter name : String
    getter decltype : ColumnType?
  end

  enum ColumnType
    INTEGER
    TEXT
    NULL
    REAL
    BLOB
  end
end
