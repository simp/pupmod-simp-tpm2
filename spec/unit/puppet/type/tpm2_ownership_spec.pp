#!/usr/bin/env rspec

require 'spec_helper'

tpm2_ownership_type = Puppet::Type.type(:tpm2_ownership)

describe tpm2_ownership_type do
  before(:each) do
    @catalog = Puppet::Resource::Catalog.new
    Puppet::Type::Tpm2_ownership.any_instance.stubs(:catalog).returns(@catalog)
  end

  context 'when setting parameters' do
    it 'should accept a name parameter and set defaults' do
      resource = tpm2_ownership_type.new :name => 'foo', :allauth => 'clear'
      expect(resource[:name]).to eq('foo')
      expect(resource[:allauth]).to eq(:clear)
      expect(resource[:tcti]).to eq(:abrmd)
      expect(resource[:in_hex]).to eq(false)
      expect(resource[:owner_auth]).to eq('')
      expect(resource[:endorse_auth]).to eq('')
      expect(resource[:lock_auth]).to eq('')
    end

    it 'should accept parameters for tcti socket' do
      resource = tpm2_ownership_type.new :name =>  'foo', :allauth => 'clear', :tcti => 'socket', :socket_port => 5894 , :socket_address => '8.8.8.8'
      expect(resource[:name]).to eq('foo')
      expect(resource[:tcti]).to eq(:socket)
      expect(resource[:socket_address]).to eq('8.8.8.8')
      expect(resource[:socket_port]).to eq(5894)
    end

    it 'should accept parameters for tcti device and in_hex' do
      resource = tpm2_ownership_type.new :name =>  'foo', :allauth => 'clear', :tcti => 'device', :devicefile => '/dev/myspace', :in_hex => true
      expect(resource[:name]).to eq('foo')
      expect(resource[:tcti]).to eq(:device)
      expect(resource[:in_hex]).to eq(true)
      expect(resource[:devicefile]).to eq('/dev/myspace')
    end

    it 'should accept password parameters ' do
      resource = tpm2_ownership_type.new :name => 'foo', :allauth => 'set', :owner_auth => 'password', :lock_auth => 'password', :endorse_auth => 'password'
      expect(resource[:owner_auth]).to eq('password')
      expect(resource[:endorse_auth]).to eq('password')
      expect(resource[:lock_auth]).to eq('password')
    end

    it 'should not accept bad parameters' do
      expect {
        tpm2_ownership_type.new :name => 'foo', :allauth => 'goofy', :owner_auth => 'password', :lock_auth => 'password', :endorse_auth => 'password'
      }.to raise_error(/Invalid value "goofy". Valid values are clear, set/)
    end

    it 'should fail if nothing to do' do
      expect {
        tpm2_ownership_type.new :name => 'foo'
      }.to raise_error(/Either "allauth" or one of "owner, endorsement, lock" properties must be set./)
    end

    it 'should error if there is no password and allauth = set' do
      expect {
        tpm2_ownership_type.new :name => 'foo', :allauth => 'set',  :lock_auth => 'password', :endorse_auth => 'password'
      }.to raise_error(/Passwords for all auth parameters must be provided/)
    end

    it 'should error if both allauth and individual settings are used' do
      expect {
        tpm2_ownership_type.new :name =>  'foo', :owner => 'set', :allauth => 'set', :owner_auth => 'password'
      }.to raise_error(/Cannot use both "allauth" and any of "owner, endorsement, lock"/)
    end

    it 'should error if there is no password for lock_auth and lock = set' do
      expect {
        tpm2_ownership_type.new :name =>  'foo', :owner => 'set', :lock => 'set',  :owner_auth => 'password', :endorse_auth => 'password'
      }.to raise_error(/Password parameter, lock_auth, must be provided when lock = 'set'/)
    end
  end
end

