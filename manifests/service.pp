# @summary A private class to ensure that the TABRM service is running
class tpm2::service {
  assert_private()


  if $tpm2::tabrm_options {
    $_cmd_opts = join($tpm2::tabrm_options, ' ')
    $_override = @("OVERRIDE")
      # This file managed by Puppet
      [Service]
      ExecStart=
      ExecStart=/usr/sbin/${tpm2::tabrm_service} ${_cmd_opts}
      | OVERRIDE

    systemd::dropin_file { 'tabrm_service.conf':
      unit    => "${tpm2::tabrm_service}.service",
      content => $_override,
      notify  => Service["#{$tpm2::tabrm_service}"]
    }
  }

  service{ $tpm2::tabrm_service:
    ensure => running,
    enable =>  true,
  }
}
