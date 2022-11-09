require_relative 'backlog'
require 'sqlite3'

module Backlog
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
