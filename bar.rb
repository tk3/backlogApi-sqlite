#!/usr/bin/env ruby

require_relative 'lib/backlog'

require 'dotenv'
Dotenv.load

api_url = ENV['BACKLOG_API_URL']
api_key = ENV['BACKLOG_API_KEY']

api = Backlog::Client.new(api_url, api_key)

project_id = api.projects.filter { |project| project['name'] == 'main' }.first['id']

Backlog::Query.api_url = ENV['BACKLOG_API_URL']
Backlog::Query.api_key = ENV['BACKLOG_API_KEY']

Backlog::Query.context do |ctx|
  ctx.project_id = project_id

  ctx.fetch_issue_types
  ctx.fetch_statuses
  ctx.fetch_issues({'count' => 100})

  ctx.execute('SELECT * FROM issue_types') do |row|
    p row
  end

  ctx.execute('SELECT * FROM statuses') do |row|
    p row
  end

  ctx.execute('SELECT * FROM issues') do |row|
    p row
  end

  ctx.execute('SELECT * FROM users') do |row|
    p row
  end

  sql =<<-SQL
SELECT u.name, count(*) FROM issues i
INNER JOIN users u
ON i.assignee_id  = u.id
GROUP BY u.id
SQL
  ctx.execute(sql) do |row|
    p row
  end
end

