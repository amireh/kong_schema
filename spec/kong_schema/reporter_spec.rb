describe KongSchema::Reporter do
  subject { described_class }

  let(:test_utils) { KongSchemaTestUtils.new }
  let(:schema) { KongSchema::Schema }

  let :config do
    test_utils.generate_config({
      upstreams: [{ name: 'bridge-learn.kong-service' }]
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

  let :with_deleted_config do
    test_utils.generate_config({
      upstreams: []
    })
  end

  it 'reports a resource to be created' do
    report = subject.report(schema.scan(config))

    expect(report).to include('Create Upstream')
  end

  it 'reports a resource to be updated [JSON]' do
    schema.commit(config, schema.scan(config))

    report = subject.report(schema.scan(with_updated_config))

    expect(report).to include('Update Upstream')
    expect(report).to match(/\-[ ]*"slots": 100/)
    expect(report).to match(/\+[ ]*"slots": 50/)
  end

  it 'reports a resource to be updated [YAML]' do
    schema.commit(config, schema.scan(config))

    report = subject.report(schema.scan(with_updated_config), object_format: :yaml)

    expect(report).to include('Update Upstream')
    expect(report).to include('-slots: 100')
    expect(report).to include('+slots: 50')
  end

  it 'reports a resource to be deleted' do
    schema.commit(config, schema.scan(config))

    report = subject.report(schema.scan(with_deleted_config))

    expect(report).to include('Delete Upstream')
  end

  describe '.extract_record_attributes' do
    context 'Kong::Target' do
      it 'it rewrites "upstream_id" into the upstream name' do
        with_target = test_utils.generate_config({
          upstreams: [{ name: 'foo' }],
          targets:   [{ upstream_id: 'foo', target: '127.0.0.1' }]
        })

        with_updated_target = test_utils.generate_config({
          upstreams: [{ name: 'foo' }],
          targets:   []
        })

        schema.commit(with_target, schema.scan(with_target))

        next_changes = schema.scan(with_updated_target)
        report = subject.report(next_changes, object_format: :yml)

        expect(report).to include('upstream_id: foo')
      end
    end
  end
end