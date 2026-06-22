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

    # Overload read(type : T.class) to handle Union/nilable types and custom type conversions
    def read(type : T.class) : T forall T
      {% if T <= DB::Mappable || T <= Enum %}
        super
      {% else %}
        col_index = next_column_index
        {% if T.union? %}
          value = read
          if value.nil?
            {% if T.nilable? %}
              nil.as(T)
            {% else %}
              raise DB::ColumnTypeMismatchError.new(
                context: "#{self.class}#read",
                column_index: col_index,
                column_name: column_name(col_index),
                column_type: "Nil",
                expected_type: T.to_s
              )
            {% end %}
          else
            {% non_nil_types = T.union_types.reject(&.== Nil) %}
            {% if non_nil_types.size == 1 %}
              convert_value(value, {{non_nil_types[0]}}, col_index).as(T)
            {% else %}
              {% for sub_t in non_nil_types %}
                if value.is_a?({{sub_t}})
                  return value.as(T)
                end
              {% end %}
              raise DB::ColumnTypeMismatchError.new(
                context: "#{self.class}#read",
                column_index: col_index,
                column_name: column_name(col_index),
                column_type: value.class.to_s,
                expected_type: T.to_s
              )
            {% end %}
          end
        {% else %}
          value = read
          if value.is_a?(T)
            value
          else
            convert_value(value, T, col_index)
          end
        {% end %}
      {% end %}
    end

    private def convert_value(value, t : T.class, col_index : Int32) : T forall T
      {% if T == Bool %}
        if value.is_a?(Int64)
          (value != 0).as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "Bool"
          )
        end
      {% elsif T == Int32 %}
        if value.is_a?(Int64)
          value.to_i32.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "Int32"
          )
        end
      {% elsif T == Int8 %}
        if value.is_a?(Int64)
          value.to_i8.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "Int8"
          )
        end
      {% elsif T == Int16 %}
        if value.is_a?(Int64)
          value.to_i16.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "Int16"
          )
        end
      {% elsif T == UInt8 %}
        if value.is_a?(Int64)
          value.to_u8.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "UInt8"
          )
        end
      {% elsif T == UInt16 %}
        if value.is_a?(Int64)
          value.to_u16.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "UInt16"
          )
        end
      {% elsif T == UInt32 %}
        if value.is_a?(Int64)
          value.to_u32.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "UInt32"
          )
        end
      {% elsif T == UInt64 %}
        if value.is_a?(Int64)
          value.to_u64.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "UInt64"
          )
        end
      {% elsif T == Float32 %}
        if value.is_a?(Float64)
          value.to_f32.as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "Float32"
          )
        end
      {% elsif T == UUID %}
        if value.is_a?(String)
          UUID.new(value).as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "UUID"
          )
        end
      {% elsif T == Time %}
        if value.is_a?(String)
          parse_time(value).as(T)
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: "Time"
          )
        end
      {% else %}
        if value.is_a?(T)
          value
        else
          raise DB::ColumnTypeMismatchError.new(
            context: "#{self.class}#read",
            column_index: col_index,
            column_name: column_name(col_index),
            column_type: value.class.to_s,
            expected_type: T.to_s
          )
        end
      {% end %}
    end

    def read(t : Bool.class) : Bool
      read(Int64) != 0
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
