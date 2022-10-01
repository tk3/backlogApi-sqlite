#!/usr/bin/env ruby

require 'net/http'
require 'json'

module Blg
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
      req['User-Agent'] = 'blg ' + Blg::VERSION
      req['Accept'] = 'application/json'
      res = http.request(req)

      JSON.parse(res.body)
    end
  end
end

module Blg
  module Api
    module Space
      def space
        get('/space')
      end
    end
  end
end

module Blg
  module Api
    module User
      def users
        get('/users')
      end
    end
  end
end

module Blg
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

module Blg
  module Api
    module Priority
      def priorities(params = {})
        get('/priorities')
      end
    end
  end
end

module Blg
  module Api
    module Issue
      def issues(params = {})
        get('/issues', params)
      end
    end
  end
end

module Blg
  module Api
  end
end

module Blg
  VERSION = '0.0.1'
end

module Blg

  class Client
    include Blg::Request
    include Blg::Api::User
    include Blg::Api::Space
    include Blg::Api::Project
    include Blg::Api::Category
    include Blg::Api::Status
    include Blg::Api::IssueType
    include Blg::Api::Issue
    include Blg::Api::Priority

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

  api = Blg::Client.new(endpoint, api_key)

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


