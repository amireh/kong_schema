describe KongSchema::Resource::Target do
  let(:schema) { KongSchema::Schema }
  let(:test_utils) { KongSchemaTestUtils.new }

  describe 'creating targets' do
    let :config do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service'
        }],

        targets: [{
          upstream_id: 'bridge-learn.kong-service',
          target: '127.0.0.1:3000'
        }]
      })
    end

    it 'adds a target if it does not exist' do
      directives = schema.scan(config)

      expect(directives.map(&:class)).to eq([ KongSchema::Actions::Create, KongSchema::Actions::Create ])
    end

    it 'does add a target' do
      directives = schema.scan(config)

      expect {
        schema.commit(config, directives)
      }.to change {
        KongSchema::Client.connect(config) { Kong::Upstream.all.count }
      }.by(1)
    end

    it 'does not add a target if it exists' do
      directives = schema.scan(config)

      schema.commit(config, directives)

      next_directives = schema.scan(config)

      expect(next_directives.map(&:class)).not_to include(KongSchema::Actions::Create)
    end

    it 'does not allow defining a target without an upstream_id' do
      directives = schema.scan(test_utils.generate_config({
        targets: [{ target: '127.0.0.1:3000' }]
      }))

      expect {
        schema.commit(config, directives)
      }.to raise_error(/Can not add a target without an upstream!/)
    end
  end

  describe "changing a target's target" do
    let :config do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service'
        }],

        targets: [{
          upstream_id: 'bridge-learn.kong-service',
          target: '127.0.0.1:3000'
        }]
      })
    end

    let :with_updated do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service'
        }],

        targets: [{
          upstream_id: 'bridge-learn.kong-service',
          target: '127.0.0.1:9999'
        }]
      })
    end

    before(:each) do
      schema.commit(config, schema.scan(config))
    end

    it 'identifies targets to be updated' do
      directives = schema.scan(with_updated)

      expect(directives.map(&:class)).to eq([KongSchema::Actions::Create, KongSchema::Actions::Delete])
    end

    it 'updates a target' do
      expect {
        schema.commit(with_updated, schema.scan(with_updated))
      }.to change {
        KongSchema::Client.connect(config) {
          KongSchema::Resource::Target.all.map { |x| [ x.weight, x.target ] }
        }
      }.from([
        [ 100, '127.0.0.1:3000' ]
      ]).to([
        [ 100,  '127.0.0.1:9999' ]
      ])
    end
  end

  describe "changing a target's weight" do
    let :config do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service'
        }],

        targets: [{
          upstream_id: 'bridge-learn.kong-service',
          target: '127.0.0.1:3000'
        }]
      })
    end

    let :with_different_weight do
      test_utils.generate_config({
        upstreams: [{
          name: 'bridge-learn.kong-service'
        }],

        targets: [{
          upstream_id: 'bridge-learn.kong-service',
          target: '127.0.0.1:3000',
          weight: 20
        }]
      })
    end

    before(:each) do
      schema.commit(config, schema.scan(config))
    end

    it 'updates the existing target' do
      directives = schema.scan(with_different_weight)

      expect(directives.map(&:class)).to eq([ KongSchema::Actions::Update ])
    end

    it 'updates a target' do
      expect {
        schema.commit(with_different_weight, schema.scan(with_different_weight))
      }.to change {
        KongSchema::Client.connect(config) {
          KongSchema::Resource::Target.all.map { |x| [ x.weight, x.target ] }
        }
      }.from([
        [ 100, '127.0.0.1:3000' ]
      ]).to([
        [ 20,  '127.0.0.1:3000' ]
      ])
    end
  end

  describe 'deleting targets' do
    let :config do
      test_utils.generate_config(
        upstreams: [{
          name: 'bridge-learn.kong-service'
        }],

        targets: [{
          upstream_id: 'bridge-learn.kong-service',
          target: '127.0.0.1:3000'
        }]
      )
    end

    let :with_deleted do
      test_utils.generate_config(
        upstreams: [{ name: 'bridge-learn.kong-service' }],
        targets: []
      )
    end

    before(:each) do
      schema.commit(config, schema.scan(config))
    end

    it 'identifies targets to be deleted' do
      directives = schema.scan(with_deleted)

      expect(directives.map(&:class)).to include(KongSchema::Actions::Delete)
    end

    it 'deletes a target' do
      expect {
        schema.commit(with_deleted, schema.scan(with_deleted))
      }.to change {
        KongSchema::Client.connect(config) {
          KongSchema::Resource::Target.all.map { |x| [ x.target, x.weight ] }
        }
      }.from([
        [ '127.0.0.1:3000', 100 ]
      ]).to([
      ])
    end
  end
end