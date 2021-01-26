Puppet::Type.type(:tpm2_changeauth).provide(:tpm2_changeauth) do
  desc 'tpm2_changeauth uses the TCG software stack
    and the tpm2_changeauth command provided by tpm2-tool
    package to set the authentication tokens for owner, lockout
    and endorsement contexts for the tpm if it is a version 2
    tpm. tpm2_changeauth is only provided in tpm2-tools
    version 4 or later. (Currently the version on tpm_tools
    installed is  retreived using tpm2_getcap -v)

    @author SIMP Team https://simp-project.com'

  has_feature :take_ownership

  defaultfor :kernel => :Linux

  commands :tpm2_changeauth => 'tpm2_changeauth'

  def initialize(value={})
    super(value)
  end

  def set_auth(context, desired, auth)
    options = []
    case context
    when 'owner'
      options << ['-c', 'o']
    when 'lockout'
      options << ['-c', 'l']
    when 'endorsement'
      options << ['-c', 'e']
    else
      Puppet.warning("The context #{context} for tpm2_changeauth is not a known value. Valid values are 'owner', 'lockout' and 'endorsement'.  Puppet will not attempt to change ownership.")
      return
    end

    case desired
    when :ignore
      return
    when :clear
      options << [ '-p', auth]
    when :set
      options << [ auth ]
    else
      Puppet.warning("The setting for the state for tpm2_changeauth is not a known value.  Puppet will not attempt to change ownership.")
      return
    end

    begin
      tpm2_changeauth(options.flatten)
      return
    rescue Puppet::ExecutionFailure => e
      warn("tpm2_takeownership failed with error -> #{e.inspect}")
      return e
    end
  end

  # Check and see if the data file exists for the tpm.  In version 2 you can
  # use tpm2_dump_capability to check what passwords are set.

  def state
    value = 'unknown'
    case resource[:name]
    when 'owner'
      value = Facter.value(:tpm2)['tpm2_getcap']['properties-variable']['TPM2_PT_PERSISTENT']['ownerAuthSet']
    when 'lockout'
      value = Facter.value(:tpm2)['tpm2_getcap']['properties-variable']['TPM2_PT_PERSISTENT']['lockoutAuthSet']
    when 'endorsement'
      value = Facter.value(:tpm2)['tpm2_getcap']['properties-variable']['TPM2_PT_PERSISTENT']['endorsementAuthSet']
    end
    case value
    when 0
      :clear
    when 1
      :set
    else
      :unknown
    end
  end

  def state=(value)
    set_auth( resource[:name], value, resource[:auth] )
  end

end
