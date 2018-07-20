require 'spec_helper'

# Some contexts are holdovers from the original tpm module and haven't been
# validated yet.  They are currently being kept for reference during the tpm2
# transition, and may no longer be relevant.
xmessage = 'TODO: validate this spec, then activate or remove it.'

# Contains the tests for modules init and both install modules.
#
describe 'tpm2::ownership' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
        })
      end

      context 'with default parameters' do
        it { is_expected.to create_class('tpm2::ownership') }
        it {is_expected.to compile.and_raise_error(/You must supply one of the following parameters: allauth, owner, endorsement, lock/)}
      end

      context 'with default parameters and no physical TPM', :skip => xmessage do
        let(:facts) do
          os_facts.merge({
          })
        end
        let(:params) {{
          :allauth => 'clear'
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_tpm2__ownership('tpm2').with({
          'allauth' => 'clear'
          })},
      end

    end
  end
end
