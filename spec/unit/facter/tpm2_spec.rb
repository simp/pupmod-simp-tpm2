require 'spec_helper'
require 'facter/tpm2'
require 'facter/tpm2/util'
require 'ostruct'

describe 'tpm2', :type => :fact do

  before :all do
    @l_bin = '/usr/local/bin'
    @u_bin = '/usr/bin'
  end

  context 'when a hardware TPM is installed' do
    it 'should return nil' do
      allow(Facter).to receive(:value).with(:has_tpm).and_return true
      allow(Facter).to receive(:value).with(:tpm).and_return({ :tpm1_hash => :values })
      allow(Facter::Core::Execution).to receive(:execute).with(%r{uname$}).and_return true
      allow(Facter::Core::Execution).to receive(:execute).with(%r{.*/?tpm_version$}, :timeout => 15).and_return nil
      expect(Facter).to receive(:fact).with(:tpm2).and_call_original

      expect(Facter.fact(:tpm2).value).to eq nil
    end
  end

  context 'The hardware TPM is TPM 2.0' do
    it 'should return a fact' do
      allow(Facter).to receive(:value).with(:has_tpm).and_return true
      allow(Facter).to receive(:value).with(:tpm).and_return( nil )
      allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return(false)
      allow(File).to receive(:executable?).with("#{@u_bin}/tpm2_pcrlist").and_return( true )
      allow(Facter).to receive(:value).with(:has_tpm).and_return true
      allow(Facter::Core::Execution).to receive(:execute).with("#{@u_bin}/tpm2_getcap -c properties-fixed").and_return(
      File.read File.expand_path(
          '../../../files/tpm2/mocks/tpm2_getcap_-c_properties-fixed/nuvoton-ncpt6xx-fbfc85e.yaml',
          __FILE__,
        )
      )
      allow(Facter::Core::Execution).to receive(:execute).with("#{@u_bin}/tpm2_pcrlist -s").and_return(
          "Supported Bank/Algorithm: sha1(0x0004) sha256(0x000b) sha384(0x000c)\n"
        )
      fact = Facter.fact(:tpm2).value
      expect(fact).to be_a(Hash)
      expect(fact['manufacturer']).to match(/.{0,4}/)
      expect(fact['firmware_version']).to match(/^\d+\.\d+\.\d+\.\d+$/)
      expect(fact['tpm2_getcap']['properties-fixed']).to be_a(Hash)
    end
  end
end
