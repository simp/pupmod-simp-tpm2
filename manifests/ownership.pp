# @summary Provides the ability to set or clear the authentication passwords for the TPM
#
# At this time you can clear a set password but cannot change it another value.
#
# To use this module, set tpm2::take_ownership to true in hiera
# and set the parameters in hiera to override the defaults.
#
# @param owner
#   The desired state fo the owner authentication.
#
# @param endorsement
#   The desired state fo the endorsement authentication.
#
# @param lockout
#   The desired state fo the lockout authentication.
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
#
# @example
#
#  In Hiera set the following:
#    tpm2::take_ownership: true
#    tpm2::ownership::owner: set
#    tpm2::ownership::lockout:  clear
#    tpm2::ownership::endorsement: set
#
# The passwords will default to automatically generated passwords using passgen.  If
# you want to set them to specific passwords then set them in hiera using the
# following settings (it expects a minumum password length of 14 charaters):
#
#   tpm2::ownership::owner_auth: 'MyOwnerPassword'
#   tpm2::ownership::lockout_auth:  'MyLockPassword'
#   tpm2::ownership::endorsement_auth: 'MyEndorsePassword'
#
# @author SIMP Team https://simp-project.com
#
class tpm2::ownership(
  Enum['set','clear']            $owner              = 'clear',
  Enum['set','clear']            $endorsement        = 'clear',
  Enum['set','clear']            $lockout            = 'clear',
  String[14]                     $owner_auth         = simplib::passgen("${facts['fqdn']}_tpm_owner_auth", {'length'=> 24}),
  String[14]                     $lockout_auth       = simplib::passgen("${facts['fqdn']}_tpm_lock_auth", {'length'=> 24}),
  String[14]                     $endorsement_auth   = simplib::passgen("${facts['fqdn']}_tpm_endorse_auth", {'length'=> 24}),
  Boolean                        $in_hex             = false
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
