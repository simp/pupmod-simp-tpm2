# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-tpm2` is a SIMP Puppet module that manages a **TPM 2.0** (Trusted Platform
Module 2.0) device on Enterprise Linux systems. It does three things:

1. **Installs the tpm2 tooling** — the `tpm2-tools`, `tpm2-tss`, and
   `tpm2-abrmd` packages (`manifests/install.pp`, driven by
   `data/common.yaml`).
2. **Manages the resource-manager service** — the `tpm2-abrmd` (TPM2 Access
   Broker & Resource Manager) systemd service (`manifests/service.pp`).
3. **Optionally takes/changes ownership of the TPM** — sets or clears the
   authentication passwords for the TPM's three authorization hierarchies
   (**owner**, **lockout**, **endorsement**) when
   `tpm2::take_ownership` is `true` (`manifests/init.pp`).

The catalog "sees" the TPM through a custom structured Facter fact, **`tpm2`**
(`lib/facter/tpm2.rb` + `lib/facter/tpm2/util.rb`), which shells out to
`tpm2_getcap` to report manufacturer, firmware version, installed tools version,
and the raw fixed/variable capability properties. Ownership management is
implemented by two **custom native types/providers** that shell out to
`tpm2-tools`.

### Business logic

The module has three public entry points — the `tpm2` class, and the
`tpm2::ownership*` classes — plus two private classes.

- **`tpm2` (`manifests/init.pp`)** — public entry class; consumers
  `include 'tpm2'`. Parameters (`init.pp`):
  - `$package_ensure` (`String[1]`) — defaults to
    `simplib::lookup('simp_options::package_ensure', {'default_value' => 'installed'})`
    (`init.pp`). This is the **only** `simp_options::*` seam in the module.
  - `$packages` (`Hash[String[1], Hash[String[1],String[1]]]`) —
    `simplib::lookup('tpm2::packages')` with **no default_value**
    (`init.pp`), so it is resolved entirely from module data
    (`data/common.yaml`). A missing `tpm2::packages` key is a compile error.
  - `$tabrm_service` (`String[1]`) — default `'tpm2-abrmd'` (`init.pp`).
  - `$tabrm_options` (`Optional[Array[String[1]]]`) — default `undef`; an
    **explicitly unvalidated** list of options passed to the service at start
    (`init.pp`).
  - `$take_ownership` (`Boolean`) — default `false` (`init.pp`).

  Control flow (`init.pp`):
  - `simplib::assert_metadata($module_name)` runs first (`init.pp`).
  - **tpm1 guard** (`init.pp`): if `$facts['tpm_version'] == 'tpm1'`, the
    module does **nothing** except emit a `notify` — it will not install TPM2
    resources on a TPM 1.2 host.
  - Otherwise it `include`s `tpm2::install` and `tpm2::service`, orders
    `Class['tpm2::install'] ~> Class['tpm2::service']` (`init.pp`), and
    `include`s `tpm2::ownership` only when `$take_ownership` (`init.pp`).

- **`tpm2::install` (`manifests/install.pp`)** — `assert_private()`
  (`install.pp`). Iterates `$tpm2::packages` and declares a `package` for
  each. The per-package `ensure` from data is the literal string
  `package_ensure`, which `regsubst` rewrites to the value of
  `$tpm2::package_ensure` (`install.pp`) — this is the indirection that lets
  `data/common.yaml` say `ensure: package_ensure` as a placeholder.

- **`tpm2::service` (`manifests/service.pp`)** — `assert_private()`
  (`service.pp`). Ensures `Service[$tabrm_service]` is `running`/`enable => true`
  (`service.pp`). If `$tabrm_options` is set, it writes a systemd drop-in
  via `systemd::dropin_file` (`service.pp`) that overrides `ExecStart` to
  `/usr/sbin/<service> <joined options>`.

- **`tpm2::ownership` (`manifests/ownership.pp`)** — the version-dispatch
  entry point. It reads `$facts['tpm2']['tools_version']` and, using
  `versioncmp`, delegates to:
  - `tpm2::ownership::takeownership` when tools **< 4.0.0** (`ownership.pp`),
    which uses the `tpm2_ownership` type / `tpm2_takeownership` command;
  - `tpm2::ownership::changeauth` when tools **>= 4.0.0** (`ownership.pp`),
    which uses the `tpm2_changeauth` type / command.
  On tools < 4.0.0, `owner`/`endorsement`/`lockout` of `'ignore'` is a hard
  `fail()` (`ownership.pp`) — the old tool requires all three values. The
  whole block is a no-op unless both `$facts['tpm2']` and its `tools_version`
  are present (`ownership.pp`).

