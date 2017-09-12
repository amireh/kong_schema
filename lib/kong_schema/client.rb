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
      admin_host = config['admin_host']

      if admin_host.nil?
        fail "Missing 'admin_host' property; can not connect to Kong admin!"
      end

      Kong::Client.api_url = "http://#{admin_host}"

      yield Kong::Client
    ensure
      Kong::Client.api_url = api_url
    end

    # Reset Kong's database by removing all objects through the API.
    def self.purge(config)
      connect(config) do
        KongSchema::Resource::Upstream.all.each do |upstream|
          upstream.targets.each(&:delete)
          upstream.delete
        end

        KongSchema::Resource::Api.all.each(&:delete)
      end
    end
  end
end
