#  @summary Install tpm2 packages
class tpm2::install {
  assert_private()

  $tpm2::packages.each | $pkg_name, $parameters | {
    $_ensure = defined('$parameters["ensure"]') ? {
      true    => regsubst($parameters["ensure"], '^package_ensure$', $tpm2::package_ensure ) ,
      default => $tpm2::package_ensure,
    }

    package { $pkg_name:
      ensure => $_ensure,
    }
  }
}
