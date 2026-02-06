require "json"

require "./column"
require "./field"
require "./string_to_int64_converter"
require "./time_span_converter"

module LibSQL
  struct QueryResult
    include JSON::Serializable

    getter cols : Array(Column)
    getter rows : Array(Array(Field))
    @[JSON::Field(converter: LibSQL::StringToInt64Converter)]
    getter affected_row_count : Int64
    @[JSON::Field(converter: LibSQL::NilableStringToInt64Converter)]
    getter last_insert_rowid : Int64?
    @[JSON::Field(converter: LibSQL::NilableStringToInt64Converter)]
    getter replication_index : Int64?
    @[JSON::Field(converter: LibSQL::StringToInt64Converter)]
    getter rows_read : Int64
    @[JSON::Field(converter: LibSQL::StringToInt64Converter)]
    getter rows_written : Int64
    @[JSON::Field(key: "query_duration_ms", converter: LibSQL::TimeSpanConverter)]
    getter query_duration : Time::Span
  end
end
