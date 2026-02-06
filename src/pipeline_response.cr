require "json"

require "./pipeline_result"

module LibSQL
  struct PipelineResponse
    include JSON::Serializable

    getter baton : String?
    getter base_url : String?
    getter results : Array(PipelineResult)
  end
end
