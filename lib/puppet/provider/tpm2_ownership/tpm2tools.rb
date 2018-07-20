Puppet::Type.type(:tpm2_ownership).provide(:tpm2tools) do
  desc 'tpm2tools providers uses the TCG software stack
    and commands provided by tpm2-tools rpm to set the
    authentication tokens for the tpm if it is a version 2
    tpm.

    @author SIMP Team https://simp-project.com'

  has_feature :take_ownership

  defaultfor :kernel => :Linux

  commands :tpm2_takeownership => 'tpm2_takeownership'
  commands :tpm2_getcap        => 'tpm2_getcap'

  def initialize(value={})
    super(value)
    @property_flush = {}
    @to_opts    = {:owner       => {:passwd => resource[:owner_auth],
                                    :opt => 'o'},
                   :endorsement => {:passwd => resource[:endorse_auth],
                                    :opt => 'e'},
                   :lock        => {:passwd => resource[:lock_auth],
                                    :opt => 'l'}
                  }
  end

  # Dump the owner password to a flat file
  #
  # @param [String] path where fact will be dumped
  def dump_pass(name, vardir)
    require 'json'

    pass_file = File.expand_path("#{vardir}/simp/#{name}/#{name}data.json")

    passwords = { "owner_auth"   => resource[:owner_auth],
                  "lock_auth"    => resource[:lock_auth],
                  "endorse_auth" => resource[:endorsement_auth]
                }
    # Check to make sure the SIMP directory in vardir exists, or create it
    if !File.directory?( File.dirname(pass_file) )
      FileUtils.mkdir_p( File.dirname(pass_file), :mode => 0750 )
      FileUtils.chown( 'root','root', File.dirname(pass_file) )
      FileUtils.chmod 0700, File.dirname(pass_file)
    end

    # Dump the password to pass_file
    file = File.new( pass_file, 'w', 0600 )
    file.write( passwords.to_json )
    file.close

  end

  # Generate standard args for connecting to the TPM.  These arguements
  # are common for most TPM2 commands.
  #
  # @return [String] Return a string of the tcti and the
  # hex option if it is set.
  def gen_extra_args()
    options = []

    debug('tpm2_takeownership setting tcti args.')
    case resource[:tcti]
    when :devicefile
      options << ["--tcti device","-d", "#{resource[:devicefile]}"]
    when :socket
      options << ["--tcti socket", "-R", "#{resource[:socket_address]}", "-p", "#{resource[:socket_port]}"]
    else
      options << ["--tcti abrmd"]
    end

    options << "-X" if resource[:in_hex]

    options
  end

  def get_passwd_options(current, desired, value)
    options = []
    case current
    when 'set'
      fail("The current state is set and password is not provided.  The password must be provided even if a change is not required") if value[:passwd].nil?
      options << [ "-#{value[:opt]}.uppercase", value[:opt] ]
      # If the auth is set and we don't want to clear it then you have to give it the password
      #  to set the password or the command will fail.
      if desired.nil? || desired == 'set'

        options << [ "-#{value[:opt]}", value[:opt] ]
      end
    when 'clear'
      if desired[value] == 'set'
        options << [ "-#{value[:opt]}", value[:opt] ]
      end
    else
      return
    end
    options
  end

  def take_ownership(current, desired)

    password_options = @to_opts.map { |k, v| get_passwd_options(current[k], desired[k], v) }
    begin
      tpm2_takeownership(get_extra_args,password_options)
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
    if current[:lock] == 'set'
      return "Cannot clear the authorization on tpm.  Lock auth is set but no password was supplied") if resource[:lock_auth].nil?
      options << ["-l","#{resource[:lock_auth]}"]
    end
    begin
      tpm2_takeownership(get_extra_args, options)
      return
    rescue Puppet::ExecutionFailure => e
      warn("tpm2_takeownership failed with error -> #{e.inspect}")
      return e
    end
  end

  # Check and see if the data file exists for the tpm.  In version 2 you can
  # use tpm2_dump_capability to check what passwords are set.
  def get_tpm_status
    begin
      yaml = tpm2_getcap(get_extra_args, -c, 'properties-variable')
    rescue Puppet::ExecutionFailure => e
      fail("tpm2_getcap failed with error -> #{e.inspect}")
      return e
    end
    properties_variable = YAML.safe_load(yaml)

    unless properties_variable.has_key?('TPM_PT_PERSISTENT')
      fail("tpm2_takeownership: tpm2_getcap did not return 'TPM_PT_PERSISTENT' data.")
    end

    status = Hash.new

    properties_variable['TPM_PT_PERSISTENT'].each { |k,v|
      case k
      when 'ownerAuthSet'
         status[:owner] = v
      when 'endorsementAuthSet'
        status[:endorsement] = v
      when 'lockoutAuthSet'
         status[:lock] = v
      else
          status[k] = v
      end
    }
    status
  end

  def allauth=(should)
    debug 'tpm2: Setting allauth property_flush to should'
    @property_flush[:allauth] = should
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
    current = get_tpm_status
    debug 'tpm2: Flushing tpm2_ownership'
    # If they asked to clear the settings check if
    # any of them are set
    if @property_flush[:allauth] == :clear
      cleared = true
      @to_opt.keys.each { |x| if status[x] == 'set' cleared = false }
      unless cleared
        output = clear_ownership(current)
        unless output.nil?
          fail Puppet::Error,"Could not take ownership of the tpm. Error from tpm2_takeownership is #{output}"
        end
      end
    else
    # If they want to set ownership auth
      desired = Hash.new
      # Set the desired state for each auth value
      @to_opt.keys.each { |x|
        if @property_flush[:allauth] = :set
          desired[x] = 'set'
        else
          desired[x] = @property_flush[x]
        end
      }
      # Check it the current and desired states match.
      states_match = true
      @to_opt.keys.each { |x|
        unless desired[x].nil?
          if  current[x] != desired[x]
             states_match = false
          end
        end
      }
      unless states_match
        output = take_ownership(current, desired)
        unless output.nil?
           fail Puppet::Error,"Could not take ownership of the tpm. Error from tpm2_takeownership is #{output}"
        end
      end
    end
    @property_hash = resource.to_hash

  end

end
