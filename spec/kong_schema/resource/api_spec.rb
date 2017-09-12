describe KongSchema::Resource::Api do
  let(:schema) { KongSchema::Schema }
  let(:test_utils) { KongSchemaTestUtils.new }

  after(:each) do
    test_utils.reset_kong
  end

  describe 'creating APIs' do
    let :config do
      test_utils.generate_config({
        apis: [{
          name: 'bridge-learn',
          hosts: ['bridgeapp.com'],
          upstream_url: 'http://bridge-learn.kong-service'
        }]
      })
    end

    it 'adds an API if it does not exist' do
      directives = schema.scan(config)

      expect(directives.map(&:class)).to include(KongSchema::Actions::Create)
    end

    it 'does add an API' do
      directives = schema.scan(config)

      expect {
        schema.commit(config, directives)
      }.to change {
        KongSchema::Client.connect(config) { Kong::Api.all.count }
      }.by(1)
    end

    it 'does not add an API if it exists' do
      directives = schema.scan(config)

      schema.commit(config, directives)

      next_directives = schema.scan(config)

      expect(next_directives.map(&:class)).not_to include(KongSchema::Actions::Create)
    end
  end

  describe 'updating APIs' do
    let :config do
      test_utils.generate_config({
        apis: [{
          name: 'bridge-learn',
          hosts: ['bridgeapp.com'],
          upstream_url: 'http://bridge-learn.kong-service'
        }]
      })
    end

    let :with_updated_config do
      test_utils.generate_config({
        apis: [{
          name: 'bridge-learn',
          hosts: ['bar.com'],
          upstream_url: 'http://bridge-learn.kong-service'
        }]
      })
    end

    before(:each) do
      schema.commit(config, schema.scan(config))
    end

    it 'updates an API' do
      directives = schema.scan(with_updated_config)
      expect(directives.map(&:class)).to include(KongSchema::Actions::Update)
    end

    it 'does update an API' do
      directives = schema.scan(with_updated_config)

      expect {
        schema.commit(with_updated_config, directives)
      }.to change {
        KongSchema::Client.connect(config) { Kong::Api.all[0].hosts[0] }
      }.from('bridgeapp.com').to('bar.com')
    end
  end

  describe 'deleting APIs' do
    let :config do
      test_utils.generate_config({
        apis: [{
          name: 'bridge-learn',
          hosts: ['bar.com'],
          upstream_url: 'http://bridge-learn.kong-service'
        }]
      })
    end

    let :with_deleted_config do
      test_utils.generate_config({
        apis: []
      })
    end

    before(:each) do
      schema.commit(config, schema.scan(config))
    end

    it 'deletes an API' do
      directives = schema.scan(with_deleted_config)

      expect(directives.map(&:class)).to include(KongSchema::Actions::Delete)
    end

    it 'does delete an API' do
      directives = schema.scan(with_deleted_config)

      expect {
        schema.commit(with_deleted_config, directives)
      }.to change {
        KongSchema::Client.connect(config) { Kong::Api.all.count }
      }.from(1).to(0)
    end
  end
end