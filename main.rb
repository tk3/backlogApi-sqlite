#!/usr/bin/env ruby

require './blg'
require 'sqlite3'

module Blg
  class Query
    class Context
      class Project
        attr_reader :id_or_key

        def initialize(id_or_key, options = {})
          @id_or_key = id_or_key
          @api = Blg::Client.new(
            options[:endpoint],
            options[:api_key]
          )
          @db = SQLite3::Database.new ':memory:'

          yield(self) if block_given?
        end

        def fetch(resource, options = {})
          case resource
          when :issue_types
            fetch_issue_types
          when :statuses
            fetch_statuses
          when :issues
            fetch_issues options
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

        def fetch_issues(options = {})
          issues = @api.issues options

          unless table_exists('issue')
            rows = @db.execute <<-SQL
CREATE TABLE issues (
  id            integer unique,
  summary       text,
  issue_type_id integer,
  status_id     integer,
  assignee_id   integer
);
SQL
          end

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
                unless table_exists('users')
            rows = @db.execute <<-SQL
CREATE TABLE users (
  id integer unique,
  name text
);
SQL
                end
                if !record_exists('users', assignee['id'])
                  @db.execute 'INSERT INTO users VALUES (?, ?)', [assignee['id'], assignee['name']]
                end
              end
            end
          end
        end

        def fetch_statuses
          statuses = @api.statuses(@id_or_key)

          unless table_exists('statuses')
            rows = @db.execute <<-SQL
CREATE TABLE statuses (
  id integer unique,
  name text
);
SQL
          end

          statuses.each do |status|
            if !record_exists('statuses', status['id'])
              @db.execute 'INSERT INTO statuses VALUES (?, ?)', [status['id'], status['name']]
            end
          end
        end

        def fetch_issue_types
          issue_types = @api.issueTypes(@id_or_key)

          unless table_exists('issue_types')
            rows = @db.execute <<-SQL
CREATE TABLE issue_types (
  id integer unique,
  name text
);
SQL
          end

          issue_types.each do |issue_type|
            if !record_exists('issue_types', issue_type['id'])
              @db.execute 'INSERT INTO issue_types VALUES (?, ?)', [issue_type['id'], issue_type['name']]
            end
          end
        end
      end
    end

    def self.project(id_or_key, api, &block)
      Blg::Query::Context::Project.new(id_or_key, api, &block)
    end

  end
end

require 'dotenv'
Dotenv.load

endpoint = ENV['BACKLOG_API_ENDPOINT']
api_key = ENV['BACKLOG_API_KEY']

api = Blg::Client.new(endpoint, api_key)

projects = api.projects

Blg::Query::project(projects[0]['id'], {:endpoint => endpoint, :api_key => api_key}) do |project|
  puts project.id_or_key
  project.fetch(:issue_types)
  project.fetch(:statuses)
  project.fetch(:issues, {'count' => 100})

  project.execute('SELECT * FROM issue_types') do |row|
    p row
  end

  project.execute('SELECT * FROM statuses') do |row|
    p row
  end

  project.execute('SELECT * FROM issues') do |row|
    p row
  end

  project.execute('SELECT * FROM users') do |row|
    p row
  end

  sql =<<-SQL
SELECT u.name, count(*) FROM issues i
INNER JOIN users u
ON i.assignee_id  = u.id
GROUP BY u.id
SQL
  project.execute(sql) do |row|
    p row
  end


end

