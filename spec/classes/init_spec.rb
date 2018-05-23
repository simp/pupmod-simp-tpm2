require 'spec_helper'

describe 'tpm2' do
  shared_examples_for "a structured module" do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('tpm2') }
    it { is_expected.to contain_class('tpm2') }
    it { is_expected.to contain_class('tpm2::install').that_comes_before('Class[tpm2::config]') }
    it { is_expected.to contain_class('tpm2::config') }
    it { is_expected.to contain_class('tpm2::service').that_subscribes_to('Class[tpm2::config]') }

    it { is_expected.to contain_service('tpm2') }
    it { is_expected.to contain_package('tpm2').with_ensure('present') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "tpm2 class without any parameters" do
          let(:params) {{ }}
          it_behaves_like "a structured module"
          it { is_expected.to contain_class('tpm2').with_trusted_nets(['127.0.0.1/32']) }
        end

        context "tpm2 class with firewall enabled" do
          let(:params) {{
            :enable_firewall => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('tpm2::config::firewall') }

          it { is_expected.to contain_class('tpm2::config::firewall').that_comes_before('Class[tpm2::service]') }
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_tpm2_tcp_connections').with_dports(9999)
          }
        end

        context "tpm2 class with selinux enabled" do
          let(:params) {{
            :enable_selinux => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('tpm2::config::selinux') }
          it { is_expected.to contain_class('tpm2::config::selinux').that_comes_before('Class[tpm2::service]') }
          it { is_expected.to create_notify('FIXME: selinux') }
        end

        context "tpm2 class with auditing enabled" do
          let(:params) {{
            :enable_auditing => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('tpm2::config::auditing') }
          it { is_expected.to contain_class('tpm2::config::auditing').that_comes_before('Class[tpm2::service]') }
          it { is_expected.to create_notify('FIXME: auditing') }
        end

        context "tpm2 class with logging enabled" do
          let(:params) {{
            :enable_logging => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('tpm2::config::logging') }
          it { is_expected.to contain_class('tpm2::config::logging').that_comes_before('Class[tpm2::service]') }
          it { is_expected.to create_notify('FIXME: logging') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'tpm2 class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta'
      }}

      it { expect { is_expected.to contain_package('tpm2') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
