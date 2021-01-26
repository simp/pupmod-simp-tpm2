# @summary Provides the ability to set or clear the authentication passwords for the TPM
#
# At this time you can clear a set password but cannot change it to another value.
#
# You can call this module directly or set tpm2::take_ownership to true in hiera.
# Using tpm2::takeownership will require 2 puppet runs but will allow you to configure
# multiple machines with different tpm2-tools packages.
#
# You also need to set the parameters in hiera to override the defaults.
#
# @param owner
#   The desired state of the owner authentication.
#
# @param endorsement
#   The desired state of the endorsement authentication.
#
# @param lockout
#   The desired state of the lockout authentication.
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
#  See the Readme.md on how to use this class through the tpm2:ownership class. It can determine the version
#  of tpm2_tools installed and call the correct class.  If you are sure you are using tpm2_tools
#  you can call this module directly.
#
#  Also see the man page for tpm2_takeownership for further information.
#  Ih hiera:
#
#    # Set tpm2::take_ownership to false to make sure a duplicate resource is not created.
#    tpm2::take_ownership: false
#    # all three values must be set to the desired state.
#    tpm2::ownership::takeownership::owner: set
#    tpm2::ownership::takeownership::lockout:  clear
#    tpm2::ownership::takeownership::endorsement: set
#
# The passwords will default to automatically generated passwords using simplib::passgen.  If
# you want to set them to specific passwords then set them in hiera using the
# following settings (it expects a minumum password length of 14 charaters):
#
#   # If you want to clear a password you must know the current password.
#   tpm2::ownership::takeownership::owner_auth: 'MyOwnerPassword'
#   tpm2::ownership::takeownership::lockout_auth:  'MyLockPassword'
#   tpm2::ownership::takeownership::endorsement_auth: 'MyEndorsePassword'
#
# @author SIMP Team https://simp-project.com
#
class tpm2::ownership::takeownership(
  Enum['set','clear']   $owner              = 'clear',
  Enum['set','clear']   $endorsement        = 'clear',
  Enum['set','clear']   $lockout            = 'clear',
  String[14]            $owner_auth         = simplib::passgen("${facts['fqdn']}_tpm_owner_auth", {'length'=> 24}),
  String[14]            $lockout_auth       = simplib::passgen("${facts['fqdn']}_tpm_lock_auth", {'length'=> 24}),
  String[14]            $endorsement_auth   = simplib::passgen("${facts['fqdn']}_tpm_endorse_auth", {'length'=> 24}),
  Boolean               $in_hex             = false
){

  tpm2_ownership { 'tpm2':
    owner            => $owner,
    lockout          => $lockout,
    endorsement      => $endorsement,
    owner_auth       => $owner_auth,
    endorsement_auth => $endorsement_auth,
    lockout_auth     => $lockout_auth,
    in_hex           => $in_hex,
    require          => Class['tpm2::service']
  }

}
