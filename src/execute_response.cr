require "json"

require "./query_result"

module LibSQL
  struct ExecuteResponse
    include JSON::Serializable

    getter type : String
    getter result : QueryResult?
  end
end
