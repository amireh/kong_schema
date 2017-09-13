describe KongSchema::CLI do
  let(:test_utils) { KongSchemaTestUtils.new }
  let(:schema) { KongSchema::Schema }
  let(:client) { KongSchema::Client }

  let(:config) do
    test_utils.generate_config({
      apis: [{
        name: 'my-api',
        hosts: [ 'example.com' ],
        upstream_url: 'http://example'
      }]
    })
  end

  let(:keyed_config) do
    {
      "kong" => config
    }
  end

  describe 'up' do
    it 'complains if no file was passed' do
      expect(subject).to receive(:bail!)
        .with('Missing path to .yml or .json config file')
        .and_call_original

      expect {
        subject.run(["up"])
      }.to  output(/Missing path to/).to_stderr_from_any_process
       .and output(/SYNOPSIS/).to_stdout_from_any_process # help listing
    end

    it 'works' do
      test_utils.generate_config_file(config) do |filepath|
        expect {
          subject.run(["up", filepath, "--no-confirm", "--key", ""])
        }.to  change { client.connect(config) { Kong::Api.all.count } }.by(1)
         .and output(/Kong has been reconfigured!/).to_stdout
      end
    end

    it 'works (with a JSON file)' do
      test_utils.generate_config_file(config, format: :json) do |filepath|
        expect {
          subject.run(["up", filepath, "--no-confirm", "--key", ""])
        }.to  change { client.connect(config) { Kong::Api.all.count } }.by(1)
         .and output(/Kong has been reconfigured!/).to_stdout
      end
    end

    it 'accepts config file using -c for consistency with Kong' do
      test_utils.generate_config_file(keyed_config) do |filepath|
        expect {
          subject.run(["up", "-c", filepath, "--no-confirm"])
        }.to  change { client.connect(config) { Kong::Api.all.count } }.by(1)
         .and output(/Kong has been reconfigured!/).to_stdout
      end
    end

    it 'accepts config file using -c (globally) for convenience' do
      test_utils.generate_config_file(keyed_config) do |filepath|
        expect {
          subject.run(["-c", filepath, "up", "--no-confirm"])
        }.to  change { client.connect(config) { Kong::Api.all.count } }.by(1)
         .and output(/Kong has been reconfigured!/).to_stdout
      end
    end

    it 'reads config from a custom key' do
      test_utils.generate_config_file(keyed_config) do |filepath|
        expect {
          subject.run(["up", filepath, "--no-confirm", "--key", "kong"])
        }.to  change { client.connect(config) { Kong::Api.all.count } }.by(1)
         .and output(/Kong has been reconfigured!/).to_stdout
      end
    end

    it 'prompts for confirmation' do
      test_utils.fake_stdin(["y"]) do
        test_utils.generate_config_file(keyed_config) do |filepath|
          expect {
            subject.run(["up", filepath])
          }.to  change { client.connect(config) { Kong::Api.all.count } }.by(1)
           .and output(/Kong has been reconfigured!/).to_stdout
        end
      end
    end

    it 'aborts if not confirmed' do
      test_utils.fake_stdin(["n"]) do
        test_utils.generate_config_file(keyed_config) do |filepath|
          expect {
            subject.run(["up", filepath])
          }.to  change { client.connect(config) { Kong::Api.all.count } }.by(0)
           .and output.to_stdout
        end
      end
    end

    it 'does nothing if there are no changes to commit' do
      config = test_utils.generate_config({})

      test_utils.generate_config_file(config) do |filepath|
        expect {
          subject.run(["up", filepath, "--no-confirm", "--key", ""])
        }.to output(/Nothing to update./).to_stdout
      end
    end
  end

  describe 'down' do
    it 'complains if no file was passed' do
      expect(subject).to receive(:bail!)
        .with('Missing path to .yml or .json config file')
        .and_call_original

      expect {
        subject.run(["down"])
      }.to  output(/Missing path to/).to_stderr_from_any_process
       .and output(/SYNOPSIS/).to_stdout_from_any_process # help listing
    end

    it 'works' do
      KongSchema::Schema.commit(config, KongSchema::Schema.scan(config))

      test_utils.generate_config_file(config) do |filepath|
        expect {
          subject.run(["down", filepath, "--no-confirm", "--key", ""])
        }.to  change { client.connect(config) { Kong::Api.all.count } }.by(-1)
         .and output(/Kong reset\./).to_stdout
      end
    end
  end
end