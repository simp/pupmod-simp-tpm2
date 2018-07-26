# The tpm_ownership type allows you to take ownership of tpm0.
#
# @!puppet.type.param owner_auth TPM owner password. Required.
# @!puppet.type.param lock_auth TPM  lock out password. Required.
# @!puppet.type.param endorse_auth TPM endorsement hierachy password. Required.
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

  tpm2_ownership { 'tpm0':
    owner        =>  set,
    lock         =>  set,
    endorsement  =>  set,
    owner_auth   => 'badpass',
    lock_auth    => 'badpass',
    endorse_auth => 'badpass',
  }
"

  feature :take_ownership, "The ability to take ownership of a TPM"


  newparam(:owner_auth) do
    desc 'The owner password of the TPM'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "owner_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:lock_auth) do
    desc "The lock out password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "lock_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:endorse_auth) do
    desc "The endorse password of the TPM"
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "endorse_auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newparam(:name, :namevar => true) do
    desc 'The name of the resource has no impact.'
    defaultto 'tpm2'
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

  newproperty(:lock) do
    desc ' Seting for owner authorization'
    newvalues(:clear, :set)
  end


  #Global Validation
   validate do

     [[:owner,:owner_auth],[:lock,:lock_auth],[:endorsement, :endorse_auth]].each { |x,y|
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
