require 'spec_helper'

describe 'tpm2::ownership' do
  on_supported_os.each do |os, os_facts|
    let(:pre_condition) { 'include tpm2' }
    context "tpm2::ownership on #{os}" do
      context 'with tpm_tools < 4.0' do
        let(:facts) do
          os_facts.merge(
            tpm2: {
              'tools_version' => '3.0.1',
            },
          )
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to create_class('tpm2::ownership::takeownership').with(
              'owner'            => 'clear',
              'lockout'          => 'clear',
              'endorsement'      => 'clear',
              'in_hex'           => 'false',
              'lockout_auth'     => %r{^\w{24,}$},
              'endorsement_auth' => %r{^\w{24,}$},
              'owner_auth'       => %r{^\w{24,}$},
            )
          }

          it {
            is_expected.to create_tpm2_ownership('tpm2').with(
              'owner'            => 'clear',
              'lockout'          => 'clear',
              'endorsement'      => 'clear',
              'in_hex'           => 'false',
              'lockout_auth'     => %r{^\w{24,}$},
              'endorsement_auth' => %r{^\w{24,}$},
              'owner_auth'       => %r{^\w{24,}$},
            )
          }
        end

        context 'with all set' do
          let(:params) do
            {
              owner: 'set',
              lockout: 'set',
              endorsement: 'set',
              lockout_auth: 'MyMysteryPassword',
              endorsement_auth: 'MyMysteryPassword',
              owner_auth: 'MyMysteryPassword',
              in_hex: true,
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to create_class('tpm2::ownership::takeownership').with(
              'owner'            => 'set',
              'lockout'          => 'set',
              'endorsement'      => 'set',
              'lockout_auth'     => 'MyMysteryPassword',
              'endorsement_auth' => 'MyMysteryPassword',
              'owner_auth'       => 'MyMysteryPassword',
              'in_hex'           => 'true',
            )
          }

          it {
            is_expected.to create_tpm2_ownership('tpm2').with(
              'owner'            => 'set',
              'lockout'          => 'set',
              'endorsement'      => 'set',
              'lockout_auth'     => 'MyMysteryPassword',
              'endorsement_auth' => 'MyMysteryPassword',
              'owner_auth'       => 'MyMysteryPassword',
              'in_hex'           => 'true',
            )
          }
        end

        context 'with bad params' do
          let(:params) do
            {
              owner: 'set',
              lockout: 'set',
              endorsement: 'ignore',
              lockout_auth: 'MyMysteryPassword',
              endorsement_auth: 'MyMysteryPassword',
              owner_auth: 'MyMysteryPassword',
              in_hex: true,
            }
          end

          it { is_expected.to raise_error(%r{'ignore' is not a valid setting for param}) }
        end
      end

      context 'with tpm_tools > 4.0' do
        let(:facts) do
          os_facts.merge(
            tpm2: {
              'tools_version' => '4.4.1',
            },
          )
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to create_class('tpm2::ownership::changeauth').with(
              'owner'            => 'clear',
              'lockout'          => 'clear',
              'endorsement'      => 'clear',
              'lockout_auth'     => %r{^\w{24,}$},
              'endorsement_auth' => %r{^\w{24,}$},
              'owner_auth'       => %r{^\w{24,}$},
            )
          }

          it {
            is_expected.to contain_tpm2_changeauth('owner').with(
              'state' => 'clear',
              'auth'  => %r{^\w{24,}$},
            )
          }

          it {
            is_expected.to contain_tpm2_changeauth('lockout').with(
              'state' => 'clear',
              'auth'  => %r{^\w{24,}$},
            )
          }

          it {
            is_expected.to contain_tpm2_changeauth('endorsement').with(
              'state' => 'clear',
              'auth'  => %r{^\w{24,}$},
            )
          }
        end

        context 'with all ignore set' do
          let(:params) do
            {
              owner: 'set',
              lockout: 'set',
              endorsement: 'ignore',
              lockout_auth: 'MyMysteryPassword',
              endorsement_auth: 'MyMysteryPassword',
              owner_auth: 'MyMysteryPassword',
              in_hex: true,
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to create_class('tpm2::ownership::changeauth').with(
              'owner'            => 'set',
              'lockout'          => 'set',
              'endorsement'      => 'ignore',
              'lockout_auth'     => 'MyMysteryPassword',
              'endorment_auth'   => 'MyMysteryPassword',
              'owner_auth'       => 'MyMysteryPassword',
            )
          }

          it {
            is_expected.to contain_tpm2_changeauth('owner').with(
              'state' => 'set',
              'auth'  => 'MyMysteryPassword',
            )
          }

          it {
            is_expected.to contain_tpm2_changeauth('lockout').with(
              'state' => 'set',
              'auth'  => 'MyMysteryPassword',
            )
          }

          it { is_expected.not_to contain_tpm2_changeauth('endorsement') }
        end

        context 'with all ignore set on others' do
          let(:params) do
            {
              owner: 'ignore',
              lockout: 'ignore',
              endorsement: 'ignore',
              lockout_auth: 'MyMysteryPassword',
              endorsement_auth: 'MyMysteryPassword',
              owner_auth: 'MyMysteryPassword',
              in_hex: true,
            }
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to create_class('tpm2::ownership::changeauth').with(
              'owner'            => 'ignore',
              'lockout'          => 'ignore',
              'endorsement'      => 'ignore',
              'lockout_auth'     => 'MyMysteryPassword',
              'endorsement_auth' => 'MyMysteryPassword',
              'owner_auth'       => 'MyMysteryPassword',
            )
          }

          it { is_expected.not_to contain_tpm2_changeauth('owner') }
          it { is_expected.not_to contain_tpm2_changeauth('lockout') }
          it { is_expected.not_to contain_tpm2_changeauth('endorsement') }
        end
      end
    end
  end
end
