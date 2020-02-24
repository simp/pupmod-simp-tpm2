# @summary Provides utilities for interacting with a TPM2 device
#
# @param manage_tpm2_tools
#   The module will manage the tpm2-tools packages unless `false`
#
# @param package_ensure
#   The default ensure parmeter for packages.
#
# @param packages
#   A Hash of packages needed for tpm2-tools.  The Hash format is:
#
#   ```yaml
#   <package_name>':
#     ensure: <ensure_value>
#   ```
#
# @param take_ownership
#   Enable to allow Puppet to take ownership of the TPM
#
# @param tabrm_service
#   Systemd name of the abrmd-service
#
# @param tabrm_options
#   An **unvalidated** list of options to pass to $tabrm_service at start time
#
# @author SIMP Team https://simp-project.com
#
class tpm2 (
  String[1]                                  $package_ensure    = simplib::lookup('simp_options::package_ensure', {'default_value' => 'installed'}),
  Hash[String[1], Hash[String[1],String[1]]] $packages          = simplib::lookup('tpm2::packages'),
  String[1]                                  $tabrm_service     = 'tpm2-abrmd',
  Optional[Array[String[1]]]                 $tabrm_options     = undef,
  Boolean                                    $take_ownership    = false,
){
  simplib::assert_metadata( $module_name )

  # There is no reason to install TPM2 resources on a host
  if defined('$facts["tpm_version"]') and $facts['tpm_version' == 'tpm1'] {
    notify { 'tpm2_with_tpm1':
      message => "NOTICE: Host has a tpm1 device; skipping TPM2 resources from module ${module_name}"
    }
  } else {
    include 'tpm2::install'
    include 'tpm2::service'
    Class[ 'tpm2::install' ] ~> Class[ 'tpm2::service' ]

    if $take_ownership {
      include 'tpm2::ownership'
    }
  }
}
