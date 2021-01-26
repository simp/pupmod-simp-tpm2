require 'spec_helper'
require 'json'
require 'yaml'
require 'facter'

describe 'Puppet::Type.type(:tpm2_changeauth).provider(:tpm2_changeauth)' do

  let(:all_clear) {
    YAML.safe_load(File.read(File.expand_path('spec/files/tpm2/mocks/facts/tpm2_fact_all_clear.yaml')))
  }

  let(:all_set) {
    YAML.safe_load(File.read(File.expand_path('spec/files/tpm2/mocks/facts/tpm2_fact_all_set.yaml')))
  }


  let(:provider_class) { Puppet::Type.type(:tpm2_changeauth).provider(:tpm2_changeauth) }

  before :each do
    @provider = provider_class.new
    allow(@provider).to receive(:command).with(:tpm2_changeauth).and_return("/usr/bin/tpm2_changeauth")
  end

  context 'with name set to owner' do
    let (:resource) {
      Puppet::Type.type(:tpm2_changeauth).new({
      :name         => 'owner',
      :state        => 'set',
      :auth         => 'password',
      :provider     => 'tpm2_changeauth'
      })}


    it 'should run tpm2_changeauth with the correct arguments' do
      allow(Facter).to receive(:value).with(:kernel).and_return(:Linux)
      allow(Facter).to receive(:value).with(:tpm2).and_return(all_clear)
      @provider.resource = resource

      expect(@provider.state).to eq(:clear)
      #expect(@provider.state=(:set)).to receive(:tpm2_changeauth).with('-c', 'o', 'password')

    end
  end
end
