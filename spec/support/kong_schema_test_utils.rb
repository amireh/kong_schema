require 'kong_schema'
require 'fileutils'

class KongSchemaTestUtils
  attr_reader :host

  def initialize(host: ENV.fetch('KONG_URI', '127.0.0.1:9712'))
    @host = host
  end

  def generate_config(config = {})
    JSON.parse(JSON.dump({ admin_host: host }.merge(config)))
  end

  def generate_config_file(config = {}, format: :yaml)
    buffer = case format
    when :json
      JSON.dump(config)
    else
      YAML.dump(config)
    end

    filename = case format
    when :json
      'config.json'
    else
      'config.yaml'
    end

    filepath = File.join(Dir.pwd, 'spec', 'fixtures', filename)

    File.write(filepath, buffer)
    yield filepath
  ensure
    FileUtils.rm(filepath)
  end

  def fake_stdin(*args)
    $stdin = StringIO.new
    $stdin.puts(args.shift) until args.empty?
    $stdin.rewind
    yield
  ensure
    $stdin = STDIN
  end

  def reset_kong
    KongSchema::Client.purge(generate_config)
  end
end
