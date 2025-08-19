require 'spec_helper'
require 'facter/tpm2'
require 'facter/tpm2/util'
require 'ostruct'

describe 'tpm2', type: :fact do
  before :each do
    Facter.clear
  end
  let :tpm2_getcap do
    '/usr/bin/tpm2_getcap'
  end

  context 'when tpm2-tools is not installed' do
    it 'returns nil' do
      allow(Facter::Core::Execution).to receive(:which).with('tpm2_getcap').and_return(nil)
      expect(Facter.fact(:tpm2).value).to eq nil
    end
  end

  context 'when the TPM tools is installed' do
    context 'when the version of tpm2_getcap is less than 4.0.0' do
      let :content do
        "tool=\"tpm2_getcap\" version=\"3.0.2\" tctis=\"tabrmd,\"\n"
      end
      let :content_fixed do
        File.read File.expand_path(
          '../../../files/tpm2/mocks/tpm2_getcap_-c_properties-fixed/nuvoton-ncpt6xx-fbfc85e.yaml',
          __FILE__,
        )
      end
      let :content_variable do
        File.read File.expand_path(
          '../../../files/tpm2/mocks/tpm2_getcap_-c_properties-variable/clear-clear-clear.yaml',
          __FILE__,
        )
      end

      it 'returns a fact' do
        allow(Facter::Core::Execution).to receive(:which).with('tpm2_getcap').and_return(tpm2_getcap)
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -v").and_return(content)
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -c properties-fixed").and_return(content_fixed)
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -c properties-variable").and_return(content_variable)
        fact = Facter.fact(:tpm2).value
        expect(fact).to be_a(Hash)
        expect(fact['manufacturer']).to match(%r{.{0,4}})
        expect(fact['firmware_version']).to match(%r{^\d+\.\d+\.\d+\.\d+$})
        expect(fact['tpm2_getcap']['properties-fixed']).to be_a(Hash)
        expect(fact['tpm2_getcap']['properties-variable']).to be_a(Hash)
      end
    end
    context 'when the version of tpm2_getcap is greater than 4.0.0' do
      let :content do
        "tool=\"tpm2_getcap\" version=\"4.3.2\" tctis=\"tabrmd,\"\n"
      end
      let :content_fixed do
        File.read File.expand_path(
          '../../../files/tpm2/mocks/tpm2_getcap_properties-fixed/simulator_fixed.yaml',
          __FILE__,
        )
      end
      let :content_variable do
        File.read File.expand_path(
          '../../../files/tpm2/mocks/tpm2_getcap_properties-variable/clear-clear-clear.yaml',
          __FILE__,
        )
      end

      it 'returns a fact' do
        allow(Facter::Core::Execution).to receive(:which).with('tpm2_getcap').and_return(tpm2_getcap)
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -v").and_return(content)
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} properties-fixed").and_return(content_fixed)
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} properties-variable").and_return(content_variable)
        fact = Facter.fact(:tpm2).value
        expect(fact).to be_a(Hash)
        expect(fact['manufacturer']).to match(%r{.{0,4}})
        expect(fact['firmware_version']).to match(%r{^\d+\.\d+\.\d+\.\d+$})
        expect(fact['tpm2_getcap']['properties-fixed']).to be_a(Hash)
        expect(fact['tpm2_getcap']['properties-variable']).to be_a(Hash)
      end
    end
  end
end
