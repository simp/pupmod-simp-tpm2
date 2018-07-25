require 'spec_helper'

describe 'tpm2::ownership' do
  on_supported_os.each do |os, os_facts|
    context "tpm2::ownership on #{os}" do
      let(:facts) do
        os_facts.merge({
        })
      end

      context 'with default parameters' do
        it { is_expected.to create_tpm2_ownership('tpm2').with({
          'owner'       => 'set',
          'lock'        => 'set',
          'endorsement' => 'set',
          'tcti'        => 'abrmd'
          })}
      end

      context 'with all set' do
        let(:params) {{
          :owner       => 'clear',
          :lock        => 'clear',
          :endorsement => 'set'
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_tpm2_ownership('tpm2').with({
          'owner'       => 'clear',
          'lock'        => 'clear',
          'endorsement' => 'set',
          'tcti'        => 'abrmd'
          })}
      end
    end
  end
end
