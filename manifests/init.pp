# Full description of SIMP module 'tpm2' here.
#
# === Welcome to SIMP!
#
# This module is a component of the System Integrity Management Platform, a
# managed security compliance framework built on Puppet.
#
# ---
# *FIXME:* verify that the following paragraph fits this module's characteristics!
# ---
#
# This module is optimally designed for use within a larger SIMP ecosystem, but
# it can be used independently:
#
# * When included within the SIMP ecosystem, security compliance settings will
#   be managed from the Puppet server.
#
# * If used independently, all SIMP-managed security subsystems are disabled by
#   default, and must be explicitly opted into by administrators.  Please
#   review the +trusted_nets+ and +$enable_*+ parameters for details.
#
# @param service_name
#   The name of the tpm2 service
#
# @param package_name
#   The name of the tpm2 package
#
# @param trusted_nets
#   A whitelist of subnets (in CIDR notation) permitted access
#
# @param enable_auditing
#   If true, manage auditing for tpm2
#
# @param enable_firewall
#   If true, manage firewall rules to acommodate tpm2
#
# @param enable_logging
#   If true, manage logging configuration for tpm2
#
# @param enable_pki
#   If true, manage PKI/PKE configuration for tpm2
#
# @param enable_selinux
#   If true, manage selinux to permit tpm2
#
# @param enable_tcpwrappers
#   If true, manage TCP wrappers configuration for tpm2
#
# @author simp
#
class tpm2 (
  String                        $service_name       = 'tpm2',
  String                        $package_name       = 'tpm2',
  Simplib::Port                 $tcp_listen_port    = 9999,
  Simplib::Netlist              $trusted_nets       = simplib::lookup('simp_options::trusted_nets', {'default_value' => ['127.0.0.1/32'] }),
  Variant[Boolean,Enum['simp']] $enable_pki         = simplib::lookup('simp_options::pki', { 'default_value'         => false }),
  Boolean                       $enable_auditing    = simplib::lookup('simp_options::auditd', { 'default_value'      => false }),
  Variant[Boolean,Enum['simp']] $enable_firewall    = simplib::lookup('simp_options::firewall', { 'default_value'    => false }),
  Boolean                       $enable_logging     = simplib::lookup('simp_options::syslog', { 'default_value'      => false }),
  Boolean                       $enable_selinux     = simplib::lookup('simp_options::selinux', { 'default_value'     => false }),
  Boolean                       $enable_tcpwrappers = simplib::lookup('simp_options::tcpwrappers', { 'default_value' => false })
) {

  $oses = load_module_metadata( $module_name )['operatingsystem_support'].map |$i| { $i['operatingsystem'] }
  unless $::operatingsystem in $oses { fail("${::operatingsystem} not supported") }

  include '::tpm2::install'
  include '::tpm2::config'
  include '::tpm2::service'

  Class[ '::tpm2::install' ]
  -> Class[ '::tpm2::config' ]
  ~> Class[ '::tpm2::service' ]

  if $enable_pki {
    include '::tpm2::config::pki'
    Class[ '::tpm2::config::pki' ]
    -> Class[ '::tpm2::service' ]
  }

  if $enable_auditing {
    include '::tpm2::config::auditing'
    Class[ '::tpm2::config::auditing' ]
    -> Class[ '::tpm2::service' ]
  }

  if $enable_firewall {
    include '::tpm2::config::firewall'
    Class[ '::tpm2::config::firewall' ]
    -> Class[ '::tpm2::service' ]
  }

  if $enable_logging {
    include '::tpm2::config::logging'
    Class[ '::tpm2::config::logging' ]
    -> Class[ '::tpm2::service' ]
  }

  if $enable_selinux {
    include '::tpm2::config::selinux'
    Class[ '::tpm2::config::selinux' ]
    -> Class[ '::tpm2::service' ]
  }

  if $enable_tcpwrappers {
    include '::tpm2::config::tcpwrappers'
    Class[ '::tpm2::config::tcpwrappers' ]
    -> Class[ '::tpm2::service' ]
  }
}
