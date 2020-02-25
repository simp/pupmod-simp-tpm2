require 'spec_helper'

describe 'tpm2::ownership' do
  on_supported_os.each do |os, os_facts|

    let(:pre_condition){ 'include tpm2' }

    context "tpm2::ownership on #{os}" do
      let(:facts) do
        os_facts.merge({
        })
      end

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_tpm2_ownership('tpm2').with({
          'owner'            => 'clear',
          'lockout'          => 'clear',
          'endorsement'      => 'clear',
          'in_hex'           => 'false',
          'lockout_auth'     => /^[\w]{24,}$/,
          'endorsement_auth' => /^[\w]{24,}$/,
          'owner_auth'       => /^[\w]{24,}$/,
          'require'          => 'Class[Tpm2::Service]',
          })}
      end

      context 'with all set' do
        let(:params) {{
          :owner            => 'set',
          :lockout          => 'set',
          :endorsement      => 'set',
          :lockout_auth     => 'MyMysteryPassword',
          :endorsement_auth => 'MyMysteryPassword',
          :owner_auth       => 'MyMysteryPassword',
          :in_hex           => true
        }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_tpm2_ownership('tpm2').with({
          'owner'            => 'set',
          'lockout'          => 'set',
          'endorsement'      => 'set',
          'lockout_auth'     => 'MyMysteryPassword',
          'endorsement_auth' => 'MyMysteryPassword',
          'owner_auth'       => 'MyMysteryPassword',
          'in_hex'           => 'true',
          'require'          => 'Class[Tpm2::Service]',
          })}
      end
    end
  end
end
