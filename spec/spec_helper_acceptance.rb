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

# Download (and unpack if tarball of) TPM2 RPMs in the rpm_staging_dir
# supports URLs ending in *.rpm, #.tar.gz, *.tar, and *.tgz
def download_rpm_tarball_on(hosts, rpm_staging_dir)
  tpm2_rpms_tarball_url_string = ENV['BEAKER_tpm2_rpms_tarball_url'] || \
    'https://github.com/op-ct/simp-tpm2-rpms/releases/download/0.1.0-rpms/simp-tpm2-simulator-1119.0.0-0.el7.centos.x86_64.rpm'
    ### 'https://github.com/op-ct/simp-tpm2-rpms/releases/download/0.1.0/simp-tpm-rpms-0.1.0.tar.gz'
  urls = tpm2_rpms_tarball_url_string.split(/,/)
  urls.each do |url|
    file = File.basename url
    cmd  = "curl -L '#{url}' > '#{rpm_staging_dir}/#{file}'"

    if file =~ /\.(tar\.gz|tgz)$/
      cmd += " && cd '#{rpm_staging_dir}' && tar zxvf '#{file}'"
    elsif file =~ /\.tar$/
      cmd += " && cd '#{rpm_staging_dir}' && tar xvf '#{file}'"
    end
    on hosts, cmd
  end
end

# Install all `*.rpm` files in `rpm_staging_dir/`
def install_rpms_staged_on(hosts,rpm_staging_dir)
  on hosts, "yum localinstall -y #{rpm_staging_dir}/*.rpm"
end

# If local .rpm files have been staged in an 'rpms/' directory at the top
# level of the repository, upload them to the SUTs' RPM staging directories
def upload_locally_staged_rpms_to(hosts, rpm_staging_dir)
  rpms = Dir['*.rpm'] + Dir[File.join('rpms','*.rpm')]
  rpms.each do |f|
    scp_to(hosts,f,rpm_staging_dir)
  end
end

# Implement any workarounds that are needed to get
def implement_workarounds(hosts)
  # workaround for dbus config file mismatch error:
  #
  # "dbus[562]: [system] Unable to reload configuration: Configuration file
  #  needs one or more <listen> elements giving addresses"
  on hosts, 'systemctl restart dbus'
end

def install_pre_suite_rpms(hosts)
  download_rpms   = !ENV.fetch('BEAKER_download_pre_suite_rpms','yes') == 'no'
  rpm_staging_dir = "/root/rpms.#{$$}"

  on hosts, "mkdir -p #{rpm_staging_dir}"
  download_rpm_tarball_on(hosts, rpm_staging_dir) unless download_rpms
  upload_locally_staged_rpms_to(hosts, rpm_staging_dir)
  install_rpms_staged_on(hosts, rpm_staging_dir)
end

# starts tpm2sim service on (hosts)
def start_tpm2sim_on(hosts)
  on hosts, 'runuser tpm2sim --shell /bin/sh -c ' \
    '"cd /tmp; nohup /usr/local/bin/tpm2-simulator &> /tmp/tpm2-simulator.log &"', \
    pty: true, run_in_parallel: true
end

def config_abrmd_for_tpm2sim_on(hosts)
  on hosts, 'mkdir -p /etc/systemd/system/tpm2-abrmd.service.d'

  # Configure the TAB/RM to talk to the TPM2 simulator
  extra_file=<<-SYSTEMD.gsub(/^\s*/,'')
  [Service]
  ExecStart=
  ExecStart=/sbin/tpm2-abrmd -t socket
  SYSTEMD

  create_remote_file hosts, '/etc/systemd/system/tpm2-abrmd.service.d/override.conf', extra_file
  on hosts, 'systemctl daemon-reload'

  on hosts, 'systemctl list-unit-files | grep tpm2-abrmd ' \
    + '&& systemctl restart tpm2-abrmd ' \
    + %q[|| echo "tpm2-abrmd.service not restarted because it doesn't exist"]
end

# start the tpm2sim and override tpm2-abrmd's systemd config use it
# assumes the tpm2sim has been installed on the hosts
def configure_tpm2_0_tools(hosts)
  start_tpm2sim_on(hosts)
  config_abrmd_for_tpm2sim_on(hosts)
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

      implement_workarounds(hosts)
      install_pre_suite_rpms(hosts)
      configure_tpm2_0_tools(hosts)
    rescue StandardError, ScriptError => e
      if ENV['PRY']
        require 'pry'; binding.pry
      else
        raise e
      end
    end
  end
end
