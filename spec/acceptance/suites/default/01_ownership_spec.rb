require 'spec_helper_acceptance'
require 'yaml'

require_relative('../../lib/util')
include Tpm2TestUtil

RUN_IN_PARALLEL = ENV.fetch('BEAKER_RUN_IN_PARALLEL', '')
                     .split(',').include?('tests')
test_name 'tpm2::ownership class'

describe 'tpm2::ownership class' do

  let(:manifest) do
    <<-MANIFEST
      include 'tpm2'

    MANIFEST
  end

  let(:hieradata_clearall) do
    <<-HIERADATA
tpm2::take_ownership: true
tpm2::ownership::owner: clear
tpm2::ownership::lockout: clear
tpm2::ownership::endorsement: clear
tpm2::ownership::owner_auth: 'Myownerpassword'
tpm2::ownership::lockout_auth: 'Mylockpassword'
tpm2::ownership::endorsement_auth: 'Myendorsepassword'
    HIERADATA
  end

  let(:hieradata_setall) do
    <<-HIERADATA
tpm2::take_ownership: true
tpm2::ownership::owner: set
tpm2::ownership::lockout: set
tpm2::ownership::endorsement: set
tpm2::ownership::owner_auth: 'Myownerpassword'
tpm2::ownership::lockout_auth: 'Mylockpassword'
tpm2::ownership::endorsement_auth: 'Myendorsepassword'
    HIERADATA
  end
  let(:hieradata_setsome) do
    <<-HIERADATA
tpm2::take_ownership: true
tpm2::ownership::owner: set
tpm2::ownership::lockout: clear
tpm2::ownership::endorsement: set
tpm2::ownership::owner_auth: 'Myownerpassword'
tpm2::ownership::lockout_auth: 'Mylockpassword'
tpm2::ownership::endorsement_auth: 'Myendorsepassword'
    HIERADATA
  end
  let(:hieradata_flip) do
    <<-HIERADATA
tpm2::take_ownership: true
tpm2::ownership::owner: clear
tpm2::ownership::lockout: set
tpm2::ownership::endorsement: set
tpm2::ownership::owner_auth: 'Myownerpassword'
tpm2::ownership::lockout_auth: 'Mylockpassword'
tpm2::ownership::endorsement_auth: 'Myendorsepassword'
    HIERADATA
  end


  context 'applying tpm2::ownership with various settings' do
    it 'with the defaults the tpm packages should install but all settings be clear.' do
      hosts.entries.each do |host|
        apply_manifest_on( host, manifest, catch_failures: true)
        apply_manifest_on( host, manifest, catch_failures: true)
        expect(get_tpm2_status(host)).to eq(['clear','clear','clear'])
      end
    end

    it 'should set auth values for all three sections and idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        set_hieradata_on( host, hieradata_setall )
        apply_manifest_on( host, manifest, catch_failures: true)
        apply_manifest_on( host, manifest, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['set','set','set'])
      end
    end

    it 'should clear the auth on tpm and be idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        set_hieradata_on( host, hieradata_clearall )
        apply_manifest_on( host, manifest, catch_failures: true)
        apply_manifest_on( host, manifest, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['clear','clear','clear'])
      end
    end
    it 'should set owner and lockout and be idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        set_hieradata_on( host, hieradata_setsome )
        apply_manifest_on( host, manifest, catch_failures: true)
        apply_manifest_on( host, manifest, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['set','set','clear'])
      end
    end

    it 'should clear owner and leave lockout and be idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        set_hieradata_on( host, hieradata_flip )
        apply_manifest_on( host, manifest, catch_failures: true)
        apply_manifest_on( host, manifest, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['clear','set','set'])
      end
    end
  end
end
