require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end


def install_tpm2_0_tools
  # install any rpm files in the top-level directory to tmp
  rpm_staging_dir = "/root/rpms.#{$$}"
  on hosts, "mkdir -p #{rpm_staging_dir}"

  # Download and unpack tarball of TPM2 RPMs in the rpm_staging_dir
  unless ENV.fetch('BEAKER_download_tpm2_rpms','yes') == 'no'
    tpm2_rpms_tarball_url = ENV['BEAKER_tpm2_rpms_tarball_url'] || \
      'https://github.com/op-ct/simp-tpm2-rpms/releases/download/0.1.0/simp-tpm-rpms-0.1.0.tar.gz'
    on hosts, "curl -L '#{tpm2_rpms_tarball_url}' > '#{rpm_staging_dir}/simp-tpm2-rpms.tar.gz'" + \
              " && cd '#{rpm_staging_dir}' && tar zxvf simp-tpm2-rpms.tar.gz"
  end

  # If .rpm files have been locally staged at the top level of the repository, upload them as well
  Dir['*.rpm'].each do |f|
    scp_to(hosts,f,rpm_staging_dir)
  end

  on hosts, "yum install -y #{rpm_staging_dir}/*.rpm"

  # TODO:
  # Start the TPM 2.0 simulator as a background process
  on hosts, 'runuser tpm2sim --shell /bin/sh -c "cd /tmp; nohup /usr/local/bin/tpm2-simulator &> /tmp/tpm2-simulator.log &"', pty: true, run_in_parallel: true
  on hosts, 'mkdir -p /etc/systemd/system/tpm2-abrmd.service.d'

  # Configure the TAB/RM to talk to the TPM2 simulator
  extra_file=<<-SYSTEMD.gsub(/^\s*/,'')
  [Service]
  ExecStart=
  ExecStart=/usr/local/sbin/tpm2-abrmd -t socket
  SYSTEMD
  create_remote_file hosts, '/etc/systemd/system/tpm2-abrmd.service.d/override.conf', extra_file
  on hosts, 'systemctl daemon-reload'
  on hosts, 'systemctl start tpm2-abrmd'
end

RSpec.configure do |c|
  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    begin

      # Install modules and dependencies from spec/fixtures/modules
      copy_fixture_modules_to( hosts )
      begin
        server = only_host_with_role(hosts, 'server')
      rescue ArgumentError =>e
        server = only_host_with_role(hosts, 'default')
      end

      # Generate and install PKI certificates on each SUT
      Dir.mktmpdir do |cert_dir|
        run_fake_pki_ca_on(server, hosts, cert_dir )
        hosts.each{ |sut| copy_pki_to( sut, cert_dir, '/etc/pki/simp-testing' )}
      end

      # add PKI keys
      copy_keydist_to(server)
    rescue StandardError, ScriptError => e
      if ENV['PRY']
        require 'pry'; binding.pry
      else
        raise e
      end
    end
  end
end
