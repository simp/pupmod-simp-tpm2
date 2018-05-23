# == Class tpm2::install
#
# This class is called from tpm2 for install.
#
class tpm2::install {
  assert_private()

  package { $::tpm2::package_name:
    ensure => present
  }
}
