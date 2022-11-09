require 'net/http'
require 'json'

module Backlog
  module Request
    def get(api_path, params = {})
      url = URI.parse(@endpoint)

      query_string = {'apiKey' => @api_key}
      url.path = url.path + api_path
      url.query = URI.encode_www_form(query_string.merge(params))

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req = Net::HTTP::Get.new(url.request_uri)
      req['User-Agent'] = 'blg ' + Backlog::VERSION
      req['Accept'] = 'application/json'
      res = http.request(req)

      JSON.parse(res.body)
    end
  end
end

