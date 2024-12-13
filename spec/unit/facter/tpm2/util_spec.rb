require 'spec_helper'
require 'rspec/mocks'
require 'facter/tpm2/util'

describe Facter::TPM2::Util do
  let :tpm2_getcap do
    '/usr/bin/tpm2_getcap'
  end

  before :each do
    allow(Facter::Core::Execution).to receive(:which).with('tpm2_getcap').and_return(tpm2_getcap)
    allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -v").and_return(version_info)
  end

  context 'with tpm2_getcap version < 4' do
    let :version_info do
      "tool=\"tpm2_getcap\" version=\"3.0.2\" tctis=\"tabrmd,\"\n"
    end

    context 'when tpm2-tools can query the TABRM' do
      # Test against `tpm2_getcap -c properties-fixed` dumps from as many
      # manufacturers/models as we can find
      it 'returns a correct data structure queried from the TPM of any manufacturer' do
        # Modeling an @base EL7 rpm install of tpm2-tools
        variable_yaml_string = File.read(File.expand_path('../../../../files/tpm2/mocks/tpm2_getcap_-c_properties-variable/set-set-set.yaml', __FILE__))
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -c properties-variable").and_return(variable_yaml_string)
        yaml_files = Dir.glob(File.expand_path('../../../../files/tpm2/mocks/tpm2_getcap_-c_properties-fixed/*.yaml', __FILE__))
        yaml_strings = yaml_files.map { |yaml_file| File.read yaml_file }
        yaml_strings.each do |yaml_string|
          allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -c properties-fixed").and_return(yaml_string)
          util = described_class.new
          fact = util.build_structured_fact
          expect(fact).to be_a(Hash)
          expect(fact['manufacturer']).to match(%r{.{0,4}})
          expect(fact['firmware_version']).to match(%r{^\d+\.\d+\.\d+\.\d+$})
          expect(fact['tpm2_getcap']['properties-fixed']).to be_a(Hash)
          expect(fact['tpm2_getcap']['properties-fixed']['TPM_PT_FAMILY_INDICATOR']['as string']).to eql '2.0'
        end
      end
    end
    context 'when tpm2-tools cannot query the TABRM' do
      it 'does not raise a failure' do
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -c properties-variable").and_return('')
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} -c properties-fixed").and_return('')

        util = described_class.new
        fact = util.build_structured_fact
        expect(fact).to be_nil
      end
    end

    xcontext 'when tpm2-tools can query the TABRM', skip: 'FIXME: acquire TPM2 EK certificate + pubkey sample files to test' do
      it 'populates result' do
        allow(Facter::Core::Execution).to receive(:execute).with('/usr/bin/tpm2_getcap -c properties-fixed').and_return(
        File.read(File.expand_path('../../../../files/tpm2/mocks/tpm2_getcap_-c_properties-fixed/nuvoton-ncpt6xx-fbfc85e.yaml', __FILE__)),
      )
        util = described_class.new
        expect(util.build_structured_fact.is_a?(Hash)).to be true
      end
    end
  end
  context 'with tpm2_getcap version >= 4' do
    let :version_info do
      "tool=\"tpm2_getcap\" version=\"4.0.2\" tctis=\"tabrmd,\"\n"
    end

    context 'when tpm2-tools can query the TABRM' do
      # Test against `tpm2_getcap -c properties-fixed` dumps from as many
      # manufacturers/models as we can find
      it 'returns a correct data structure queried from the TPM of any manufacturer' do
        # Modeling an @base EL7 rpm install of tpm2-tools
        variable_yaml_string = File.read(File.expand_path('../../../../files/tpm2/mocks/tpm2_getcap_properties-variable/set-set-set.yaml', __FILE__))
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} properties-variable").and_return(variable_yaml_string)
        yaml_files = Dir.glob(File.expand_path('../../../../files/tpm2/mocks/tpm2_getcap_properties-fixed/*.yaml', __FILE__))
        yaml_strings = yaml_files.map { |yaml_file| File.read yaml_file }
        yaml_strings.each do |yaml_string|
          allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} properties-fixed").and_return(yaml_string)
          util = described_class.new
          fact = util.build_structured_fact
          expect(fact).to be_a(Hash)
          expect(fact['manufacturer']).to match(%r{.{0,4}})
          expect(fact['firmware_version']).to match(%r{^\d+\.\d+\.\d+\.\d+$})
          expect(fact['tpm2_getcap']['properties-fixed']).to be_a(Hash)
          expect(fact['tpm2_getcap']['properties-fixed']['TPM2_PT_FAMILY_INDICATOR']['value']).to eql '2.0'
        end
      end
    end
    context 'when tpm2-tools cannot query the TABRM' do
      it 'does not raise a failure' do
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} properties-variable").and_return('')
        allow(Facter::Core::Execution).to receive(:execute).with("#{tpm2_getcap} properties-fixed").and_return('')

        util = described_class.new
        fact = util.build_structured_fact
        expect(fact).to be_nil
      end
    end
  end
end
