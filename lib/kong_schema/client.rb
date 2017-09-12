# frozen_string_literal: true

require 'kong'

module KongSchema
  module Client
    # Configure Kong::Client to use the host specified in config['admin_host']
    # for the duration of a proc.
    #
    # Example:
    #
    #     KongSchema::Schema.connect({ 'admin_host' => '127.0.0.1:8001' }) do
    #       Kong::Api.all()
    #     end
    def self.connect(config, &_)
      api_url = Kong::Client.api_url

      Kong::Client.api_url = "http://#{config['admin_host']}"

      yield Kong::Client
    ensure
      Kong::Client.api_url = api_url
    end
  end
end
