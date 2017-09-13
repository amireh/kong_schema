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

  it 'adds a plugin if it does not exist' do
    directives = schema.scan(config)

    expect(directives.map(&:class)).to eq([
      KongSchema::Actions::Create,
      KongSchema::Actions::Create
    ])
  end

  it 'does add a plugin' do
    directives = schema.scan(config)

    expect {
      schema.commit(config, directives)
    }.to change {
      KongSchema::Client.connect(config) {
        Kong::Plugin.all.count
      }
    }.by(1)
  end

  it 'updates a plugin' do
    schema.commit(config, schema.scan(config))

    with_update = test_utils.generate_config({
      apis: [{
        name: 'my-api',
        upstream_url: 'http://example.com',
        hosts: [ 'example.com' ]
      }],

      plugins: [{
        config: plugin_config.merge({ second: 60 }),
        name: 'rate-limiting',
        api_id: 'my-api',
      }]
    })

    expect { schema.commit(config, schema.scan(with_update)) }.to change {
      KongSchema::Client.connect(config) {
        Kong::Plugin.find_by_name('rate-limiting').config['second']
      }
    }.from(120).to(60)
  end

  it 'removes the plugin if enabled is set to false' do
    schema.commit(config, schema.scan(config))

    with_update = test_utils.generate_config({
      apis: [{
        name: 'my-api',
        upstream_url: 'http://example.com',
        hosts: [ 'example.com' ]
      }],

      plugins: [{
        name: 'rate-limiting',
        api_id: 'my-api',
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
      apis: [{
        name: 'my-api',
        upstream_url: 'http://example.com',
        hosts: [ 'example.com' ]
      }],

      plugins: []
    })

    expect { schema.commit(config, schema.scan(with_removal)) }.to change {
      KongSchema::Client.connect(config) {
        Kong::Plugin.all.count
      }
    }.by(-1)
  end
end