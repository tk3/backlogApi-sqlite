#!/usr/bin/env ruby

require 'net/http'
require 'json'

module Backlog
  module Request
    def get(api_path, params = {})
      url = URI.parse(@endpoint)

      query_string = {'apiKey' => @api_key}
      url.path = url.path + api_path
      url.query = URI.encode_www_form(query_string.merge(params))

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Get.new(url.request_uri)
      req['User-Agent'] = 'blg ' + Backlog::VERSION
      req['Accept'] = 'application/json'
      res = http.request(req)

      JSON.parse(res.body)
    end
  end
end

module Backlog
  module Api
    module Space
      def space
        get('/space')
      end
    end
  end
end

module Backlog
  module Api
    module User
      def users
        get('/users')
      end
    end
  end
end

module Backlog
  module Api
    module Project
      def projects(params = {})
        get('/projects')
      end

      def versions(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/versions')
      end
    end

    module Category
      def categories(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/categories')
      end
    end

    module Status
      def statuses(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/statuses')
      end
    end

    module IssueType
      def issueTypes(project_id_or_key)
        get('/projects/' + project_id_or_key.to_s + '/issueTypes')
      end
    end
  end
end

module Backlog
  module Api
    module Priority
      def priorities(params = {})
        get('/priorities')
      end
    end
  end
end

module Backlog
  module Api
    module Issue
      def issues(params = {})
        get('/issues', params)
      end
    end
  end
end

module Backlog
  module Api
  end
end

module Backlog
  VERSION = '0.0.1'
end

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

    def initialize(endpoint, api_key)
      @endpoint = endpoint
      @api_key = api_key
    end

  end
end


if __FILE__ == $0
  require 'dotenv'
  Dotenv.load

  endpoint = ENV['BACKLOG_API_ENDPOINT']
  api_key = ENV['BACKLOG_API_KEY']

  api = Backlog::Client.new(endpoint, api_key)

  puts "projects --------"
  projects = api.projects

  pp projects
  puts "issues --------"
  pp api.issues({'projectId[]' => projects[0]['id']})
  puts "--------"
  pp api.issues({'issueTypeId[]' => 656377})

  exit 0

  require 'pp'

  puts "space --------"
  pp api.space

  puts "projects --------"
  projects = api.projects
  pp projects
  pp api.projects({:archived => true})

  puts "issues --------"
  pp api.issues

  puts "versions --------"
  pp api.versions(projects[0]['id'])

  puts "categories --------"
  pp api.categories(projects[0]['id'])

  puts "users --------"
  pp api.users

  puts "priorities --------"
  pp api.priorities

  puts "statuses--------"
  pp api.statuses(projects[0]['id'])

  puts "issueTypes --------"
  pp api.issueTypes(projects[0]['id'])
end