- **`tpm2::ownership::takeownership` (`manifests/ownership/takeownership.pp`)** —
  declares a single `tpm2_ownership { 'tpm2': }` resource (`takeownership.pp`),
  requiring `Class['tpm2::service']`.

- **`tpm2::ownership::changeauth` (`manifests/ownership/changeauth.pp`)** —
  declares up to three `tpm2_changeauth` resources named `'owner'`, `'lockout'`,
  `'endorsement'`, each skipped when its state is `'ignore'`
  (`changeauth.pp`).

  In all three ownership classes the auth passwords default to
  `simplib::passgen("${facts['networking']['fqdn']}_tpm_<hierarchy>_auth", {'length'=> 24})`
  (e.g. `ownership.pp`) — auto-generated, host-specific, min length 14
  (the `String[14]` param type).

### Custom types and providers (the heart of the module)

- **`tpm2_ownership` type (`lib/puppet/type/tpm2_ownership.rb`)** — namevar
  `name` is validated to be exactly `'tpm2'` (`type/tpm2_ownership.rb`).
  Params: `owner_auth`, `lockout_auth`, `endorsement_auth` (Strings, default
  `''`), `in_hex` (boolean), `local` (boolean). Properties: `owner`,
  `endorsement`, `lockout`, each `newvalues(:clear, :set)`. Global validation
  requires the matching `*_auth` when a hierarchy is `:set`
  (`type/tpm2_ownership.rb`). `autorequire`s packages `tpm2-tss`,
  `tpm2-tools` and service `tpm2-abrmd`.

- **`tpm2_takeownership` provider
  (`lib/puppet/provider/tpm2_ownership/tpm2_takeownership.rb`)** — wraps the
  `tpm2_takeownership` command (tpm2-tools < 4). Reads current state from the
  `tpm2` fact's `tpm2_getcap.properties-variable.TPM_PT_PERSISTENT.*AuthSet`
  keys (`tpm2_takeownership.rb`). Builds CLI flags per hierarchy
  (`-o/-e/-l`; upper-case variant `-O/-E/-L` when the current auth is already
  set) and appends `-X` when `in_hex` (`tpm2_takeownership.rb`). **Safety
  guard:** if any hierarchy's current state reads `:unknown`, `flush` refuses to
  run `tpm2_takeownership` at all, to avoid locking out the TPM
  (`tpm2_takeownership.rb`).

- **`tpm2_changeauth` type (`lib/puppet/type/tpm2_changeauth.rb`)** — namevar
  `name` validated to one of `'owner'`, `'lockout'`, `'endorsement'`
  (`type/tpm2_changeauth.rb`). Param `auth` (non-empty String,
  `type/tpm2_changeauth.rb`); property `state` `newvalues(:clear, :set)`.
  Same `autorequire`s as above.

- **`tpm2_changeauth` provider
  (`lib/puppet/provider/tpm2_changeauth/tpm2_changeauth.rb`)** — wraps the
  `tpm2_changeauth` command (tpm2-tools >= 4). Maps the resource name to a `-c
  o|l|e` context flag; `:set` passes the auth as a positional arg, `:clear`
  passes `-p <auth>` (`tpm2_changeauth.rb`). Reads current state from the
  fact's `...TPM2_PT_PERSISTENT.*AuthSet` keys (`tpm2_changeauth.rb`).

- **`tpm2` fact (`lib/facter/tpm2.rb`, `lib/facter/tpm2/util.rb`)** — `confine`d
  on `tpm2_getcap` being present (`facter/tpm2.rb`); nil otherwise. `Util`
  detects the tools version via `tpm2_getcap -v` and switches both the command
  form and the property-key prefix (`TPM` for < 4.0.0, `TPM2` for >= 4.0.0 —
  `facter/tpm2/util.rb`). It runs `properties-fixed` and
  `properties-variable`, YAML-parses them, and returns a structured hash with
  `manufacturer`, `vendor_strings`, `firmware_version`, `tools_version`, and the
  raw `tpm2_getcap` output (`facter/tpm2/util.rb`).

## Gotchas / non-obvious details

- **The property-key prefix differs between the two providers.** The fact
  chooses the prefix (`TPM` vs `TPM2`) by tools version
  (`facter/tpm2/util.rb`). The `takeownership` provider (used with tools
  < 4) reads `TPM_PT_PERSISTENT` (`tpm2_takeownership.rb`), while the
  `changeauth` provider (used with tools >= 4) reads `TPM2_PT_PERSISTENT`
  (`tpm2_changeauth.rb`). These line up with the version each provider is
  selected for, but the hard-coded prefixes are easy to get wrong — verify
  against `util.rb`'s prefix logic before editing either provider.
