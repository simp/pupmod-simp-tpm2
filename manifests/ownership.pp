class tpm2::ownership(
  Enum['set','clear']            $owner               = 'set',
  Enum['set','clear']            $endorsement         = 'set',
  Enum['set','clear']            $lock                = 'set',
  String[14]                     $owner_auth          = passgen("${facts['fqdn']}_tpm_owner_auth", {'length'=> 24}),
  String[14]                     $lock_auth           = passgen("${facts['fqdn']}_tpm_lock_auth", {'length'=> 24}),
  String[14]                     $endorse_auth        = passgen("${facts['fqdn']}_tpm_endorse_auth", {'length'=> 24}),
  Boolean                        $in_hex              = false,
){


  tpm2_ownership { 'tpm2':
    owner        => $owner,
    lock         => $lock,
    endorsement  => $endorsement,
    owner_auth   => $owner_auth,
    endorse_auth => $endorse_auth,
    lock_auth    => $lock_auth,
    in_hex       => $in_hex,
    require      => Service["${::tpm2::tabrm_service}"]
  }

}




