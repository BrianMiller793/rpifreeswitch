# FreeSWITCH for Raspbian Lite

The purpose of this project is to make an easy-to-install system for
installing and configuring FreeSWITCH on Raspbian Lite.  This will build
the minimal configuration for FreeSWITCH.

This has been tested on Raspberry Pi 3, using a Samsung Evo Plus 32GB microSD
card.  The compile performance for FreeSWITCH, with a minimal configuration,
is less than 30 minutes.

## To use:

Run `pilitefs.sh`, with no modules.conf in the `~` directory.

This will install prerequisite packages, get the source, build it, install it
into `/usr/local/freeswitch`, and make a few optimizations for Raspberry Pi.

## To run:

    cd /usr/local/freeswitch
    sudo ./bin/freeswitch

(There is a section in pilitefs.sh for configuring FreeSWITCH scripts for use
with Raspbian Lite and integrating it with services, but it's not done yet.)

## Environmental Variables

| Variable | Purpose |
|---|---|
| `BRANCH` | Version branch, v1.6, v1.8, master |
| `BUILDHOME` | Root directory for source, .deb, binaries, etc. |
| `BUILDDIR` | Directory under BUILDHOME for FreeSWITCH. |
| `FSHOME` | Installation directory, `/usr/local/freeswitch` |
| `FREESWITCHGIT` | Git URI for FreeSWITCH |
| `NOPREREQUISITES` | If set, do not install prerequisite packages. |
| `NOSOURCE` | If set, do not perform `git` operations. |
| `BUILDDEBPACKAGES` | If set, build the Debian FreeSWITCH packages. |
| `NOBUILDUSRLOCAL` | If set, do not create or install binaries. |
| `NOCONFIGUREUSRLOCAL` | If set, do not perform any post-build configuration. |

## Building and modules.conf

The `modules.conf` file controls what is built in the configuration.  The
script will use the `conf/minimal/modules.conf` file for the minimal
configuration, unless one is present.  The one included here is for
building _all_ of the modules that can be built on the Raspberry Pi.
Some of the modules apparently need tweaks, but most of them will compile.

## Minimal Configuration

The configuration uses the `conf/minimal` files as a starting point, and then
copies and modifies files from `conf/vanilla` to give a working starting
point to register endpoints and make calls between the extensions.
