# A private class to ensure that the TABRM service is running
class tpm2::service {
  assert_private()
  service{ $tpm2::tabrm_service:
    ensure => running,
    enable =>  true,
  }
}
