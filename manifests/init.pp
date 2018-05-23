# Provides utilities for interacting with a TPM2 device
#
### @param ima Toggles IMA on or off.
###
### @param take_ownership Enable to allow Puppet to take ownership
###   of the TPM.
###
### @param tpm_name The name of the device (usually tpm0).
###
### @param tpm_version Override for the tpm_version fact.
###
### @param package_ensure The ensure status of packages to be installed
#
# @author SIMP Team https://simp-project.com
#
class tpm2 (
  Boolean       $manage_tpm2_tools = true,
  String        $package_ensure    = simplib::lookup('simp_options::package_ensure', {'default_value' => 'installed'}),
  Array[String] $package_names     = simplib::lookup('tpm2::package_names'),
  String        $tabrm_service     = simplib::lookup('tpm2::tabrm_service'),
  ###  Boolean                $take_ownership = false,
  ###  String                 $tpm_name       = 'tpm0',
  ###  Optional[Tpm::Version] $tpm_version    = pick($facts['tpm_version'], 'unknown'),
  ###  String                 $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value'       => 'installed' })
){
  simplib::assert_metadata( $module_name )

  include '::tpm2::install'
  include '::tpm2::config'
  Class[ '::tpm2::install' ] -> Class[ '::tpm2::config' ]

  if $manage_tpm2_tools {
    include '::tpm2::service'
    Class[ '::tpm2::config' ] ~> Class[ '::tpm2::service' ]
  }
}
