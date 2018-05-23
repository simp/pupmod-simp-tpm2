require 'spec_helper_acceptance'

test_name 'tpm2 class'

describe 'tpm2 class' do
  let(:manifest) {
    <<-EOS
      class { 'tpm2': }
    EOS
  }

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      apply_manifest(manifest, :catch_failures => true)
    end

    it 'should be idempotent' do
      apply_manifest(manifest, :catch_changes => true)
    end


    describe package('tpm2') do
      it { is_expected.to be_installed }
    end

    describe service('tpm2') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
