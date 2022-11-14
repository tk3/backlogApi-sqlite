require_relative 'backlog'

module Backlog
  class Query
    @@api_url = nil
    @@api_key = nil
    @@output_db = ':memory:'

    def self.context(&block)
      raise 'Cannot set api_url' if @@api_url.nil?
      raise 'Cannot set api_key' if @@api_key.nil?

      api = Backlog::Client.new(@@api_url, @@api_key)
      Backlog::Context.new(api, @@output_db, &block)
    end

    def self.api_url=(value)
      @@api_url = value
    end

    def self.api_key=(value)
      @@api_key = value
    end

    def self.output_db=(value)
      @@output_db = value
    end
  end
end

