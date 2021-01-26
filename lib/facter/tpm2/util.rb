require 'yaml'

module Facter; end

# Namespace for TPM2-related classes
#
# @see Facter::TPM2::Util Facter::TPM2::Util - Utilities for detecting and
#   reporting TPM 2.0 details
module Facter::TPM2; end

# Utilities for detecting and reporting TPM 2.0 information
#
# @note This class requires the following software to be installed on the
#   underlying operating system:
#   - `tpm2-tools` ~> 3.0 (tested with 3.0.3)
#   - (probably) `tpm2-abrmd` ~> 1.2 (tested with 1.2.0)
#   - `tpm2-tools` (and probably `tpm2-abrmd`) must be configured to access TPM
#
# @note TPM devices are assumed to follow the TCG PC Client PTP Specification
#   (https://trustedcomputinggroup.org/pc-client-platform-tpm-profile-ptp-specification/)
#
class Facter::TPM2::Util
  def initialize
    cmd  = Facter::Core::Execution.which('tpm2_getcap')

    # Between versions the options for 'tpm2_getcap' changed. Determine the
    #  version and set the options.
    output = Facter::Core::Execution.execute(%(#{cmd} -v))
    result = output.match(/version="(\d+\.\d+\.\d+)/)
    @version = $1
    if Gem::Version.new(@version) < Gem::Version.new('4.0.0')
      @tpm2_getcap = "#{cmd} -c"
      @prefix = 'TPM'
    else
      @prefix = 'TPM2'
      @tpm2_getcap = "#{cmd}"
    end
    Facter.debug "tpm2_getcap version is #{@version} using command #{@tpm2_getcap}"
  end

  # Translate a TPM_PT_MANUFACTURER number into the TCG-registered ID strings
  #   (registry at: https://trustedcomputinggroup.org/vendor-id-registry/)
  #
  # @param num [Numeric] number to decode (from `TPM_PT_MANUFACTURER`)
  # @return [String] the decoded String
  def decode_uint32_string(num)
    # rubocop:disable Style/FormatStringToken
    # NOTE: Only strip "\x00" from the end of strings; some registered
    #       identifiers include trailing spaces (e.g., 'NSM ')!
    if num.instance_of? Hash
      num['value']
    else
      ('%x' % num).scan(/.{2}/).map { |x| x.hex.chr }.join.gsub(/\x00*$/,'')
      # rubocop:enable Style/FormatStringToken
    end
  end

  # Converts two unsigned Integers in a 4-part version string
  def tpm2_firmware_version(tpm_pt_firmware_version_1,tpm_pt_firmware_version_2)
    if tpm_pt_firmware_version_1.instance_of? Hash
       _tpm_pt_firmware_version_1  = tpm_pt_firmware_version_1['raw']
       _tpm_pt_firmware_version_2  = tpm_pt_firmware_version_2['raw']
    else
      _tpm_pt_firmware_version_1 = tpm_pt_firmware_version_1
      _tpm_pt_firmware_version_2 = tpm_pt_firmware_version_2
    end
    # rubocop:disable Style/FormatStringToken
    s1 = ('%x' % _tpm_pt_firmware_version_1).rjust(8,'0')
    s2 = ('%x' % _tpm_pt_firmware_version_2).rjust(8,'0')
    # rubocop:enable Style/FormatStringToken
    (s1.scan(/.{4}/) + s2.scan(/.{4}/)).map{|x| x.hex }.join('.')
  end

  def tpm2_vendor_strings( tpm2_properties )
    if Gem::Version.new(@version) < Gem::Version.new('4.0.0')
      [
         tpm2_properties["#{@prefix}_PT_VENDOR_STRING_1"]['as string'],
         tpm2_properties["#{@prefix}_PT_VENDOR_STRING_2"]['as string'],
         tpm2_properties["#{@prefix}_PT_VENDOR_STRING_3"]['as string'],
         tpm2_properties["#{@prefix}_PT_VENDOR_STRING_4"]['as string'],
      ]
    else
      [
        tpm2_properties["#{@prefix}_PT_VENDOR_STRING_1"]['value'],
        tpm2_properties["#{@prefix}_PT_VENDOR_STRING_2"]['value'],
        tpm2_properties["#{@prefix}_PT_VENDOR_STRING_3"]['value'],
        tpm2_properties["#{@prefix}_PT_VENDOR_STRING_4"]['value'],
      ]
    end
  end


  # Decode properties that the TPM is required to provide, even in failure mode
  #
  # The property keys and values are made as human-readable as possible.
  # The firmware manufacturer string and version numbers are decoded into UTF-8
  # according to the TPM 2.0 specs and observed implementations.
  #
  # @param [Hash] fixed_props properties as collected by `tpm2_getcap -c properties-fixed`
  # @param [Hash] variable_props properties as collected by `tpm2_getcap -c properties-variable`
  #
  # @return [Hash] Decoded
  def failure_safe_properties(fixed_props,variable_props)
    {
      'manufacturer'     => decode_uint32_string(
                              fixed_props["#{@prefix}_PT_MANUFACTURER"]
                            ),
      'vendor_strings'   => tpm2_vendor_strings( fixed_props ),
      'firmware_version' => tpm2_firmware_version(
                              fixed_props["#{@prefix}_PT_FIRMWARE_VERSION_1"],
                              fixed_props["#{@prefix}_PT_FIRMWARE_VERSION_2"]
                            ),
      'tools_version'    => @version,
      'tpm2_getcap'      => { 'properties-fixed' => fixed_props, 'properties-variable' => variable_props }
    }
  end

  # Returns a structured fact describing the TPM 2.0 data
  # @return [nil] if TPM data cannot be retrieved.
  # @return [Hash] TPM2 properties
  def build_structured_fact

    # Get fixed properties
    yaml = Facter::Core::Execution.execute(%(#{@tpm2_getcap} properties-fixed))
    return nil if yaml.nil?
    yaml = yaml.strip
    return nil if yaml.empty?
    properties_fixed = YAML.safe_load(yaml)

    #Get variable properties
    yaml = Facter::Core::Execution.execute(%(#{@tpm2_getcap} properties-variable))
    return nil if yaml.nil?
    yaml = yaml.strip
    return nil if yaml.empty?
    properties_variable = YAML.safe_load(yaml)

    failure_safe_properties(properties_fixed, properties_variable)

  end

end
