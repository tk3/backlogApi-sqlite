#!/usr/bin/env ruby

require_relative 'lib/backlog'

require 'dotenv'
Dotenv.load

endpoint = ENV['BACKLOG_API_ENDPOINT']
api_key = ENV['BACKLOG_API_KEY']

api = Backlog::Client.new(endpoint, api_key)

puts "projects --------"
projects = api.projects

pp projects
puts "issues --------"
pp api.issues({'projectId[]' => projects[0]['id']})
puts "--------"
pp api.issues({'issueTypeId[]' => 656377})

exit 0

require 'pp'

puts "space --------"
pp api.space

puts "projects --------"
projects = api.projects
pp projects
pp api.projects({:archived => true})

puts "issues --------"
pp api.issues

puts "versions --------"
pp api.versions(projects[0]['id'])

puts "categories --------"
pp api.categories(projects[0]['id'])

puts "users --------"
pp api.users

puts "priorities --------"
pp api.priorities

puts "statuses--------"
pp api.statuses(projects[0]['id'])

puts "issueTypes --------"
pp api.issueTypes(projects[0]['id'])

