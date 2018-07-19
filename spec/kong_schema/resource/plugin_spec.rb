describe KongSchema::Resource::Plugin do
  let(:schema) { KongSchema::Schema }
  let(:test_utils) { KongSchemaTestUtils.new }

  let :plugin_config do
    {
      second: 120
    }
  end

  let :config do
    test_utils.generate_config({
      plugins: [{
        name: 'rate-limiting',
        enabled: true,
        config: plugin_config
      }]
    })
  end

  let :config_with_custom_options do
    test_utils.generate_config({
      plugins: [{
        name: 'rate-limiting',
        enabled: true,
        config: plugin_config.merge({ second: 60 }),
      }]
    })
  end

  let :config_with_api do
    test_utils.generate_config({
      apis: [{
        name: 'my-api',
        upstream_url: 'http://example.com',
        hosts: [ 'example.com' ]
      }],

      plugins: [{
        name: 'rate-limiting',
        api_id: 'my-api',
        enabled: true,
        config: plugin_config
      }]
    })
  end

  it 'identifies plugins to be added' do
    directives = schema.scan(config)

    expect(directives.map(&:class)).to eq([ KongSchema::Actions::Create ])
  end

  it 'adds a plugin' do
    directives = schema.scan(config)

    expect {
      schema.commit(config, directives)
    }.to change {
      KongSchema::Client.connect(config) {
        Kong::Plugin.all.count
      }
    }.by(1)
  end

  it 'adds a plugin with an api' do
    directives = schema.scan(config_with_api)

    expect {
      schema.commit(config_with_api, directives)
    }.to change {
      KongSchema::Client.connect(config_with_api) {
        Kong::Plugin.all.count
      }
    }.by(1)
  end

  it 'identifies plugins to be updated' do
    schema.commit(config, schema.scan(config))
    changes = schema.scan(config_with_custom_options)

    expect(changes.map(&:class)).to eq([ KongSchema::Actions::Update ])
  end

  it 'updates a plugin' do
    schema.commit(config, schema.scan(config))

    expect { schema.commit(config, schema.scan(config_with_custom_options)) }.to change {
      KongSchema::Client.connect(config) {
        Kong::Plugin.find_by_name('rate-limiting').config['second']
      }
    }.from(120).to(60)
  end

  it 'removes the plugin if enabled is set to false' do
    schema.commit(config, schema.scan(config))

    with_update = test_utils.generate_config({
      plugins: [{
        name: 'rate-limiting',
        config: plugin_config,
        enabled: false
      }]
    })

    expect { schema.commit(config, schema.scan(with_update)) }.to change {
      KongSchema::Client.connect(config) {
        Kong::Plugin.all.count
      }
    }.by(-1)
  end

  it 'removes the plugin if it is no longer specified' do
    schema.commit(config, schema.scan(config))

    with_removal = test_utils.generate_config({
      plugins: []
    })

    expect { schema.commit(config, schema.scan(with_removal)) }.to change {
      KongSchema::Client.connect(config) {
        Kong::Plugin.all.count
      }
    }.by(-1)
  end

  it 'removes the plugin even if the target is no longer defined' do
    schema.commit(config, schema.scan(config_with_api))

    with_api_removal = test_utils.generate_config(config_with_api.merge({
      apis: [],
    }))

    expect { schema.commit(config, schema.scan(with_api_removal)) }.to change {
      KongSchema::Client.connect(config) {
        Kong::Api.all.count
      }
    }.by(-1)
  end
end