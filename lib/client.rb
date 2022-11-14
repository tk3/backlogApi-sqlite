module Backlog
  class Client
    include Backlog::Request
    include Backlog::Api::User
    include Backlog::Api::Space
    include Backlog::Api::Project
    include Backlog::Api::Category
    include Backlog::Api::Status
    include Backlog::Api::IssueType
    include Backlog::Api::Issue
    include Backlog::Api::Priority

    def initialize(api_url, api_key)
      @api_url = api_url
      @api_key = api_key
    end
  end
end