- **Ownership does nothing without a usable `tpm2` fact.** `tpm2::ownership`
  short-circuits unless `$facts['tpm2']['tools_version']` is set
  (`ownership.pp`), and the fact is `nil` unless `tpm2_getcap` is installed
  and reachable (`facter/tpm2.rb`). On tools < 4.0.0 this typically needs
  **two Puppet runs**: one to install `tpm2-tools` so the fact populates, one to
  act on it (noted in `ownership/takeownership.pp`).
- **The takeownership provider will silently refuse to act if TPM state is
  unknown.** This is deliberate — running `tpm2_takeownership` blind can lock
  out the TPM (`tpm2_takeownership.rb`). It logs a warning and returns.
- **These types cannot *change* an already-set password**, only set an unset one
  or clear a known one. This is stated in the type docs
  (`type/tpm2_ownership.rb`, `type/tpm2_changeauth.rb`) and the class docs.
- **`tpm2::packages` has no default_value in the lookup** (`init.pp`) — it is
  resolved purely from module data. If you rename or remove the key from
  `data/common.yaml`, catalog compilation fails.
- **The `package_ensure` placeholder in data is a literal string, not a
  variable.** `data/common.yaml` sets each package's `ensure:` to the string
  `package_ensure`, which `tpm2::install` rewrites via `regsubst` to
  `$tpm2::package_ensure` (`install.pp`). Setting `ensure:` to a real value
  (e.g. `latest`) in data bypasses that indirection.
- **`$tabrm_options` is explicitly unvalidated** (`init.pp`) and is joined
  straight into a systemd `ExecStart` line (`service.pp`) — treat it as a
  command-injection-adjacent surface.
- **tpm1 hosts are a no-op.** A TPM 1.2 device (`$facts['tpm_version'] ==
  'tpm1'`) skips all resources with only a `notify` (`init.pp`).
- **Acceptance suites exist on disk but are NOT wired into CI** — see the CI
  subsection below.

## Dependencies

Module dependencies (from `metadata.json`):

- `simp/simplib` `>= 4.9.0 < 5.0.0` (provides `simplib::lookup`,
  `simplib::assert_metadata`, `simplib::passgen`) — note the **upper bound is
  `< 5.0.0`**, tighter than many sibling modules' `< 7.0.0`.
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (provides `regsubst`, `join`,
  `versioncmp`).

There are **no** `optional_dependencies` and no `assert_optional_dependency`
calls in this module.

**Undeclared-but-used** (a genuine gap to be aware of, not a runtime dep the
metadata declares):

- **`puppet/systemd`** — `service.pp` calls `systemd::dropin_file`, but
  `systemd` is **not** in `metadata.json` dependencies. It is only present as a
  fixture (`.fixtures.yml`). The drop-in path is only exercised when
  `$tabrm_options` is set.

Fixture-only dependencies (from `.fixtures.yml`, present for test compilation,
not runtime deps): `iptables`, `simplib`, `stdlib`, `systemd`.

Runtime requirement (from `metadata.json` `requirements`): `puppet
>= 7.0.0 < 9.0.0`. This is the **older SIMP baseline** — this module is not yet
on OpenVox. When `metadata.json` switches this to `openvox`, update this line to
match.

Supported OS matrix (from `metadata.json`): CentOS 7/8/9; RedHat 7/8/9;
OracleLinux 7/8/9; Rocky 8/9; AlmaLinux 8/9. (This is an older matrix than some
sibling modules — it still lists EL7 and does not yet include EL10.)

## Repository layout

- `manifests/init.pp` — public `tpm2` class (entry point, tpm1 guard, wiring).
- `manifests/install.pp` — private `tpm2::install` (packages).
- `manifests/service.pp` — private `tpm2::service` (tpm2-abrmd service + drop-in).
- `manifests/ownership.pp` — public `tpm2::ownership` (tools-version dispatch).
- `manifests/ownership/takeownership.pp` — `tpm2_ownership` resource (tools < 4).
- `manifests/ownership/changeauth.pp` — `tpm2_changeauth` resources (tools >= 4).
- `types/ownership.pp` — `Tpm2::Ownership = Enum['set','clear']` data type.
- `lib/facter/tpm2.rb`, `lib/facter/tpm2/util.rb` — the structured `tpm2` fact.
- `lib/puppet/type/tpm2_ownership.rb`,
  `lib/puppet/provider/tpm2_ownership/tpm2_takeownership.rb` — the `tpm2_ownership`
  native type + `tpm2_takeownership` provider (tpm2-tools < 4).
