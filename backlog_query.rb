#!/usr/bin/env ruby

require_relative 'backlog'
require 'sqlite3'

module Backlog
  class Query
    @@endpoint = nil
    @@api_key = nil
    @@output_db = ':memory:'

    def self.context(&block)
      raise 'Cannot set endpoint' if @@endpoint.nil?
      raise 'Cannot set api_key' if @@api_key.nil?

      api = Backlog::Client.new(@@endpoint, @@api_key)
      Backlog::Context.new(api, @@output_db, &block)
    end

    def self.endpoint=(value)
      @@endpoint = value
    end

    def self.api_key=(value)
      @@api_key = value
    end

    def self.output_db=(value)
      @@output_db = value
    end
  end

  class Schema
    def self.create_table(db)
      db.execute(issues_table)
      db.execute(users_table)
      db.execute(statuses_table)
      db.execute(issue_types_table)
    end

    def self.issues_table
<<-SQL
CREATE TABLE issues (
  id            integer unique,
  summary       text,
  issue_type_id integer,
  status_id     integer,
  assignee_id   integer,
  due_date       text
);
SQL
    end

    def self.users_table
<<-SQL
CREATE TABLE users (
  id   integer unique,
  name text
);
SQL
    end

    def self.statuses_table
<<-SQL
CREATE TABLE statuses (
  id   integer unique,
  name text
);
SQL
    end

    def self.issue_types_table
<<-SQL
CREATE TABLE issue_types (
  id   integer unique,
  name text
);
SQL
    end

  end

  class Context
    attr_accessor :project_id

    def initialize(api, db = ':memory:')
      @api = api
      @db = SQLite3::Database.new db
      Schema.create_table(@db)
 
      yield(self) if block_given?
    end

    def execute(*bind_vars, &block)
      @db.execute(*bind_vars, &block)
    end

    def fetch_issues(params = {})
      issues = @api.issues(params)
      issues.each do |issue|
        if !record_exists('issues', issue['id'])
          assignee = if issue['assignee'] == nil
                       {'id' => nil}
                     else
                       issue['assignee']
                     end
          @db.execute 'INSERT INTO issues VALUES (?, ?, ?, ?, ?, ?)',
            [
              issue['id'],
              issue['summary'],
              issue['issueType']['id'],
              issue['status']['id'],
              assignee['id'],
              issue['dueDate']
            ]

          unless assignee['id'] == nil
            if !record_exists('users', assignee['id'])
              @db.execute 'INSERT INTO users VALUES (?, ?)', [assignee['id'], assignee['name']]
            end
          end
        end
      end
    end

    def fetch_statuses
      statuses = @api.statuses(@project_id)
      statuses.each do |status|
        if !record_exists('statuses', status['id'])
          @db.execute 'INSERT INTO statuses VALUES (?, ?)', [status['id'], status['name']]
        end
      end
    end

    def fetch_issue_types
      issue_types = @api.issueTypes(@project_id)
      issue_types.each do |issue_type|
        if !record_exists('issue_types', issue_type['id'])
          @db.execute 'INSERT INTO issue_types VALUES (?, ?)', [issue_type['id'], issue_type['name']]
        end
      end
    end

    private

    def table_exists(table_name)
      rows = @db.execute("SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", table_name)
      rows[0][0] == 1
    end

    def record_exists(table_name, id)
      rows = @db.execute("SELECT count(*) FROM #{table_name} WHERE id=?", id)  # TODO:
      rows[0][0] == 1
    end

  end
end


if __FILE__ == $0
  require 'dotenv'
  Dotenv.load

  endpoint = ENV['BACKLOG_API_ENDPOINT']
  api_key = ENV['BACKLOG_API_KEY']

  api = Backlog::Client.new(endpoint, api_key)

  project_id = api.projects.filter { |project| project['name'] == 'main' }.first['id']

  Backlog::Query.endpoint = ENV['BACKLOG_API_ENDPOINT']
  Backlog::Query.api_key = ENV['BACKLOG_API_KEY']

  Backlog::Query.context do |ctx|
    ctx.project_id = project_id

    ctx.fetch_issue_types
    ctx.fetch_statuses
    ctx.fetch_issues {'count' => 100}

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
end

