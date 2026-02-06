require "json"

require "./column"
require "./field"
require "./time_span_converter"

module LibSQL
  struct QueryResult
    include JSON::Serializable

    getter cols : Array(Column)
    getter rows : Array(Array(Field))
    getter affected_row_count : Int64
    getter last_insert_rowid : Int64?
    getter replication_index : Int64?
    getter rows_read : Int64
    getter rows_written : Int64
    @[JSON::Field(key: "query_duration_ms", converter: LibSQL::TimeSpanConverter)]
    getter query_duration : Time::Span
  end
end
