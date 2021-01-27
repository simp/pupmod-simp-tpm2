# @summary Provides the ability to set or clear the authentication passwords for the TPM
#
# At this time you can clear a set password but cannot change it to another value.
#
# This class works when tpm2-tools version 4.0.0 or later is installed.
# You can call this directly but it will not check the version of tpm2-tools
# installed.  It will do nothing if the incorrect version is  installed.
#
# If you don't know what version of tpm2-tools will be installed then
# set tpm2::take_ownership to true in hiera. See the Readme for more information.
# Using tpm2::takeownership will require 2 puppet runs but will allow you to configure
# multiple machines with different tpm2-tools packages.
#
# @param owner
#   The desired state of the owner authentication.
#   Valid setting are set, clear and ignore.
#
# @param endorsement
#   The desired state of the endorsement authentication.
#   Valid setting are set, clear and ignore.
#
# @param lockout
#   The desired state of the lockout authentication.
#   Valid setting are set, clear and ignore.
#
# @param owner_auth
#   The password word for owner authentication.
#
# @param lockout_auth
#   The password word for lockout authentication.
#
# @param endorsement_auth
#   The password word for endorsement authentication.
#
# @example
#
# See the tpm2::ownership class for examples on setting it up from there.
#
# To call directly:
#  In your manifest:
#    include tpm2::ownership::changeauth
#  In Hiera:
#    tpm2::take_ownership: false
#    tpm2::ownership::changeauth::owner: 'set'
#
# The passwords will default to automatically generated passwords using simplib::passgen.  If
# you want to set them to specific passwords then set them in hiera using the
# following settings (it expects a minumum password length of 14 charaters):
#
#   tpm2::ownership::changeauth::owner_auth: 'MyOwnerPassword'
#   tpm2::ownership::changeauth::lockout_auth:  'MyLockPassword'
#   tpm2::ownership::changeauth::endorsement_auth: 'MyEndorsePassword'
#
#  See the man page for tpm2_changeauth for more information.  Note: not all of the command
#  options are currently available through the type.
#
# @author SIMP Team https://simp-project.com
#
class tpm2::ownership::changeauth(
  Enum['set','clear','ignore']   $owner              = 'ignore',
  Enum['set','clear','ignore']   $endorsement        = 'ignore',
  Enum['set','clear','ignore']   $lockout            = 'ignore',
  String[14]                     $owner_auth         = simplib::passgen("${facts['fqdn']}_tpm_owner_auth", {'length'=> 24}),
  String[14]                     $lockout_auth       = simplib::passgen("${facts['fqdn']}_tpm_lock_auth", {'length'=> 24}),
  String[14]                     $endorsement_auth   = simplib::passgen("${facts['fqdn']}_tpm_endorse_auth", {'length'=> 24}),
){


# tpm2-tools version >= 4.0.0
  unless $owner == 'ignore' {
    tpm2_changeauth { 'owner':
      auth    => $owner_auth,
      state   => $owner,
      require => Class['tpm2::service']
    }
  }
  unless $lockout == 'ignore' {
    tpm2_changeauth { 'lockout':
      auth    => $lockout_auth,
      state   => $lockout,
      require => Class['tpm2::service']
    }
  }
  unless $endorsement == 'ignore' {
    tpm2_changeauth { 'endorsement':
      auth    => $endorsement_auth ,
      state   => $endorsement,
      require => Class['tpm2::service']
    }
  }
}