- `lib/puppet/type/tpm2_changeauth.rb`,
  `lib/puppet/provider/tpm2_changeauth/tpm2_changeauth.rb` — the `tpm2_changeauth`
  native type + provider (tpm2-tools >= 4).
- `data/common.yaml` — the `tpm2::packages` hash; `hiera.yaml` — v5 module-data
  hierarchy (OS family → common).
- `metadata.json` — deps, OS matrix, Puppet requirement.
- `spec/classes/*.rb` — rspec-puppet unit tests for the manifests.
- `spec/unit/facter/`, `spec/unit/puppet/type/`, `spec/unit/puppet/provider/` —
  Ruby unit tests for the fact, types, and providers.
- `spec/files/tpm2/mocks/` — captured real `tpm2_getcap` output and EK
  certificates for several vendor TPMs, used by the fact/provider specs.
- `spec/acceptance/suites/default/00_init_spec.rb`,
  `01_ownership_spec.rb` — beaker acceptance suites; nodesets
  `spec/acceptance/nodesets/default.yml` and `oel.yml` (**2** nodeset files).
- `REFERENCE.md` — generated Puppet Strings reference.
- No `templates/`.

### CI

`.github/workflows/pr_tests.yml` runs on pull requests with a global
`env: PUPPET_VERSION: '~> 7'` (`pr_tests.yml`, the older baseline style).
It defines **six** jobs and **no acceptance job**:

- `puppet-syntax` — `bundle exec rake syntax`
- `puppet-style` — `bundle exec rake lint` + `rake metadata_lint`
- `ruby-style` — `bundle exec rake rubocop` (`continue-on-error: true`)
- `file-checks` — `rake check:dot_underscore` + `rake check:test_file`
- `releng-checks` — version/tag/changelog checks + `pdk build --force`
- `spec-tests` — `bundle exec rake spec`, matrix Puppet `~> 7.0` (Ruby 2.7) and
  `~> 8.0` (Ruby 3.2)

**Gotcha:** the beaker acceptance suites and 2 nodesets exist on disk (see
layout above) but are **not** wired into `pr_tests.yml` — there is no
`acceptance` job. Acceptance must be run locally.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests (manifests + Ruby fact/type/provider specs)
bundle exec rake spec

# Run a single spec
bundle exec rspec spec/classes/ownership_spec.rb
bundle exec rspec spec/unit/facter/tpm2/util_spec.rb

# Puppet lint / syntax
bundle exec rake lint
bundle exec rake syntax

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run a beaker acceptance suite (NOT run in CI; local only)
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `rubocop ~> 1.88.0` (`Gemfile`),
`puppetlabs_spec_helper ~> 8.0.0` (`Gemfile`), `simp-rake-helpers ~> 5.24.0`
(`Gemfile`), `simp-rspec-puppet-facts ~> 4.0.0` (`Gemfile`),
`simp-beaker-helpers ~> 2.0.0` (`Gemfile`). The Puppet gem is pulled in
**only** through `gem 'puppet', puppet_version` (`Gemfile`), where
`puppet_version` defaults to `['>= 7', '< 9']` (`Gemfile`).

## Conventions

- **Route SIMP package state through the `simp_options::package_ensure` seam.**
  The single `simplib::lookup` with an explicit `default_value` is at
  `init.pp`; keep new package resources consistent with it.
- **Keep the package list in module data** (`data/common.yaml`
  `tpm2::packages`), using the `ensure: package_ensure` placeholder that
  `tpm2::install` rewrites — do not hard-code package names in the manifest.
- **Keep `assert_private()` on `tpm2::install` and `tpm2::service`**
  (`install.pp`, `service.pp`); they are internal and must be reached via
  `include 'tpm2'`.
- **Dispatch on tools version in `tpm2::ownership`, not in the providers.** The
  manifest decides `takeownership` (< 4) vs `changeauth` (>= 4) via `versioncmp`
  on the `tpm2` fact (`ownership.pp`); keep that split intact.
- **Preserve the safety guards in the providers** — the unknown-state refusal in
  `tpm2_takeownership.rb` and the empty-auth validation in the types
  exist to avoid locking out real TPM hardware.
- Preserve the `@summary` / `@param` puppet-strings docstrings on classes and
  the `@doc`/`desc` blocks on the types/providers — they drive `REFERENCE.md`.
  Regenerate `REFERENCE.md` after changing docs or parameters.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow / aligned-`=`
  parameter style used across `manifests/`.
