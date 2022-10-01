# backlogApi-sqlite


## sample code

```
require 'dotenv'
Dotenv.load

endpoint = ENV['BACKLOG_API_ENDPOINT']
api_key = ENV['BACKLOG_API_KEY']

api = Blg::Client.new(endpoint, api_key)

projects = api.projects
project_id = projects[0]['id']

Blg::Query.context do |ctx|
  ctx.fetch(:issues, api.issues({'count' => 100}))

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
```

