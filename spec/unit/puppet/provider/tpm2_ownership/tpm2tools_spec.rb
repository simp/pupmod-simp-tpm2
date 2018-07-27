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


  let(:provider) { resource.provider }
  let (:resource) {
    Puppet::Type.type(:tpm2_ownership).new({
    :name         => 'tpm2',
    :owner        => 'clear',
    :lock         => 'clear',
    :endorsement  => 'clear',
    :provider     => 'tpm2tools'
    })}

  describe 'get_password_options' do
    context 'first set' do
      let (:resource) {
        Puppet::Type.type(:tpm2_ownership).new({
        :name         => 'tpm2',
        :owner_auth   => 'ownerpassword',
        :lock_auth    => 'lockpassword',
        :endorse_auth => 'endorsepassword',
        :owner        => 'set',
        :lock         => 'set',
        :endorsement  => 'clear',
        :provider     => 'tpm2tools'
        })}

      let (:current1) {{
        :owner => :clear,
        :endorsement => :clear,
        :lock => :clear,
      }}
      it 'should return lower case options for all but endorsement' do
        allow(Facter).to receive(:value).with(:kernel).and_return(:Linux)
        passwd_args = provider.get_passwd_options(current1,resource)
        expect(passwd_args).to eq(['-o','ownerpassword','-l','lockpassword'])
      end
    end
    context 'second set' do
      # If current = set and desired = set then you must clear it and set it, hence ['-O','ownerpassword','-o','ownerpassword']
      # If current = clear and desired = set then you need to set it, hence ['-e','endorsepassword']
      # if current = set and desired = clear then you need to clear it, hence ['-L','lockpassword']
      let (:resource) {
        Puppet::Type.type(:tpm2_ownership).new({
        :name         => 'tpm2',
        :owner_auth   => 'ownerpassword',
        :lock_auth    => 'lockpassword',
        :endorse_auth => 'endorsepassword',
        :owner        => 'set',
        :lock         => 'clear',
        :endorsement  => 'set',
        :in_hex       => 'true',
        :provider     => 'tpm2tools'
        })}

      let (:current2) {{
        :owner => :set,
        :endorsement => :clear,
        :lock => :set,
      }}
      it 'should return set for all passwords' do
        provider = resource.provider
        passwd_args = provider.get_passwd_options(current2,resource)
        expect(passwd_args).to eq(['-O','ownerpassword','-o','ownerpassword','-e','endorsepassword','-L','lockpassword', '-X'])
      end
    end
  end
  describe 'get_clear_ownership_options' do
    let (:resource) {
      Puppet::Type.type(:tpm2_ownership).new({
      :name         => 'tpm2',
      :owner_auth   => 'ownerpassword',
      :lock_auth    => 'lockpassword',
      :endorse_auth => 'endorsepassword',
      :owner        => 'clear',
      :lock         => 'clear',
      :endorsement  => 'clear',
      :provider     => 'tpm2tools'
      })}

    context 'clear when lock password is not set' do
      let (:current) {{
        :owner => :set,
        :endorsement => :set,
        :lock => :clear,
      }}
      it 'should return -c' do
        allow(Facter).to receive(:value).with(:kernel).and_return(:Linux)
        passwd_args = provider.get_clear_ownership_options(current)
        expect(passwd_args).to eq(['-c'])
      end
    end
    context 'clear when lock password is set' do
      let (:current) {{
        :owner => :set,
        :endorsement => :set,
        :lock => :set,
      }}
      it 'should return -c with lock auth password' do
        allow(Facter).to receive(:value).with(:kernel).and_return(:Linux)
        passwd_args = provider.get_clear_ownership_options(current)
        expect(passwd_args).to eq(['-c', '-L', 'lockpassword'])
      end
    end
  end
end
