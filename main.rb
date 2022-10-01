#!/usr/bin/env ruby

require './blg'
require 'sqlite3'

module Blg
  class Query
    def self.context(&block)
      Blg::Context.new(&block)
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
  assignee_id   integer
);
SQL
    end

    def self.users_table
<<-SQL
CREATE TABLE users (
  id integer unique,
  name text
);
SQL
    end

    def self.statuses_table
<<-SQL
CREATE TABLE statuses (
  id integer unique,
  name text
);
SQL
    end

    def self.issue_types_table
<<-SQL
CREATE TABLE issue_types (
  id integer unique,
  name text
);
SQL
    end
  end

  class Context
    def initialize
      @db = SQLite3::Database.new ':memory:'
      Schema.create_table(@db)
 
      yield(self) if block_given?
    end

    def fetch(name, source)
      case name
      when :issue_types
        fetch_issue_types(source)
      when :statuses
        fetch_statuses(source)
      when :issues
        fetch_issues(source)
      end
    end

    def execute(*bind_vars, &block)
      @db.execute(*bind_vars, &block)
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

    def fetch_issues(issues)
      issues.each do |issue|
        if !record_exists('issues', issue['id'])
          assignee = if issue['assignee'] == nil
                       {'id' => nil}
                     else
                       issue['assignee']
                     end
          @db.execute 'INSERT INTO issues VALUES (?, ?, ?, ?, ?)',
            [
              issue['id'],
              issue['summary'],
              issue['issueType']['id'],
              issue['status']['id'],
              assignee['id']
            ]

          unless assignee['id'] == nil
            if !record_exists('users', assignee['id'])
              @db.execute 'INSERT INTO users VALUES (?, ?)', [assignee['id'], assignee['name']]
            end
          end
        end
      end
    end

    def fetch_statuses(statuses)
      statuses.each do |status|
        if !record_exists('statuses', status['id'])
          @db.execute 'INSERT INTO statuses VALUES (?, ?)', [status['id'], status['name']]
        end
      end
    end

    def fetch_issue_types(issue_types)
      issue_types.each do |issue_type|
        if !record_exists('issue_types', issue_type['id'])
          @db.execute 'INSERT INTO issue_types VALUES (?, ?)', [issue_type['id'], issue_type['name']]
        end
      end
    end
  end
end

require 'dotenv'
Dotenv.load

endpoint = ENV['BACKLOG_API_ENDPOINT']
api_key = ENV['BACKLOG_API_KEY']

api = Blg::Client.new(endpoint, api_key)

projects = api.projects

project_id = projects[0]['id']

Blg::Query.context do |ctx|
  ctx.fetch(:issue_types, api.issueTypes(project_id))
  ctx.fetch(:statuses, api.statuses(project_id))
  ctx.fetch(:issues, api.issues({'count' => 100}))

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

