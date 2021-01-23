# @summary Provides the ability to set or clear the authentication passwords for the TPM
#
# At this time you can clear a set password but cannot change it to another value.
#
# This class works when tpm2-tools version 4.0.0 or later is installed.
# You can call this directly but it will nto check the version of tpm2-tools
# installed.  It will do nothing if the incorrect version is  installed.
#
# If you don't know what version of tpm2-tools will be installed then
# set tpm2::take_ownership to true in hiera.
# Using tpm2::takeownership will require 2 puppet runs but will allow you to configure
# multiple machines with different tpm2-tools packages.
#
# You also need to set the parameters in hiera to override the defaults.
#
# @param owner
#   The desired state of the owner authentication.
#   If tpm2-tools < 4.0.0 is installed you can not use the
#   'ignore' option.  It attempts to set all 3.
#   Puppet will display a warning and not attempt to set
#   auth value if it is used and the earlier version of
#   tpm tools is set.
#
# @param endorsement
#   The desired state of the endorsement authentication.
#   See owner param for more information.
#
# @param lockout
#   The desired state of the lockout authentication.
#   See owner param for more information.
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
# @param in_hex
#   Whether or not the passwords are in Hex.
#   This value is ignore if tpm2_tools package > 4.0.0
#   is installed.
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
      unless $endorement == 'ignore' {
        tpm2_changeauth { 'endorsement':
          auth    => $endorement_auth ,
          state   => $endorement,
          require => Class['tpm2::service']
        }
      }
    }
  }

}
