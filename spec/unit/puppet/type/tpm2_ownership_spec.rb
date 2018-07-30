#!/usr/bin/env rspec

require 'spec_helper'

tpm2_ownership_type = Puppet::Type.type(:tpm2_ownership)

describe 'tpm2_ownership_type' do

  context 'when setting parameters' do
    it 'should accept a name parameter and set defaults' do
      resource = tpm2_ownership_type.new :name => 'tpm2', :owner => 'clear'
      expect(resource[:name]).to eq('tpm2')
      expect(resource[:owner]).to eq(:clear)
      expect(resource[:in_hex]).to eq(false)
      expect(resource[:owner_auth]).to eq('')
      expect(resource[:endorsement_auth]).to eq('')
      expect(resource[:lockout_auth]).to eq('')
    end

    it 'should not accept a name change' do
      expect {
        tpm2_ownership_type.new :name =>  'foo', :owner => 'set', :lockout => 'set', :endorsement => 'set', :owner_auth => 'password', :endorsement_auth => 'password'
       }.to raise_error(Puppet::ResourceError,/Parameter name failed on Tpm2_ownership\[foo\]:/)
    end

    it 'should accept password parameters ' do
      resource = tpm2_ownership_type.new :name => 'tpm2', :owner => 'set', :owner_auth => 'password', :lockout_auth => 'password', :endorsement_auth => 'password'
      expect(resource[:owner_auth]).to eq('password')
      expect(resource[:endorsement_auth]).to eq('password')
      expect(resource[:lockout_auth]).to eq('password')
    end

    it 'should not accept bad parameters' do
      expect {
        tpm2_ownership_type.new :name =>  'tpm2', :owner => 'goofy', :lockout => 'goofier', :endorsement => 'goofiest', :owner_auth => 'password', :endorsement_auth => 'password'
      }.to raise_error(/Invalid value "goofy". Valid values are clear, set/)
    end

    it 'should error if there is no password for lockout_auth and lock = set' do
      expect {
        tpm2_ownership_type.new :name =>  'tpm2', :owner => 'set', :lockout => 'set', :endorsement => 'set', :owner_auth => 'password', :endorsement_auth => 'password'
      }.to raise_error(Puppet::ResourceError,/lockout_auth, must be provided/i)
#      }.to raise_error(Puppet::ResourceError,/Password parameter, lockout_auth, must be provided when lock \= \'set\'/i)
    end
  end
end

