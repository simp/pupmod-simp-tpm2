# The tpm_ownership type allows you to take ownership of tpm0.
#
# @!puppet.type.param owner_auth TPM owner password. Required.
# @!puppet.type.param lockout_auth TPM  lock out password. Required.
# @!puppet.type.param endorsement_auth TPM endorsement hierarchy password. Required.
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

Puppet::Type.newtype(:tpm2_changeauth) do
  @doc = "A type to manage ownership of a TPM 2.0.

  Use this to set the passwords on a TPM to prevent unauthorized access.

  It cannot change the passwords but it can clear the password

Example:

  include 'tpm'

  tpm2_changeauth { 'owner':
    auth       =>  'badpasswd,
    state      =>  'set'
  }
"

  feature :take_ownership, "The ability to take ownership of a TPM"

  newparam(:name, :namevar => true) do
    desc 'The value of the context object to change the authorization on.  Currently only handles  owner, lockout, or  endorsement'

    isnamevar

    defaultto 'owner'

    validate do |value|
      raise(ArgumentError,"Error: $name must be one of 'owner', 'lockout', 'endorsement'.") unless ['owner', 'lockout', 'endorsement'].include?(value)
    end

  end

  newparam(:auth) do
    desc 'The password for the type'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "auth must be a String, not '#{value.class}'")
      end
    end
    defaultto ''
  end

  newproperty(:state) do
    desc "Whether to set the password or clear the current password. It can not change a password at this time.
          You must know the current password to clear the password"
    newvalues(:clear, :set)
  end

  autorequire(:package) do
    [ 'tpm2-tss','tpm2-tools' ]
  end
  autorequire(:service) do
    #To DO check if tcti = abrmd
    [ 'tpm2-abrmd' ]
  end

end
