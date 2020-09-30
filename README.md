[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/tpm2.svg)](https://forge.puppetlabs.com/simp/tpm2)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/tpm2.svg)](https://forge.puppetlabs.com/simp/tpm2)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-tpm2.svg)](https://travis-ci.org/simp/pupmod-simp-tpm2)

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Description](#description)
  * [This is a SIMP module](#this-is-a-simp-module)
* [Setup](#setup)
  * [What tpm2 affects](#what-tpm2-affects)
  * [Beginning with tpm2](#beginning-with-tpm2)
* [Usage](#usage)
* [Limitations](#limitations)
* [Reference](#reference)
* [Development](#development)
  * [Acceptance tests](#acceptance-tests)
    * [TPM2 simulator](#tpm2-simulator)
    * [Debug](#debug)
    * [Environment variables](#environment-variables)

<!-- vim-markdown-toc -->
## Description

This module manages TPM 2.0 devices and the `tpm2-tools` software.

### This is a SIMP module

This module is a component of the [System Integrity Management Platform][simp],
a compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug
tracker][simp-bug-tracker].


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
* The `tpm2` Facter fact
* **TODO**: Ownership of a TPM2 device's endorsement hierarchy


### Beginning with tpm2

```puppet
include 'tpm2'
```

## Usage

To set the authentication passwords on the system:

Include the tpm module and set the following in hiera:

Note: You must indicate the desired status of all three authentications settings.
They can be either 'set' or 'clear'.

tpm2::take_ownership: true
tpm2::ownership::owner: set
tpm2::ownership::lock:  set
tpm2::ownership::endorsement: set

The passwords will default to automatically generated passwords using passgen.  If
you want to set them to specific passwords then set them in hiera using the
following settings (it expects a minumum password length of 14 charaters):

tpm2::ownership::owner_auth: 'MyOwnerPassword'
tpm2::ownership::lock_auth:  'MyLockPassword'
tpm2::ownership::endorse_autt: 'MyEndorsePassword'

## Limitations

The tpm2_takeownership module cannot be used to change the current password. It would
continually try to reset the password and would lock out the TPM.  It should be used
to initialized or clear the TPM only.

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Reference

See [REFERENCE.md](./REFERENCE.md) for API documentation.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

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

The acceptance tests spin up a tpm2-simulator.  These simulators have been
compiled and package by simp and are available in the simp-project
repos, https://download.simp-project.com/simp/yum/.  See the spec/acceptance/nodesets
for the exact repo.

#### Debug

The TPM2 developers provide a debug flag. Set the environemnt variable 
G_MESSAGES_DEBUG=all and run tpm2-abrmd in a terminal.

#### Environment variables


* `BEAKER_download_pre_suite_rpms` When '`yes`', downloads a tarball of RPMs to install before running the first Beaker suite

* `BEAKER_tpm2_rpms_tarball_url`

**FIXME:** Ensure the *Acceptance tests* section is correct and complete, including any module-specific instructions, and remove this message!

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md)
for more information.

[simp]: https://simp-project.com
[simp-bug-tracker]: https://simp-project.atlassian.net/
[tpm2-tools]: https://github.com/tpm2-software/tpm2-toolso
[tpm2-software]: https://github.com/tpm2-software/

