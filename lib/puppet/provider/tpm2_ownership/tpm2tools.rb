Puppet::Type.type(:tpm2_ownership).provide(:tpm2tools) do
  desc 'tpm2tools providers uses the TCG software stack
    and commands provided by tpm2-tools rpm to set the
    authentication tokens for the tpm if it is a version 2
    tpm.

    @author SIMP Team https://simp-project.com'

  has_feature :take_ownership

  mk_resource_methods
  defaultfor :kernel => :Linux

  commands :tpm2_takeownership => 'tpm2_takeownership'
  commands :tpm2_getcap        => 'tpm2_getcap'

  def initialize(value={})
    super(value)
    @property_flush = {}
  end


  # Generate standard args for connecting to the TPM.  These arguements
  # are common for most TPM2 commands.
  #
  # @return [String] Return a string of the tcti and the
  # hex option if it is set.
  def get_extra_args()
    options = []

    debug('tpm2_takeownership setting tcti args.')
    case resource[:tcti]
    when :devicefile
      options << ["--tcti", "device","-d", "#{resource[:devicefile]}"]
    when :socket
      options << ["--tcti", "socket", "-R", "#{resource[:socket_address]}", "-p", "#{resource[:socket_port]}"]
    else
      options << ["--tcti", "abrmd"]
    end

    options << ["-X"] if resource[:in_hex]

    options
  end

  def get_passwd_options(current, desired)
    @to_opts    = {:owner       => {:passwd => resource[:owner_auth],
                                    :opt => 'o'},
                   :endorsement => {:passwd => resource[:endorse_auth],
                                    :opt => 'e'},
                   :lock        => {:passwd => resource[:lock_auth],
                                    :opt => 'l'}
                  }
    @to_opts.map { |k, v| passwd_options(current[k], desired[k], v) }
  end


  def passwd_options(current, desired, value)
    options = []
    case current
    when :set
      fail("The current state is set and password is not provided.  The password must be provided even if a change is not required") if value[:passwd].empty?
      options << [ "-#{value[:opt]}".upcase, value[:passwd]]
      # If the auth is set and we don't want to clear it then you have to give it the password
      #  to set the password or the command will fail.
      if desired.nil? || desired == :set 

        options <<  ["-#{value[:opt]}", value[:passwd]]
      end
    when :clear
      if desired == :set
        options << [ "-#{value[:opt]}", value[:passwd]]
      end
    else
      return
    end
    options.flatten
  end

  def take_ownership(current, desired)

    begin
      tpm2_takeownership(get_extra_args,get_passwd_options(current,desired))
      return
    rescue Puppet::ExecutionFailure => e
      warn("tpm2_takeownership failed with error -> #{e.inspect}")
      return e
    end
  end

  def clear_ownership(current)
    options << "-c"
    # Check if lockAuth is set and pass in the password to the
    # options if it is.
    if current[:lock] == :set
      return "Cannot clear the authorization on tpm.  Lock auth is set but no password was supplied" if resource[:lock_auth].nil?
      options << ["-L","#{resource[:lock_auth]}"]
    end
    begin
      tpm2_takeownership(get_extra_args, options)
      return
    rescue Puppet::ExecutionFailure => e
      warn("tpm2_takeownership failed with error -> #{e.inspect}")
      return e
    end
  end

  def status(x)
    @current_status || @current_status = get_status
    @current_status[x]
  end

  # Check and see if the data file exists for the tpm.  In version 2 you can
  # use tpm2_dump_capability to check what passwords are set.
  def get_tpm_status
    begin
      yaml = tpm2_getcap(get_extra_args, '-c', 'properties-variable')
      properties_variable = YAML.safe_load(yaml)
    rescue
      fail("Failed to retrieve data from tpm2_getcap ")
    end

    unless properties_variable.instance_of?(Hash) && properties_variable.has_key?('TPM_PT_PERSISTENT')
      fail("tpm2_getcap did not return 'TPM_PT_PERSISTENT' data.")
    end

    status = Hash.new

    properties_variable['TPM_PT_PERSISTENT'].each { |k,v|
      case k
      when 'ownerAuthSet'
         status[:owner] = v.to_sym
      when 'endorsementAuthSet'
        status[:endorsement] = v.to_sym
      when 'lockoutAuthSet'
         status[:lock] = v.to_sym
      else
          status[k] = v.to_sym
      end
    }
    status
  end

  def owner
    status(:owner)
  end

  def lock
    status(:lock)
  end

  def endorsement
    status(:endorsement)
  end

  def owner=(should)
    debug 'tpm2: Setting  owner property_flush to should'
    @property_flush[:owner] = should
  end

  def endorsement=(should)
    debug 'tpm2: Setting endorsement property_flush to should'
    @property_flush[:endorsement] = should
  end

  def lock=(should)
    debug 'tpm2: Setting lock property_flush to should'
    @property_flush[:lock] = should
  end

  def flush
    current = @current_status
    desired = @property_flush
    debug 'tpm2: Flushing tpm2_ownership'
    # Check if there is something to do and while you are at it check if they
    # are all set to clear.
    @something_to_do = false
    @clear_all = true
    desired.keys.each { |x|
      desired[x] == current[x] || @something_to_do = true
      desired[x] == :clear || @clear_all = false
    }
    if @something_to_do
      if @clear_all
        output = clear_ownership(current)
        unless output.nil?
          fail Puppet::Error,"Could not take ownership of the tpm. Error from tpm2_takeownership is #{output}"
        end
      else
        # Set the desired state for each auth value
        output = take_ownership(current, desired)
        unless output.nil?
           fail Puppet::Error,"Could not take ownership of the tpm. Error from tpm2_takeownership is #{output}"
        end
      end
    end
    @property_hash = resource.to_hash

  end

end
