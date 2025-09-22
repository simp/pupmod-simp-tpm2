#!/usr/bin/env rspec

require 'spec_helper'

tpm2_changeauth_type = Puppet::Type.type(:tpm2_changeauth)

describe 'tpm2_changeauth_type' do
  context 'when setting parameters' do
    it 'accepts a name parameter, owner and set defaults' do
      resource = tpm2_changeauth_type.new name: 'owner', state: 'clear', auth: 'password'
      expect(resource[:name]).to eq('owner')
      expect(resource[:state]).to eq(:clear)
      expect(resource[:auth]).to eq('password')
    end

    it 'accepts a name parameter and set settings' do
      resource = tpm2_changeauth_type.new name: 'endorsement', state: 'set', auth: 'password'
      expect(resource[:name]).to eq('endorsement')
      expect(resource[:state]).to eq(:set)
      expect(resource[:auth]).to eq('password')
    end
    it 'accepts a name parameter, lockout and set settings' do
      resource = tpm2_changeauth_type.new name: 'lockout', state: 'clear', auth: 'password'
      expect(resource[:name]).to eq('lockout')
      expect(resource[:state]).to eq(:clear)
      expect(resource[:auth]).to eq('password')
    end

    it 'name should be one of owner, endorsement ot lockout' do
      expect {
        tpm2_changeauth_type.new name: 'foo', state: 'set', auth: 'password'
      }.to raise_error(Puppet::ResourceError, %r{Parameter name failed on Tpm2_changeauth\[foo\]: Error: \$name must be one of \'owner\', \'lockout\', \'endorsement\'})
    end

    it 'does not accept bad parameters' do
      expect {
        tpm2_changeauth_type.new name: 'lockout', state: 'goofy', auth: 'password'
      }.to raise_error(%r{Invalid value "goofy". Valid values are clear, set})
      expect {
        tpm2_changeauth_type.new name: 'endorsement', state: 'clear', auth: [ 'password' ]
      }.to raise_error(%r{auth must be a String, not \'Array\'})
      expect {
        tpm2_changeauth_type.new name: 'endorsement', state: 'clear', auth: ''
      }.to raise_error(%r{auth must not be empty})
    end
  end
end
