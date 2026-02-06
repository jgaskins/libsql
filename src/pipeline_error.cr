require "json"

module LibSQL
  struct PipelineError
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    getter message : String
  end
end
