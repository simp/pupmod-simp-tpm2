Puppet::Type.type(:tpm2_ownership).provide(:tpm2tools) do
  desc 'tpm2tools providers uses the TCG software stack
    and commands provided by tpm2-tools rpm to set the
    authentication tokens for the tpm if it is a version 2
    tpm.

    @author SIMP Team https://simp-project.com'

  has_feature :take_ownership

  defaultfor :kernel => :Linux

  commands :tpm2_takeownership => 'tpm2_takeownership'

  def initialize(value={})
    super(value)
    @property_flush = {}
    @property_current = {}
  end


  def get_passwd_options(current, desired)
    to_opts    = {:owner       => {:passwd => resource[:owner_auth],
                                    :opt => 'o'},
                   :endorsement => {:passwd => resource[:endorse_auth],
                                    :opt => 'e'},
                   :lock        => {:passwd => resource[:lock_auth],
                                    :opt => 'l'}
                  }
   options =  to_opts.map { |k, v| passwd_options(current[k], desired[k], v) }
   options << "-X" if resource[:in_hex]

   options.flatten

  end

  def passwd_options(current, desired, value)
    options = []
    case current
    when :set
      fail("The current state is set and password is not provided.  The password must be provided even if a change is not required") if value[:passwd].empty?
      # If the current state is set then you need to pass the password in with upper case option.
      options << [ "-#{value[:opt]}".upcase, value[:passwd]]
      # If the auth is set and we don't want to clear it then you have to give it the password
      #  to set the password or it will clear the password.
      if desired.nil? || desired == :set

        options <<  ["-#{value[:opt]}", value[:passwd]]
      end
    when :clear
      if desired == :set
        options << [ "-#{value[:opt]}", value[:passwd]]
      end
    end
    options.flatten
  end

  def take_ownership(current, desired)
    params = get_passwd_options(current,desired)
    debug "calling tpm2_takeownership with parameters: #{params}"
    begin
      tpm2_takeownership(params)
      return
    rescue Puppet::ExecutionFailure => e
      warn("tpm2_takeownership failed with error -> #{e.inspect}")
      return e
    end
  end

  # Check and see if the data file exists for the tpm.  In version 2 you can
  # use tpm2_dump_capability to check what passwords are set.

  def owner
    value = Facter.value(:tpm2)['tpm2_getcap']['properties-variable']['TPM_PT_PERSISTENT']['ownerAuthSet']
    if value.nil?
      @property_current[:owner] = :unknown
    else
      @property_current[:owner] = value.to_sym
    end
    @property_current[:owner]
  end

  def lock
    value = Facter.value(:tpm2)['tpm2_getcap']['properties-variable']['TPM_PT_PERSISTENT']['lockoutAuthSet']
    if value.nil?
      @property_current[:lock] = :unknown
    else
      @property_current[:lock] = value.to_sym
    end
    @property_current[:lock]
  end

  def endorsement
    value = Facter.value(:tpm2)['tpm2_getcap']['properties-variable']['TPM_PT_PERSISTENT']['endorsementAuthSet']
    if value.nil?
      @property_current[:endorsement] = :unknown
    else
      @property_current[:endorsement] = value.to_sym
    end
    @property_current[:endorsement]
  end

  def owner=(should)
    @property_flush[:owner] = should
  end

  def endorsement=(should)
    @property_flush[:endorsement] = should
  end

  def lock=(should)
    @property_flush[:lock] = should
  end

  def flush
    #verify that the current state is known.  If not we don't want to try
    #tpm2_takeownership because you could lockout the TPM.
    [ :owner, :lock, :endorsement ].each  { |x|
      if @property_current[x] == :unknown
        Puppet.warning("The status of the tpm authorization values are unknown.  Puppet will not attempt to change ownership.")
        return
      end
      # The setter will only set a value for @property_flush if it is changing.
      @property_flush[x] = resource[x]
    }
    debug "Starting to process take_ownership with current state: #{@property_current} and desired state: #{@property_flush}"
    output = take_ownership(@property_current, @property_flush)
    unless output.nil?
      fail Puppet::Error,"Could not take ownership of the tpm. Error from tpm2_takeownership is #{output}"
    end
    @property_hash = resource.to_hash

  end

end
