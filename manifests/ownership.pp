class tpm2::ownership(
  String[14]                $owner_auth   = passgen("${facts['fqdn']}_tpm_owner_auth", {'length'=> 24}),
  String[14]                $lock_auth    = passgen("${facts['fqdn']}_tpm_lock_auth", {'length'=> 24}),
  String[14]                $endorse_auth = passgen("${facts['fqdn']}_tpm_endorse_auth", {'length'=> 24}),
  Optional[Tpm2::Ownership]       $allauth,
  Optional[Tpm2::Ownership]       $owner,
  Optional[Tpm2::Ownership]       $endorsement,
  Optional[Tpm2::Ownership]       $lock,
  Boolean $in_hex       = false,
  Enum['abrmd','socket','device']  $tcti  = 'abrmd'
){

  if ! ($allauth or $owner or $endorsement or $lock ) {
    fail('You must supply one of the following parameters: allauth, owner, endorsement, lock')
  }

  if $allauth {
    $setting_att =  {
      "allauth" => $allauth,
    }
  } else {
    $setting_att  = {
      'owner'       => $owner,
      'endorsement' => $endorsement,
      'lock'        => $lock,
    }
  }

  tpm2_ownership { 'tpm2':
    *                => $settings_att,
    owner_auth       => $owner_auth,
    endorsement_auth => $endorsement_auth,
    lock_auth        => $lock_auth,
    in_hex           => $in_hex,
    tcti             => $tcti
  }

}




