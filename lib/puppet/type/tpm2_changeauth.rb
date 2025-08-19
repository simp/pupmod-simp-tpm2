# The tpm_changeuth type allows you to set the authentication token
# for the owner, lockout and endorsement context on tpm2.
#
# It can not change a password that is set.
#
# See tpm2_changeauth --help for information on valid password values.
#
# @author SIMP Team <https://simp-project.com>
#
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:tpm2_changeauth) do
  @doc = "A type to manage ownership of a TPM 2.0.

  The context must be the name of the resource.  It only accepts
  'owner', 'lockout' and 'endorsement' at this time.

  Use this to set the passwords on a TPM to prevent unauthorized access.

  It cannot change the passwords but it can clear the password

Example:

  include 'tpm'

  tpm2_changeauth { 'owner':
    auth       =>  'badpasswd,
    state      =>  'set'
  }
"

  feature :take_ownership, 'The ability to take ownership of a TPM'

  newparam(:name, namevar: true) do
    desc 'The value of the context object to change the authorization on.  Currently only handles  owner, lockout, or  endorsement'

    isnamevar

    defaultto 'owner'

    validate do |value|
      raise(ArgumentError, "Error: $name must be one of 'owner', 'lockout', 'endorsement'.") unless ['owner', 'lockout', 'endorsement'].include?(value)
    end
  end

  newparam(:auth) do
    desc 'The authentication value for the context'
    validate do |value|
      unless value.is_a?(String)
        raise(Puppet::Error, "auth must be a String, not '#{value.class}'")
      end
      if value.empty?
        raise(Puppet::Error, 'auth must not be empty.')
      end
    end
  end

  newproperty(:state) do
    desc "Whether to set the password or clear the current password. It can not change a password at this time.
          You must know the current password to clear the password"
    newvalues(:clear, :set)
  end

  autorequire(:package) do
    [ 'tpm2-tss', 'tpm2-tools' ]
  end
  autorequire(:service) do
    # To DO check if tcti = abrmd
    [ 'tpm2-abrmd' ]
  end
end
