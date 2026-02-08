require "json"
require "http/client"
require "base64"

require "./statement"
require "./pipeline_response"

module LibSQL
  class Connection < ::DB::Connection
    @baton : String? = nil
    @in_transaction = false

    def initialize(options : ::DB::Connection::Options, uri : URI)
      super options

      host = uri.host || "localhost"
      port = uri.port || 443
      if token = uri.password
        authorization = "Bearer #{token}"
      end
      @http = HTTP::Client.new(host, port, tls: true)
      @http.before_request do |request|
        request.headers["Content-Type"] = "application/json"
        if authorization
          request.headers["Authorization"] = authorization
        end
      end
    end

    def build_prepared_statement(query) : Statement
      Statement.new(self, query)
    end

    def build_unprepared_statement(query) : Statement
      Statement.new(self, query)
    end

    def execute_sql(query : String, args : Enumerable) : QueryResult
      body = build_pipeline_body(query, args)

      response = @http.post("/v3/pipeline", body: body)

      unless response.status.success?
        raise DB::ConnectionRefused.new("#{response.status_code}: #{response.body}")
      end

      pipeline = PipelineResponse.from_json(response.body)
      @baton = pipeline.baton
      first_result = pipeline.results[0]

      if first_result.type.error?
        raise DB::Error.new(first_result.error.try(&.message))
      end

      first_result.response.result.not_nil!
    end

    private def build_pipeline_body(query : String, args : Enumerable) : String
      JSON.build do |json|
        json.object do
          if baton = @baton
            json.field "baton", baton
          end
          json.field "requests" do
            json.array do
              json.object do
                json.field "type", "execute"
                json.field "stmt" do
                  json.object do
                    json.field "sql", query
                    json.field "args" do
                      json.array do
                        args.each do |arg|
                          encode_arg(json, arg)
                        end
                      end
                    end
                  end
                end
              end
              unless @in_transaction
                json.object do
                  json.field "type", "close"
                end
              end
            end
          end
        end
      end
    end

    private def encode_arg(json : JSON::Builder, value : Nil)
      json.object { json.field "type", "null" }
    end

    private def encode_arg(json : JSON::Builder, value : Bool)
      json.object do
        json.field "type", "integer"
        json.field "value", value ? "1" : "0"
      end
    end

    private def encode_arg(json : JSON::Builder, value : Int)
      json.object do
        json.field "type", "integer"
        json.field "value", value.to_s
      end
    end

    private def encode_arg(json : JSON::Builder, value : Float)
      json.object do
        json.field "type", "float"
        json.field "value", value.to_f64
      end
    end

    private def encode_arg(json : JSON::Builder, value : String)
      json.object do
        json.field "type", "text"
        json.field "value", value
      end
    end

    private def encode_arg(json : JSON::Builder, value : Bytes)
      json.object do
        json.field "type", "blob"
        json.field "base64" do
          json.string do |io|
            Base64.strict_encode value, io
          end
        end
      end
    end

    private def encode_arg(json : JSON::Builder, value : Time)
      json.object do
        json.field "type", "text"
        json.field "value" do
          json.string do |io|
            value.to_rfc3339 io, fraction_digits: 9
          end
        end
      end
    end

    private def encode_arg(json : JSON::Builder, value)
      json.object do
        json.field "type", "text"
        json.field "value", value.to_s
      end
    end

    def perform_begin_transaction
      @in_transaction = true
      execute_sql("BEGIN", [] of String)
    end

    def perform_commit_transaction
      execute_sql("COMMIT", [] of String)
      @baton = nil
      @in_transaction = false
    end

    def perform_rollback_transaction
      execute_sql("ROLLBACK", [] of String)
      @baton = nil
      @in_transaction = false
    end

    protected def do_close
      super
      @http.close
    end
  end
end
