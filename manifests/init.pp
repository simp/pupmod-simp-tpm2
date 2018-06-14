# Provides utilities for interacting with a TPM2 device
#
# @param manage_tpm2_tools The module will manage the tpm2-tools packages unless `false`
#
# @param package_ensure  The default ensure parmeter for packages.
#
# @param packages A Hash of packages needed for tpm2-tools
#
# @param take_ownership Enable to allow Puppet to take ownership
#   of the TPM.
#
# @param tabrm_service Systemd name of the abrmd-service
#
# @author SIMP Team https://simp-project.com
#
class tpm2 (
  Boolean       $manage_tpm2_tools = true,
  String        $package_ensure    = simplib::lookup('simp_options::package_ensure', {'default_value' => 'installed'}),
  Hash[String,Hash[String,String]]  $packages  = simplib::lookup('tpm2::packages'),
  String        $tabrm_service     = simplib::lookup('tpm2::tabrm_service'),
  ###  Boolean                $take_ownership = false,
){
  simplib::assert_metadata( $module_name )

  # do not attempt to install tpm2-tools, etc on a system that is known to have
  # a TPM 1.2 device.
  if defined('$facts["tpm_version"]') and $facts['tpm_version' == 'tpm1'] {
    notify{ "NOTICE: Skipping resources from module '${module_name}': \$tpm_version == 'tpm1'": }
  } else {
    include '::tpm2::install'
    include '::tpm2::config'
    Class[ '::tpm2::install' ] -> Class[ '::tpm2::config' ]

    if $manage_tpm2_tools {
      include '::tpm2::service'
      Class[ '::tpm2::config' ] ~> Class[ '::tpm2::service' ]
    }
  }
}
