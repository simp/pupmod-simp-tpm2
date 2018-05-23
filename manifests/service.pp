# == Class tpm2::service
#
# This class is meant to be called from tpm2.
# It ensures that the TABRM service is running.
#
class tpm2::service {
  assert_private()
  service{ $tpm2::tabrm_service:
    ensure => running,
    enable =>  true,
  }
}
