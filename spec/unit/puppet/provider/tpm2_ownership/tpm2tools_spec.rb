require 'spec_helper'
require 'json'

describe Puppet::Type.type(:tpm2_ownership).provider(:tpm2tools) do


  let(:tpmdata1) {
    File.read(File.expand_path('spec/files/tpmdata1'))
  }

  let(:tpmdata2) {
    File.read(File.expand_path('spec/files/tpmdata2'))
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

  
  describe 'get_extra_args' do
    context 'with default parameters' do
      let(:resource) {
        Puppet::Type.type(:tpm2_ownership).new({
          :name         => 'tpm2',
          :owner_auth   => 'ownerpassword',
          :lock_auth    => 'lockpassword',
          :endorse_auth => 'endorsepassword',
          :owner        => 'set',
          :provider     => 'tpm2tools'
        })
      }
      it 'should return defaults' do
        options = provider.get_extra_args
        expect(options).to eq([
          ["--tcti", "abrmd"]
        ])
      end
    end
    context 'with socket set and in_hex set' do
      let(:resource) {
        Puppet::Type.type(:tpm2_ownership).new({
          :name           => 'tpm2',
          :owner_auth     => 'ownerpassword',
          :lock_auth      => 'lockpassword',
          :endorse_auth   => 'endorsepassword',
          :owner          => 'set',
          :tcti           => 'socket',
          :socket_address => '8.8.8.8',
          :in_hex         => true,
          :provider       => 'tpm2tools'
        })
      }
      it 'should return socket and hex parameters' do
        options = provider.get_extra_args
        expect(options).to eq([
         [ "--tcti", "socket" , "-R", "8.8.8.8", "-p" , "2323"],
         [ "-X"]
        ])
      end
    end
  end
  
  describe 'get_tpm_status' do
    let(:resource) {
      Puppet::Type.type(:tpm2_ownership).new({
        :name         => 'tpm2',
        :owner_auth   => 'ownerpassword',
        :lock_auth    => 'lockpassword',
        :endorse_auth => 'endorsepassword',
        :owner        => 'set',
        :provider     => 'tpm2tools'
      })
    }
    context 'with valid input' do
      it 'should return a hash of settings' do
#        provider.stubs(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').returns('bad data: junk')
        allow(provider).to receive(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').and_return(tpmdata1)
        status = provider.get_tpm_status
        expect(status).to eq(expected_hash1)
      end
    end
    context 'with no TPM_PT_PERSISTENT data returned' do
      it 'should return an error' do
#        provider.stubs(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').returns('bad data: junk')
        allow(provider).to receive(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').and_return('bad data: junk')
        expect { provider.get_tpm_status }.to raise_error(/tpm2_getcap did not return 'TPM_PT_PERSISTENT' data/)
      end
    end
    context 'with invalid input' do
     it 'should return an error' do
#        provider.stubs(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').returns('bad data')
        allow(provider).to receive(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').and_return('bad data')
        expect { provider.get_tpm_status }.to raise_error(/tpm2_getcap did not return 'TPM_PT_PERSISTENT' data/)
      end
    end
  end

  describe 'get_password_options' do
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
      it 'should return lower case options for all passwords' do
        allow(provider).to receive(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').and_return(tpmdata1)
#        provider.stubs(:tpm2_getcap).with([["--tcti","abrmd"]],'-c', 'properties-variable').returns(tpmdata1)
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
        passwd_args = provider.get_passwd_options(current2,desired2)
        expect(passwd_args).to eq([['-O','ownerpassword','-o','ownerpassword'],['-e','endorsepassword'],['-L','lockpassword']])
      end
    end
  end

end
