module Tpm2TestUtil
  # This is a helper to get the status of the TPM so it can be compared against the
  # the expected results.
  def get_tpm2_status(host)
    require 'yaml'
    stdout = on(host, 'facter -p -y tpm2 --strict').stdout
    fact = YAML.safe_load(stdout)['tpm2']
    tpm2_status = fact['tpm2_getcap']['properties-variable']['TPM_PT_PERSISTENT']
    [tpm2_status['ownerAuthSet'],tpm2_status['endorsementAuthSet'],tpm2_status['lockoutAuthSet']]
  end
end
