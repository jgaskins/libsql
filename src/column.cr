require "json"

module LibSQL
  struct Column
    include JSON::Serializable

    getter name : String
    @[JSON::Field(converter: LibSQL::Column::ColumnTypeConverter)]
    getter decltype : ColumnType?

    module ColumnTypeConverter
      extend self

      def from_json(json : ::JSON::PullParser)
        if value = String?.new(json)
          ColumnType.parse?(value)
        end
      end
    end
  end

  enum ColumnType
    INTEGER
    TEXT
    NULL
    REAL
    BLOB
  end
end
