require 'spec_helper'
require 'rspec/mocks'
require 'facter/tpm2/util'

describe Facter::TPM2::Util do
  before :all do
    @l_bin = '/usr/local/bin'
    @u_bin = '/usr/bin'
  end
  describe '::tpm2_tools_prefix' do
    context "tpm2-tools aren't installed" do
      it 'should return nil' do
        allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( false )
        allow(File).to receive(:executable?).with("#{@u_bin}/tpm2_pcrlist").and_return( false )
        expect(Facter::TPM2::Util.tpm2_tools_prefix).to eq nil
      end
    end
    context "tpm2-tools are only under /usr/local" do
      it 'should choose the correct path' do
        allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( true )
        allow(File).to receive(:executable?).with("#{@u_bin}/tpm2_pcrlist").and_return( false )
        expect(Facter::TPM2::Util.tpm2_tools_prefix).to eq @l_bin
      end
    end
    context "tpm2-tools are only under /usr" do
      it 'should choose the correct path' do
        allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( false )
        allow(File).to receive(:executable?).with("#{@u_bin}/tpm2_pcrlist").and_return( true )
        expect(Facter::TPM2::Util.tpm2_tools_prefix).to eq @u_bin
      end
    end
    context "tpm2-tools are installed under both /usr/local AND /usr" do
      it 'should choose the most specific path (/usr/local/bin)' do
        allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( true )
        allow(File).to receive(:executable?).with("#{@u_bin}/tpm2_pcrlist").and_return( true )
        expect(Facter::TPM2::Util.tpm2_tools_prefix).to eq @l_bin
      end
    end
  end

  describe '#build_structured_fact' do
    context "when tpm2-tools aren't installed" do
      it 'should return nil' do
        allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( false )
        allow(File).to receive(:executable?).with("#{@u_bin}/tpm2_pcrlist").and_return( false )
        util = Facter::TPM2::Util.new
        expect( util.build_structured_fact ).to be nil
      end
    end

    context "when tpm2-tools are installed" do
      before :each do
        allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( true )
      end

      context 'when tpm2-tools cannot query the TABRM' do
        it 'should return nil' do
          allow(Facter::Core::Execution).to receive(:execute).with( "#{@l_bin}/tpm2_pcrlist -s").and_return( nil )
          util = Facter::TPM2::Util.new
          expect( util.build_structured_fact ).to be nil
        end
      end
    end
    context 'when tpm2-tools can query the TABRM' do
      # Test against `tpm2_getcap -c properties-fixed` dumps from as many
      # manufacturers/models as we can find
      it 'should return a correct data structure queried from the TPM of any manufacturer' do
        # Modeling an @base EL7 rpm install of tpm2-tools
        allow(File).to receive(:executable?).with("#{@l_bin}/tpm2_pcrlist").and_return( false )
        allow(File).to receive(:executable?).with("#{@u_bin}/tpm2_pcrlist").and_return( true )

        variable_yaml_string = File.read(File.expand_path('../../../../files/tpm2/mocks/tpm2_getcap_-c_properties-variable/set-set-set.yaml', __FILE__) )
        allow(Facter::Core::Execution).to receive(:execute).with("#{@u_bin}/tpm2_getcap -c properties-variable").and_return(variable_yaml_string)
        allow(Facter::Core::Execution).to receive(:execute).with("#{@u_bin}/tpm2_pcrlist -s").and_return(
          "Supported Bank/Algorithm: sha1(0x0004) sha256(0x000b) sha384(0x000c)\n"
        )
        yaml_files = Dir.glob( File.expand_path( '../../../../files/tpm2/mocks/tpm2_getcap_-c_properties-fixed/*.yaml', __FILE__) )
        yaml_strings = yaml_files.map{ |yaml_file| File.read yaml_file }
        yaml_strings.each do |yaml_string|
          allow(Facter::Core::Execution).to receive(:execute).with("#{@u_bin}/tpm2_getcap -c properties-fixed").and_return( yaml_string )
          util = Facter::TPM2::Util.new
          fact = util.build_structured_fact
          expect(fact).to be_a(Hash)
          expect(fact['manufacturer']).to match(/.{0,4}/)
          expect(fact['firmware_version']).to match(/^\d+\.\d+\.\d+\.\d+$/)
          expect(fact['tpm2_getcap']['properties-fixed']).to be_a(Hash)
          expect(fact['tpm2_getcap']['properties-fixed']['TPM_PT_FAMILY_INDICATOR']['as string']).to eql '2.0'
        end
      end
    end
  end


  describe '#validate_ekc_cert' do
    context "when tpm2-tools are installed" do
      before :each do

      end

      context 'when tpm2-tools cannot query the TABRM' do
        it 'should return nil' do
          allow(Facter::Core::Execution).to receive(:execute).with( "#{@l_bin}/tpm2_pcrlist -s").and_return( nil )
          util = Facter::TPM2::Util.new
          expect( util.build_structured_fact ).to be nil
        end
      end

      xcontext 'when tpm2-tools can query the TABRM', :skip => 'FIXME: acquire TPM2 EK certificate + pubkey sample files to test' do
        before :each do
          allow(Facter::Core::Execution).to receive(:execute).with("#{@l_bin}/tpm2_pcrlist -s").and_return(
            "Supported Bank/Algorithm: sha1(0x0004) sha256(0x000b) sha384(0x000c)\n"
          )
          allow(Facter::Core::Execution).to receive(:execute).with("#{@l_bin}/tpm2_getcap -c properties-fixed").and_return(
            File.read File.expand_path( '../../../../files/tpm2/mocks/tpm2_getcap_-c_properties-fixed/nuvoton-ncpt6xx-fbfc85e.yaml', __FILE__)
          )
        end
        it 'should populate result' do
          util = Facter::TPM2::Util.new
          expect( util.build_structured_fact.is_a? Hash ).to be true
        end
      end
      context 'when tpm2-tools can query the TABRM' do
      end
    end
  end
end
