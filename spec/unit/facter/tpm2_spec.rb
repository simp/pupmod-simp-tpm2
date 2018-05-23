require 'spec_helper'
require 'facter/tpm'
require 'facter/tpm2'
require 'facter/tpm2/util'

describe 'tpm2', :type => :fact do

  before :each do
    @l_bin = '/usr/local/bin'
    Facter.clear
    Facter.clear_messages
    allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( true )
  end

  context 'when a hardware TPM is installed' do
    before :each do
      allow(Facter.fact(:has_tpm)).to receive(:value).and_return true
    end
    context 'tpm_version is "tpm1"' do
      it 'should return nil' do
        # Just need something that actually exists on the current FS
        allow(Facter::Core::Execution).to receive(:which).with('tpm_version').and_return nil
        allow(Facter::Core::Execution).to receive(:execute).with(%r{#{@l_bin}/?tpm2_pcrlist -s$}).and_return nil
        allow(Facter::Core::Execution).to receive(:execute).with(%r{.*/?tpm_version$}, :timeout => 15).and_return nil
        allow(Facter.fact(:tpm_version)).to receive(:value).and_return 'tpm1'
        expect(Facter.fact(:tpm2).value).to eq nil
      end
    end
    context 'The hardware TPM is TPM 2.0' do
      before :each do
        allow(Facter.fact(:has_tpm)).to receive(:value).and_return true
          allow(Facter::Core::Execution).to receive(:execute).with("#{@l_bin}/tpm2_pcrlist -s").and_return(
            "Supported Bank/Algorithm: sha1(0x0004) sha256(0x000b) sha384(0x000c)\n"
          )
          allow(Facter::Core::Execution).to receive(:execute).with("#{@l_bin}/tpm2_getcap -c properties-fixed").and_return(
            File.read File.expand_path( '../../../files/tpm2/mocks/tpm2_getcap_-c_properties-fixed/nuvoton-ncpt6xx-fbfc85e.yaml', __FILE__)
          )
      end
      context 'tpm_version is "unknown"' do
        it 'should return a Hash' do
          allow(Facter.fact(:tpm_version)).to receive(:value).and_return 'unknown'
          expect(Facter.fact(:tpm2).value.is_a? Hash).to eq true
        end
      end
      context 'tpm_version is "tpm2"' do
        it 'should return a Hash' do
          allow(Facter.fact(:tpm_version)).to receive(:value).and_return 'tpm2'
          expect(Facter.fact(:tpm2).value.is_a? Hash).to eq true
        end
      end
    end
  end
end
