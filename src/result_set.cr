require "uuid"
require "base64"

require "./query_result"

module LibSQL
  class ResultSet < ::DB::ResultSet
    @row_index = -1
    @column_index = 0
    @result : QueryResult

    def initialize(statement : ::DB::Statement, @result)
      super(statement)
      @columns = @result.cols
      @rows = @result.rows
    end

    def move_next : Bool
      @row_index += 1
      @column_index = 0
      @row_index < @rows.size
    end

    def column_count : Int32
      @columns.size
    end

    def column_name(index : Int32) : String
      @columns[index].name
    end

    def next_column_index : Int32
      @column_index
    end

    def read
      value = @rows[@row_index][@column_index]
      @column_index += 1
      decode_value(value)
    end

    def read(t : Int32.class) : Int32
      read(Int64).to_i32
    end

    def read(t : Float32.class) : Float32
      read(Float64).to_f32
    end

    def read(t : UUID.class) : UUID
      UUID.new(read(String))
    end

    def read(t : Time.class) : Time
      parse_time(read(String))
    end

    private def parse_time(str : String) : Time
      Time.parse(str, "%F %T", Time::Location::UTC)
    rescue Time::Format::Error
      Time.parse_rfc3339(str)
    end

    private def decode_value(value : Field)
      case value.type
      in .null?
        nil
      in .integer?
        value.value.not_nil!.to_i64
      in .float?
        value.value.not_nil!.to_f64
      in .text?
        value.value.not_nil!
      in .blob?
        Base64.decode(value.base64.not_nil!)
      end
    end
  end
end
