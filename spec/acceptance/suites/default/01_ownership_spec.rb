require 'spec_helper_acceptance'
require 'yaml'

RUN_IN_PARALLEL = ENV.fetch('BEAKER_RUN_IN_PARALLEL', '')
                     .split(',').include?('tests')
test_name 'tpm2::ownership class'

describe 'tpm2::ownership class' do

  let(:set_manifest) do
    <<-MANIFEST
      include 'tpm2'

      class { 'tpm2::ownership':
        owner        => 'set',
        endorsement  => 'set',
        lock         => 'set',
        owner_auth   => 'Myownerpassword',
        lock_auth    => 'Mylockpassword',
        endorse_auth => 'Myendorsepassword',
        require      => Service['tpm2-abrmd'],
      }

    MANIFEST
  end
  let(:clear_manifest) do
    <<-MANIFEST
      include 'tpm2'
      class { 'tpm2::ownership':
        owner        => 'clear',
        endorsement  => 'clear',
        lock         => 'clear',
        owner_auth   => 'Myownerpassword',
        lock_auth    => 'Mylockpassword',
        endorse_auth => 'Myendorsepassword',
        require      => Service['tpm2-abrmd'],
      }

    MANIFEST
  end
  let(:owner_only) do
    <<-MANIFEST
      include 'tpm2'
      class { 'tpm2::ownership':
        owner        => 'set',
        endorsement  => 'clear',
        lock         => 'set',
        owner_auth   => 'Myownerpassword',
        lock_auth    => 'Mylockpassword',
        require      => Service['tpm2-abrmd'],
      }

    MANIFEST
  end
  let(:clear_owner_only) do
    <<-MANIFEST
      include 'tpm2'
      class { 'tpm2::ownership':
        owner        => 'clear',
        endorsement  => 'clear',
        lock         => 'set',
        owner_auth   => 'Myownerpassword',
        lock_auth    => 'Mylockpassword',
        require      => Service['tpm2-abrmd'],
    }

    MANIFEST
  end

  context 'applying tpm2::ownership with various settings' do
    it 'the test installs tpm without errors' do
      apply_manifest_on(hosts, 'include tpm2', catch_failures: true)
      apply_manifest_on( hosts, 'include tpm2', catch_failures: true)
    end

    it 'should take ownership of all three sections and idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        sleep 20
        apply_manifest_on( host, set_manifest, catch_failures: true)
        apply_manifest_on( host, set_manifest, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['set','set','set'])
      end
    end

    it 'should clear the auth on tpm and be idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        sleep 20
        apply_manifest_on( host, clear_manifest, catch_failures: true)
        apply_manifest_on( host, clear_manifest, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['clear','clear','clear'])
      end
    end
    it 'should set owner and lock and be idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        sleep 20
        apply_manifest_on( host, owner_only, catch_failures: true)
        apply_manifest_on( host, owner_only, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['set','clear','set'])
      end
    end

    it 'should clear owner and leave lock and be idempotent' do
      #Note: applying it twice to make sure the fact is updated.
      hosts.entries.each do |host|
        sleep 20
        apply_manifest_on( host, clear_owner_only, catch_failures: true)
        get_tpm2_status(host)
        apply_manifest_on( host, clear_owner_only, catch_changes: true)
        expect(get_tpm2_status(host)).to eq(['clear','clear','set'])
      end
    end
  end
end
