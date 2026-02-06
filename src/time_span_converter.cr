require "json"

module LibSQL
  module TimeSpanConverter
    extend self

    def from_json(json : JSON::PullParser)
      json.read_float.milliseconds
    end

    def to_json(value : Time::Span, json : JSON::Builder)
      json.number value.total_milliseconds
    end
  end
end
