require 'rspec'
require_relative '../../libraries/helpers'

describe AuditOSX do
  describe 'AuditOSX.users' do
    let(:users_dir) { ['/Users/Guest', '/Users/hansolo', '/Users/Shared'] }

    before(:each) do
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with('/Users/**').and_return(users_dir)
    end

    it 'returns array of real users' do
      expect(AuditOSX.users).to eq(['hansolo'])
    end

    it 'does not contain guest user' do
      expect(AuditOSX.users).to_not include('Guest')
    end

    it 'does not contain shared user' do
      expect(AuditOSX.users).to_not include('Shared')
    end
  end
end
