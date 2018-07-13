# A private class to ensure that firewall rules are defined.
class tpm2::config::firewall {
  assert_private()

  # FIXME: ensure your module's firewall settings are defined here.
  iptables::listen::tcp_stateful { 'allow_tpm2_tcp_connections':
    trusted_nets => $::tpm2::trusted_nets,
    dports       => $::tpm2::tcp_listen_port
  }
}
