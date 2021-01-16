# A structured fact that return some facts about a TPM 2.0 TPM
#
# The fact will be nil if the tpm2-tools are either not available, or aren't
# configured to communicate with the TPM
Facter.add( :tpm2 ) do
  confine { Facter::Core::Execution.which('tpm2_getcap') }

  setcode do
    Facter.debug 'tpm2 setcode'
    require 'facter/tpm2/util'
    Facter::TPM2::Util.new.build_structured_fact
  end
end

