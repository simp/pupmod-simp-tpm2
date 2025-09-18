require 'spec_helper_acceptance'
require 'yaml'

RUN_IN_PARALLEL = ENV.fetch('BEAKER_RUN_IN_PARALLEL', '')
                     .split(',').include?('tests')

test_name 'tpm2 class'

describe 'tpm2 class' do
  let(:tpm2_abrmd2_hieradata) do
    {
      # Required to use the IBM simulator
      'tpm2::tabrm_options' => ['--tcti=/usr/lib64/libtss2-tcti-mssim.so.0']
    }
  end

  let(:tpm2_abrmd1_hieradata) do
    {
      # Required to use the IBM simulator
      'tpm2::tabrm_options' => ['-t socket']
    }
  end

  let(:manifest) do
    <<-MANIFEST
      include 'tpm2'
    MANIFEST
  end

  hosts.each do |host|
    context "on #{host} with tpm" do
      it 'installs tpm2-abrmd' do
        install_package(host, 'tpm2-abrmd')
      end

      it 'installs and start the TPM2 simulator' do
        install_package(host, 'simp-tpm2-simulator')

        on(host, 'puppet resource service simp-tpm2-simulator ensure=running enable=true')
      end

      # TODO: Undo this when
      # https://github.com/tpm2-software/tpm2-abrmd/pull/680/files makes it into
      # mainline
      it 'disables selinux for testing' do
        on(host, 'setenforce 0')
      end

      it 'sets the hieradata appropriately' do
        tpm2_abrmd_version = on(host, 'tpm2-abrmd --version').stdout.split(%r{\s+}).last

        if tpm2_abrmd_version
          if tpm2_abrmd_version.split('.').first.to_i > 1
            set_hieradata_on(host, tpm2_abrmd2_hieradata)
          else
            set_hieradata_on(host, tpm2_abrmd1_hieradata)
          end
        end
      end
    end
  end

  context 'with default settings' do
    it 'applies with no errors' do
      apply_manifest_on(hosts, manifest, run_in_parallel: RUN_IN_PARALLEL)
      apply_manifest_on(
        hosts, manifest,
        catch_failures: true,
        run_in_parallel: RUN_IN_PARALLEL
      )
    end

    it 'is idempotent' do
      sleep 20
      apply_manifest_on(
        hosts, manifest,
        catch_changes: true,
        run_in_parallel: RUN_IN_PARALLEL
      )
    end

    # If you're troubleshooting this, there are a few things that have stopped
    # the tpm2-adbrmd service from starting:
    #   - selinux denies with AVC/USER_AVC:
    #     (check with `ausearch -i -m avc,user_avc -ts recent`):
    #     - tpm2-tabrmd from opening a socket
    #     - tpm2-tabrmd from connecting to the (unconfined) tpm2-simulator
    #  - dbus is confused
    #    (check with `journalctl -xe | grep -i dbus)`:
    #     - tpm2-tabrmd service dies immediately after systemctl reports it
    #       started successfully; no AVC problems reported
    it 'is running the tpm2-abrmd service' do
      hosts.entries.each do |host|
        stdout = on(host, 'puppet resource service tpm2-abrmd --to_yaml').stdout
        service = YAML.safe_load(stdout)['service']['tpm2-abrmd']
        expect { service['ensure'].to eq 'running' }
      end
    end

    it 'queries tpm2 information with facter' do
      hosts.entries.each do |host|
        stdout = on(host, 'facter -p -y tpm2 --strict').stdout
        fact = YAML.safe_load(stdout)['tpm2']
        expect { fact['tpm2_getcap'].to be_a Hash }
        expect { fact['tpm2_getcap']['properties-fixed'].to be_a Hash }
        expect { fact['tpm2_getcap']['properties-fixed']['TPM_PT_FAMILY_INDICATOR']['as string'].to eq '2.0' }
        expect { fact['manufacturer'].to eq 'IBM ' }
      end
    end
  end
end
