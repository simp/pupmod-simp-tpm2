# == Class tpm2::service
#
# This class is meant to be called from tpm2.
# It ensure the service is running.
#
class tpm2::service {
  assert_private()

  service { $::tpm2::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }
}
