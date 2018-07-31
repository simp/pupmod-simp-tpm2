# The tpm_ownership type allows you to take ownership of tpm0.
#
# @!puppet.type.param owner_auth TPM owner password. Required.
# @!puppet.type.param lockout_auth TPM  lock out password. Required.
# @!puppet.type.param endorsement_auth TPM endorsement hierachy password. Required.
#
# @!puppet.type.param in_hex If true, indicates the passwords are in Hex.
#
# @!puppet.type.param local If true, the provider will drop the
#   passwords in a file in the puppet `$vardir`/simp/<tpmname>.
#
# @!puppet.type.param owned If true it will set the passwords on the TPM. Required
#
#
# @author SIMP Team <https://simp-project.com>
#
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:tpm2_ownership) do
  @doc = "A type to manage ownership of a TPM 2.0.

  Use this to set the passwords on a TPM to prevent unauthorized access.

  It can not change the passwords.

Example:

  include 'tpm'

  tpm2_ownership { 'tpm2':
    owner        =>  set,
    lockout      =>  set,
    endorsement  =>  set,
    owner_auth   => 'badpass',
    lockout_auth => 'badpass',
    endorsement_auth => 'badpass',
  }
"

  feature :take_ownership, "The ability to take ownership of a TPM"

  newparam(:name, :namevar => true) do
    desc 'A static name assigned to this type. You can only declare
          this type of resource once in your node scope'

    isnamevar

    defaultto 'tpm2'

    validate do |value|
      raise(ArgumentError,"Error: $name must be 'tpm2'.") unless value == 'tpm2'
    end

  end

  newparam(:owner_auth) do
    desc 'The owner password of the TPM'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "owner_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:lockout_auth) do
    desc "The lock out password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "lockout_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:endorsement_auth) do
    desc "The endorse password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "endorsement_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end


  newparam(:in_hex, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Whether or not the passwords are in hex"
    defaultto 'false'
  end

  newparam(:local, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Whether to save the passwords on the local system"
    defaultto 'false'
  end

  newproperty(:owner) do
    desc ' Seting for owner authorization'
    newvalues(:clear, :set)
  end

  newproperty(:endorsement) do
    desc ' Seting for owner authorization'
    newvalues(:clear, :set)
  end

  newproperty(:lockout) do
    desc ' Seting for owner authorization'
    newvalues(:clear, :set)
  end

  #Global Validation
   validate do

     [[:owner,:owner_auth],[:lockout,:lockout_auth],[:endorsement, :endorsement_auth]].each { |x,y|
       if self[x] ==  :set
         raise(Puppet::Error, "Password parameter, #{y}, must be provided when #{x} = 'set'") if self[y].empty?
       end
     }
   end

  autorequire(:package) do
    [ 'tpm2-tss','tpm2-tools' ]
  end
  autorequire(:service) do
    #To DO check if tcti = abrmd
    [ 'tpm2-abrmd' ]
  end

end
