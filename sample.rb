#!/usr/bin/env ruby

require_relative 'backlog'
require_relative 'backlog_query'

require 'dotenv'
Dotenv.load

endpoint = ENV['BACKLOG_API_ENDPOINT']
api_key = ENV['BACKLOG_API_KEY']

api = Backlog::Client.new(endpoint, api_key)
project_id = api.projects.filter { |project| project['name'] == 'main' }.first['id']

Backlog::Query.endpoint = endpoint
Backlog::Query.api_key = api_key
Backlog::Query.output_db = 'aaaa.db'

Backlog::Query.context do |ctx|
  ctx.project_id = project_id

  ctx.fetch_issue_types
  ctx.fetch_statuses
  ctx.fetch_issues {'count' => 100}

end

