#!/usr/bin/env ruby

require_relative 'lib/backlog'

require 'dotenv'
Dotenv.load

api_url = ENV['BACKLOG_API_URL']
api_key = ENV['BACKLOG_API_KEY']

api = Backlog::Client.new(api_url, api_key)
project_id = api.projects.filter { |project| project['name'] == 'main' }.first['id']

Backlog::Query.api_url = api_url
Backlog::Query.api_key = api_key

Backlog::Query.context do |ctx|
  ctx.project_id = project_id

  ctx.fetch_issue_types
  ctx.fetch_statuses
  ctx.fetch_issues({'count' => 100})

  sql =<<-SQL
SELECT coalesce(u.name, '担当者なし') as '担当者', count(*) FROM issues i
LEFT OUTER JOIN users u
ON i.assignee_id  = u.id
GROUP BY u.id;
SQL
  ctx.execute(sql) do |row|
    p row
  end
end

