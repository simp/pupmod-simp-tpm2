require 'spec_helper_acceptance'

test_name 'tpm::tpm2::install class'
install_tpm2_0_tools

describe 'tpm::tpm2::install class' do

  let(:manifest) { <<-EOS
      include 'tpm::tpm2::install'
    EOS
  }

  context 'with default settings' do
    it 'should apply with no errors' do
require 'pry'; binding.pry
      apply_manifest_on(hosts, manifest, run_in_parallel: true)
      apply_manifest_on(hosts, manifest, catch_failures: true, run_in_parallel: true)
    end

    it 'should be idempotent' do
      sleep 20
      apply_manifest_on(hosts, manifest, catch_changes: true, run_in_parallel: true)
    end
  end
end
