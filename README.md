# backlogApi-sqlite


## sample code

```
require 'dotenv'
Dotenv.load

endpoint = ENV['BACKLOG_API_ENDPOINT']
api_key = ENV['BACKLOG_API_KEY']

api = Blg::Client.new(endpoint, api_key)

projects = api.projects

Blg::Query::project(projects[0]['id'], {:endpoint => endpoint, :api_key => api_key}) do |project|
  puts project.id_or_key
  project.fetch(:issue_types, api.issueTypes(project.id_or_key))
  project.fetch(:statuses, api.statuses(project.id_or_key))
  project.fetch(:issues, api.issues({'count' => 100}))

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
```

