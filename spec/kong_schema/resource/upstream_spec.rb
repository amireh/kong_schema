describe KongSchema::Resource::Upstream do
  let(:schema) { KongSchema::Schema }
  let(:test_utils) { KongSchemaTestUtils.new }

  describe 'creating upstreams' do
    let :config do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service'
        }]
      })
    end

    it 'adds an upstream if it does not exist' do
      changes = schema.scan(config)

      expect(changes.map(&:class)).to include(KongSchema::Actions::Create)
    end

    it 'does add an upstream' do
      changes = schema.scan(config)

      expect {
        schema.commit(config, changes)
      }.to change {
        KongSchema::Client.connect(config) { Kong::Upstream.all.count }
      }.by(1)
    end

    it 'does not add an upstream if it exists' do
      changes = schema.scan(config)

      schema.commit(config, changes)

      next_changes = schema.scan(config)

      expect(next_changes.map(&:class)).not_to include(KongSchema::Actions::Create)
    end
  end

  describe 'updating upstreams' do
    let :config do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service',
        }]
      })
    end

    let :with_updated_config do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service',
          slots: 50,
          orderlist: nil
        }]
      })
    end

    before(:each) do
      schema.commit(config, schema.scan(config))
    end

    it 'updates an upstream' do
      changes = schema.scan(with_updated_config)

      expect(changes.map(&:class)).to eq([ KongSchema::Actions::Update ])
    end

    it 'does update an upstream' do
      changes = schema.scan(with_updated_config)

      expect {
        schema.commit(with_updated_config, changes)
      }.to change {
        KongSchema::Client.connect(config) {
          Kong::Upstream.all.first.slots
        }
      }.from(100).to(50)
    end
  end

  describe 'deleting upstreams' do
    let :config do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service',
        }]
      })
    end

    let :with_deleted_config do
      test_utils.generate_config({
        upstreams: []
      })
    end

    before(:each) do
      schema.commit(config, schema.scan(config))
    end

    it 'deletes an upstream' do
      changes = schema.scan(with_deleted_config)

      expect(changes.map(&:class)).to include(KongSchema::Actions::Delete)
    end

    it 'does delete an upstream' do
      changes = schema.scan(with_deleted_config)

      expect {
        schema.commit(with_deleted_config, changes)
      }.to change {
        KongSchema::Client.connect(config) { Kong::Upstream.all.count }
      }.from(1).to(0)
    end
  end
end