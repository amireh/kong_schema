describe KongSchema::Client do
  describe 'connect' do
    it 'whines if "admin_host" is undefined' do
      expect {
        described_class.connect({})
      }.to raise_error("Missing 'admin_host' property; can not connect to Kong admin!")
    end
  end
end