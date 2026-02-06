require "json"

require "./execute_response"
require "./pipeline_error"

module LibSQL
  struct PipelineResult
    include JSON::Serializable

    getter type : Type
    getter! response : ExecuteResponse
    getter error : PipelineError?

    enum Type
      OK
      Error
    end
  end
end
