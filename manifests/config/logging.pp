# == Class tpm2::config::logging
#
# This class is meant to be called from tpm2.
# It ensures that logging rules are defined.
#
class tpm2::config::logging {
  assert_private()

  # FIXME: ensure your module's logging settings are defined here.
  $msg = "FIXME: define the ${module_name} module's logging settings."

  notify{ 'FIXME: logging': message => $msg } # FIXME: remove this and add logic
  err( $msg )                                 # FIXME: remove this and add logic

}

