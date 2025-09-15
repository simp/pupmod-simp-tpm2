require 'spec_helper'

# Some contexts are holdovers from the original tpm module and haven't been
# validated yet.  They are currently being kept for reference during the tpm2
# transition, and may no longer be relevant.

# Contains the tests for modules init and both install modules.
#
shared_examples_for 'tpm2 default' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('tpm2') }
  it { is_expected.to create_class('tpm2::install') }
  it { is_expected.to contain_package('tpm2-tools').with_ensure('installed') }
  it { is_expected.to contain_package('tpm2-tss').with_ensure('installed') }
  it { is_expected.to contain_package('tpm2-abrmd').with_ensure('installed') }
  it { is_expected.to create_class('tpm2::service') }
  it { is_expected.to contain_service('tpm2-abrmd') }
end

describe 'tpm2' do
  on_supported_os.each do |os, os_facts|
    context "tpm2 init on #{os}" do
      let(:facts) do
        os_facts.merge(
          fqdn: 'myhost.com',
        )
      end

      context 'with default params' do
        it_behaves_like 'tpm2 default'
        it { is_expected.not_to create_class('tpm2::ownership') }
        it { is_expected.not_to contain_systemd__dropin_file('tabrm_service.conf') }
      end

      context 'with detected TPM1 version TPM' do
        let(:facts) do
          os_facts.merge(
            tpm_version: 'tpm1',
          )
        end

        it 'works properly' do
          is_expected.to create_notify('tpm2_with_tpm1')
        end
      end

      context 'with service options' do
        let(:params) do
          {
            tabrm_options: [
              '-option1',
              '-option2 X',
            ],
            tabrm_service: 'tpm2-abrmd-service',
          }
        end
        let(:hieradata) { 'take_ownership' }

        it {
          is_expected.to contain_systemd__dropin_file('tabrm_service.conf').with(
            unit: 'tpm2-abrmd-service.service',
            notify: 'Service[tpm2-abrmd-service]',
          )
        }
        it {
          is_expected.to contain_systemd__dropin_file('tabrm_service.conf').with_content(<<~EOM)
            # This file managed by Puppet
            [Unit]
            ConditionPathExistsGlob=

            [Service]
            ExecStart=
            ExecStart=/usr/sbin/tpm2-abrmd-service -option1 -option2 X
          EOM
        }
      end

      context 'with take_ownership true' do
        let(:params) do
          {
            take_ownership: true,
          }
        end

        it_behaves_like 'tpm2 default'
        it { is_expected.to contain_class('tpm2::ownership') }
      end
    end
  end
end
