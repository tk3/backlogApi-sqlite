module Backlog
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
  due_date      text,
  created       text,
  updated       text
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
end
