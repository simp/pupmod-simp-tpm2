[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-tpm2.svg)](https://travis-ci.org/simp/pupmod-simp-tpm2) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-6.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-6.*-orange.svg)

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Description](#description)
  * [This is a SIMP module](#this-is-a-simp-module)
* [Setup](#setup)
  * [What tpm2 affects](#what-tpm2-affects)
  * [Setup Requirements **OPTIONAL**](#setup-requirements-optional)
  * [Beginning with tpm2](#beginning-with-tpm2)
* [Usage](#usage)
* [Reference](#reference)
* [Limitations](#limitations)
* [Development](#development)
  * [Acceptance tests](#acceptance-tests)
    * [TPM2 simulator](#tpm2-simulator)
    * [Environment variables](#environment-variables)

<!-- vim-markdown-toc -->
## Description

This module manages TPM 2.0 devices and the `tpm2-tools` software.

### This is a SIMP module

This module is a component of the [System Integrity Management Platform][simp],
a compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug
tracker][simp-bug-tracker].


**FIXME:** Ensure the *This is a SIMP module* section is correct and complete, then remove this message!

This module is optimally designed for use within a larger SIMP ecosystem, but
it can be used independently:

 * When included within the SIMP ecosystem, security compliance settings will
   be managed from the Puppet server.
 * If used independently, all SIMP-managed security subsystems are disabled by
   default and must be explicitly opted into by administrators.  Please review
   the parameters in
   [`simp/simp_options`](https://github.com/simp/pupmod-simp-simp_options) for
   details.

## Setup

### What tpm2 affects

The **tpm2** module manages:

* [`tpm2-software`][tpm2-software] packages and services (e.g., [`tpm2-tools`][tpm2-tools], etc.,)
* Ownership of a TPM2 device's endorsement hierarchy
* The `tpm2` Facter fact

----

**FIXME:** Ensure the *What tpm2 affects* section is correct and complete, then remove this message!

If it's obvious what your module touches, you can skip this section. For
example, folks can probably figure out that your mysql_instance module affects
their MySQL instances.

If there's more that they should know about, though, this is the place to
mention:

 * A list of files, packages, services, or operations that the module will
   alter, impact, or execute.
 * Dependencies that your module automatically installs.
 * Warnings or other important notices.

### Setup Requirements **OPTIONAL**

**FIXME:** Ensure the *Setup Requirements* section is correct and complete, then remove this message!

If your module requires anything extra before setting up (pluginsync enabled,
etc.), mention it here.

If your most recent release breaks compatibility or requires particular steps
for upgrading, you might want to include an additional "Upgrading" section
here.

### Beginning with tpm2

**FIXME:** Ensure the *Beginning with tpm2* section is correct and complete, then remove this message!

The very basic steps needed for a user to get the module up and running. This
can include setup steps, if necessary, or it can be an example of the most
basic use of the module.

## Usage

**FIXME:** Ensure the *Usage* section is correct and complete, then remove this message!

This section is where you describe how to customize, configure, and do the
fancy stuff with your module here. It's especially helpful if you include usage
examples and code samples for doing things with your module.

## Reference

**FIXME:** Ensure the *Reference* section is correct and complete, then remove this message!  If there is pre-generated YARD documentation for this module, ensure the text links to it and remove references to inline documentation.

Please refer to the inline documentation within each source file, or to the
module's generated YARD documentation for reference material.

## Limitations

**FIXME:** Ensure the *Limitations* section is correct and complete, then remove this message!

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

**FIXME:** Ensure the *Development* section is correct and complete, then remove this message!

Please read our [Contribution Guide](http://simp-doc.readthedocs.io/en/stable/contributors_guide/index.html).

### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance
tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).
By default the tests use [Vagrant](https://www.vagrantup.com/) with
[VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox
must both be installed to run these tests without modification. To execute the
tests run the following:

```shell
bundle install
bundle exec rake beaker:suites
```


#### TPM2 simulator

The acceptance tests spin up a tpm2-simulator.  To our knowledge this has not
been packaged for EL7, so a package has been provided as part of



#### Environment variables


* `BEAKER_download_pre_suite_rpms` When '`yes`', downloads a tarball of RPMs to install before running the first Beaker suite

* `BEAKER_tpm2_rpms_tarball_url`

**FIXME:** Ensure the *Acceptance tests* section is correct and complete, including any module-specific instructions, and remove this message!

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md)
for more information.

[simp]: https://github.com/NationalSecurityAgency/SIMP
[simp-bug-tracker]: https://simp-project.atlassian.net/
[tpm2-tools]: https://github.com/tpm2-software/tpm2-toolso
[tpm2-software]: https://github.com/tpm2-software/

