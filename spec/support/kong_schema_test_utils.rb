require 'kong_schema'

class KongSchemaTestUtils
  attr_reader :host

  def initialize(host: ENV.fetch('KONG_URI', '127.0.0.1:9712'))
    @host = host
  end

  def generate_config(config = {})
    JSON.parse(JSON.dump({ admin_host: host }.merge(config)))
  end

  def reset_kong
    KongSchema::Client.connect(generate_config) do
      KongSchema::Resource::Upstream.all.each do |upstream|
        upstream.targets.each(&:delete)
        upstream.delete
      end

      KongSchema::Resource::Api.all.each(&:delete)
    end
  end
end
