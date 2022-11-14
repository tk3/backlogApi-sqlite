

```ruby
  1 #!/usr/bin/env ruby
  2
  3 require_relative 'lib/backlog'
  4
  5 require 'dotenv'
  6 Dotenv.load
  7
  8 api_url = ENV['BACKLOG_API_URL']
  9 api_key = ENV['BACKLOG_API_KEY']
 10
 11 api = Backlog::Client.new(api_url, api_key)
 12 project_id = api.projects.filter { |project| project['name'] == 'main' }.first['id']
 13
 14 Backlog::Query.api_url = api_url
 15 Backlog::Query.api_key = api_key
 16 Backlog::Query.output_db = 'sample.db'
 17
 18 Backlog::Query.context do |ctx|
 19   ctx.project_id = project_id
 20
 21   ctx.fetch_issue_types
 22   ctx.fetch_statuses
 23   ctx.fetch_issues({'count' => 100})
 24 end
 25
```

## データベースにアクセスする

```
$ sqlite3 sample.db
```

## テーブルの定義を確認する

```sql
sqlite> .schema
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
CREATE TABLE users (
  id   integer unique,
  name text
);
CREATE TABLE statuses (
  id   integer unique,
  name text
);
CREATE TABLE issue_types (
  id   integer unique,
  name text
);
```

## 課題を検索してみる

```sql
sqlite> SELECT * FROM issues LIMIT 5;
```

```
id|summary|issue_type_id|status_id|assignee_id|due_date|created|updated
19051942|課題 その25|107916|3|393296||2022-10-01T11:31:03Z|2022-10-02T10:42:00Z
19051941|課題 その24|656378|4|393295||2022-10-01T11:30:59Z|2022-10-01T12:42:58Z
19051940|課題 その23|656378|3|393297||2022-10-01T11:30:54Z|2022-10-01T12:45:16Z
19051938|課題 その22|656378|2|393296||2022-10-01T11:30:51Z|2022-10-01T12:46:44Z
19051937|課題 その21|656378|1|||2022-10-01T11:30:48Z|2022-10-01T11:34:40Z
```

## 作成日付で課題をソートしてみる

```
sqlite> SELECT summary,updated FROM issues ORDER BY datetime(updated) DESC limit 5;
```

```
summary|updated
課題 その1|2022-11-08T13:56:32Z
課題 その25|2022-10-02T10:42:00Z
課題 その2|2022-10-02T10:33:16Z
課題 その16|2022-10-01T12:46:54Z
課題 その22|2022-10-01T12:46:44Z
```

## 課題と担当者、ステータスを表示する

```sql
SELECT i.summary, u.name, s.name FROM issues i
INNER JOIN users u
ON u.id = i.assignee_id
INNER JOIN statuses s
ON s.id = i.status_id;
```

```
sqlite> SELECT i.summary, u.name, s.name FROM issues i
   ...> INNER JOIN users u
   ...> ON u.id = i.assignee_id
   ...> INNER JOIN statuses s
   ...> ON s.id = i.status_id;
summary|name|name
課題 その25|山田 太郎|処理済み
課題 その24|絵文字 三郎|完了
課題 その23|課題 次郎|処理済み
課題 その22|山田 太郎|処理中
課題 その20|絵文字 三郎|処理中
...(省略)...
```

## ステータス別の課題の数をカウントする

```
SELECT s.name, count(*)FROM issues i
INNER JOIN users u
ON u.id = i.assignee_id
INNER JOIN statuses s
ON s.id = i.status_id
GROUP BY s.id;
```

```
sqlite> SELECT s.name, count(*)FROM issues i
   ...> INNER JOIN users u
   ...> ON u.id = i.assignee_id
   ...> INNER JOIN statuses s
   ...> ON s.id = i.status_id
   ...> GROUP BY s.id;
name|count(*)
処理中|10
処理済み|6
完了|5
```

## 担当している課題の数をカウントする

```sql
SELECT coalesce(u.name, '担当者なし') as '担当者', count(*) FROM issues i
LEFT OUTER JOIN users u
ON i.assignee_id  = u.id
GROUP BY u.id;
```

```
sqlite> SELECT coalesce(u.name, '担当者なし') as '担当者', count(*) FROM issues i
   ...> LEFT OUTER JOIN users u
   ...> ON i.assignee_id  = u.id
   ...> GROUP BY u.id;
担当者|count(*)
担当者なし|4
絵文字 三郎|5
山田 太郎|11
課題 次郎|5
```

## 

```
  1 #!/usr/bin/env ruby
  2
  3 require_relative 'lib/backlog'
  4
  5 require 'dotenv'
  6 Dotenv.load
  7
  8 api_url = ENV['BACKLOG_API_URL']
  9 api_key = ENV['BACKLOG_API_KEY']
 10
 11 api = Backlog::Client.new(api_url, api_key)
 12 project_id = api.projects.filter { |project| project['name'] == 'main' }.first['id']
 13
 14 Backlog::Query.api_url = api_url
 15 Backlog::Query.api_key = api_key
 16
 17 Backlog::Query.context do |ctx|
 18   ctx.project_id = project_id
 19
 20   ctx.fetch_issue_types
 21   ctx.fetch_statuses
 22   ctx.fetch_issues({'count' => 100})
 23
 24   sql =<<-SQL
 25 SELECT coalesce(u.name, '担当者なし') as '担当者', count(*) FROM issues i
 26 LEFT OUTER JOIN users u
 27 ON i.assignee_id  = u.id
 28 GROUP BY u.id;
 29 SQL
 30   ctx.execute(sql) do |row|
 31     p row
 32   end
 33 end
 34
```

```
$ ./sample2.rb
["担当者なし", 4]
["絵文字 三郎", 5]
["山田 太郎", 11]
["課題 次郎", 5]
```

