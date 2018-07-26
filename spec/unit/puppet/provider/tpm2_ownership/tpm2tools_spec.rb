require 'spec_helper'
require 'json'
require 'yaml'
require 'facter'

describe Puppet::Type.type(:tpm2_ownership).provider(:tpm2tools) do



  let(:all_clear) {
    YAML.safe_load(File.read(File.expand_path('spec/files/tpm2/mocks/tpm2_getcap_-c_properties-variable/clear-clear-clear.yaml')))
  }

  let(:all_set) {
    YAML.safe_load(File.read(File.expand_path('spec/files/tpm2/mocks/tpm2_getcap_-c_properties-variable/set-set-set.yaml')))
  }

  let(:mixed) {
    YAML.safe_load(File.read(File.expand_path('spec/files/tpm2/mocks/tpm2_getcap_-c_properties-variable/set-set-clear.yaml')))
  }
  let (:expected_hash1) {{
    :owner => :clear,
    :endorsement => :clear,
    :lock => :clear,
    'reserved1' => :clear,
    'disableClear' => :clear,
    'inLockout' => :clear,
    'tpmGeneratedEPS' => :set,
    'reserved2' => :clear,
  }}

  let(:resource) {
    Puppet::Type.type(:tpm2_ownership).new({
      :name         => 'tpm2',
      :owner_auth   => 'ownerpassword',
      :lock_auth    => 'lockpassword',
      :endorse_auth => 'endorsepassword',
      :owner        => 'set',
      :lock         => 'set',
      :endorsement  => 'set',
      :provider     => 'tpm2tools'
    })
  }

  let(:provider) { resource.provider }


  describe 'get_password_options' do
    context 'first set' do
      let (:current1) {{
        :owner => :clear,
        :endorsement => :clear,
        :lock => :clear,
      }}
      let (:desired1) {{
        :owner => :set,
        :endorsement => :set,
        :lock => :set,
      }}
      let (:facts) {{
        :tpm2 => {'tpm2_getcap' => { 'properties-variable' => all_clear}, 'auth_status' => true }
      }}
      it 'should return lower case options for all passwords' do
#        Facter.clear
#        allow(Facter).to receive(:fact).with(:tpm2).and_return(Facter.add(:tpm2) {setcode {{'tpm2_getcap' => { 'properties-variable' => all_clear}, 'auth_status' => true }}})
        resource = Puppet::Type.type(:tpm2_ownership).new({
          :name         => 'tpm2',
          :owner_auth   => 'ownerpassword',
          :lock_auth    => 'lockpassword',
          :endorse_auth => 'endorsepassword',
          :owner        => 'set',
          :lock         => 'set',
          :endorsement  => 'set',
          :provider     => 'tpm2tools'
        })
        provider = resource.provider
        passwd_args = provider.get_passwd_options(current1,desired1)
        expect(passwd_args).to eq([['-o','ownerpassword'],['-e','endorsepassword'],['-l','lockpassword']])
      end
    end
    context 'second set' do
      # If current = set and desired = set then you must clear it and set it, hence ['-O','ownerpassword','-o','ownerpassword']
      # If current = clear and desired = set then you need to set it, hence ['-e','endorsepassword']
      # if current = set and desired = clear then you need to clear it, hence ['-L','lockpassword']
      let (:current2) {{
        :owner => :set,
        :endorsement => :clear,
        :lock => :set,
      }}
      let (:desired2) {{
        :owner => :set,
        :endorsement => :set,
        :lock => :clear,
      }}
      it 'should return set for all passwords' do
        allow(Facter).to receive(:value).with(:tpm2).and_return({'tpm2_getcap' => { 'properties-variable' => mixed }, 'auth_status' => true })
        resource =  Puppet::Type.type(:tpm2_ownership).new({
          :name         => 'tpm2',
          :owner_auth   => 'ownerpassword',
          :lock_auth    => 'lockpassword',
          :endorse_auth => 'endorsepassword',
          :owner        => 'set',
          :lock         => 'clear',
          :endorsement  => 'set',
          :provider     => 'tpm2tools'
        })
        provider = resource.provider
        passwd_args = provider.get_passwd_options(current2,desired2)
        expect(passwd_args).to eq([['-O','ownerpassword','-o','ownerpassword'],['-e','endorsepassword'],['-L','lockpassword']])
      end
    end
  end

end
