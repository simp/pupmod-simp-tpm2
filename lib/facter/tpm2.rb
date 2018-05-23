# A strucured fact that return some facts about a TPM 2.0 TPM
#
# The fact will be nil if the tpm2-tools are either not available, or aren't
# configured to comminucate with the TPM
Facter.add('tpm2') do

  #### The confine below is intentionally unused.
  ####
  #### The `:has_tpm` detection strategy used for TPM 1 is unreliable for TPM
  #### 2.0: TCTI can be configured to talk over network sockets, so the
  #### TPM device the system is using may not be local.
  ####
  #### This makes it impossible to conclusively detect whether a system has TPM2.0
  #### capabilities unless the tpm2-tools software is installed and properly
  #### configured.
  ####
  #### Therefore, the :has_tpm fact is *not* used to confine TPM 2.0 facts, and
  #### the :tpm2 fact returns information if it is available
  ####
  ### confine :has_tpm => true

  # Don't check for TPM 2 data if the host is *known* to have a TPM 1 device.
  #
  # Note: The block is anonymous because this check will be true it `:tpm_version` is Facter doesn't execute confine blocks for
  # absent facts.

  confine do
     value = Facter[:tpm_version]
     Facter.debug 'tpm2 confine'
     value.nil? || value != 'tpm1'
   end

  setcode do
    Facter.debug 'tpm2 setcode'
    require 'facter/tpm2/util'
    Facter::TPM2::Util.new.build_structured_fact
  end
end

