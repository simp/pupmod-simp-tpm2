require 'spec_helper'

# Some contexts are holdovers from the original tpm module and haven't been
# validated yet.  They are currently being kept for reference during the tpm2
# transition, and may no longer be relevant.
xmessage = 'TODO: validate this spec, then activate or remove it.'

# Contains the tests for modules init and both install modules.
#
describe 'tpm2' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
        })
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm2') }
        it { is_expected.to create_service('tpm2-abrmd') }
      end

      xcontext 'with default parameters and no physical TPM', :skip => xmessage do
        let(:facts) do
          os_facts.merge({
          })
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm2') }
      end


      xcontext 'with detected TPM unable to determine TPM type', :skip => xmessage do
        let(:facts) do
          os_facts.merge({
          })
        end

      end

      context 'with a detected TPM version 2' do
        let(:facts) do
          os_facts.merge({
          })
        end

        context 'with default params' do
          if os_facts[:os][:release][:major].to_i < 7
            context 'on os version < 7 ' do
              it { is_expected.to_not compile}
            end
          else
            context 'on  os version => 7' do
              it { is_expected.to compile.with_all_deps }
              it { is_expected.to create_class('tpm2') }
              it { is_expected.not_to create_class('tpm2::ima') }
              it { is_expected.not_to create_class('tpm2::ownership') }
              it { is_expected.to create_class('tpm2::install') }
              it { is_expected.to contain_package('simp-tpm2-tools').with_ensure('installed') }
              it { is_expected.to contain_package('simp-tpm2-tss').with_ensure('installed') }
              it { is_expected.to contain_package('simp-tpm2-abrmd').with_ensure('installed') }
              it { is_expected.to contain_package('simp-tpm2-abrmd-selinux').with_ensure('installed') }
            end
          end
        end

        xcontext 'with take_ownership true', skip: xmessage do
          let(:params) {{ :take_ownership => true }}

          if os_facts[:os][:release][:major].to_i < 7
            context 'on os version < 7 ' do
              it { is_expected.to_not compile}
            end
          else
            context 'on os version >= 7 ' do
              it { is_expected.to compile.with_all_deps }
              it { is_expected.to create_class('tpm2') }
              it { is_expected.not_to create_class('tpm2::ima') }
              it { is_expected.to create_class('tpm2::tpm2::ownership') }
              it { is_expected.to create_class('tpm2::tpm2::install') }
              it { is_expected.to contain_package('simp-tpm2-tools').with_ensure('installed') }
              it { is_expected.to contain_package('simp-tpm2-tss').with_ensure('installed') }
              it { is_expected.to contain_package('simp-tpm2-abrmd').with_ensure('installed') }
              it { is_expected.to contain_package('simp-tpm2-abrmd-selinux').with_ensure('installed') }
            end
          end
        # take_ownership true
        end
      #TPM2.0
      end
    end
  end
end
