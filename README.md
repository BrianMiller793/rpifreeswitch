# FreeSWITCH for Raspbian Lite

The purpose of this project is to make an easy-to-install system for
installing and configuring FreeSWITCH on Raspbian Lite.  This will build
the minimal configuration for FreeSWITCH.

This has been tested on Raspberry Pi 3, using a Samsung Evo Plus 32GB microSD
card.  The compile performance for FreeSWITCH, with a minimal configuration,
is less than 30 minutes.

## Building FreeSWITCH

Run `pilitefs.sh`, with no modules.conf in the `~` directory.

This will install prerequisite packages, get the source, build it, install it
into `/usr/local/freeswitch`, and make a few optimizations for Raspberry Pi.

## Running FreeSWITCH

    cd /usr/local/freeswitch
    sudo ./bin/freeswitch

This will start FreeSWITCH in the console mode.  The extensions 1000-1019 are
available from the default "vanilla" configuration.

### Configuring Linphone

The [Linphone app](http://www.linphone.org) was used for testing.  The
accounts 1000 and 1001 were configured on the devices, as follows:

User name: `1000`  
Password: `1234`  
Domain: `192.168.0.42`  
Transport: `UDP`  
Proxy: `<sip:192.168.0.42;transport=udp>`  

## FreeSWITCH Configuration

**NOTE:** Change the passwords in [`conf/vars.xml`](https://freeswitch.org/confluence/display/FREESWITCH/vars.xml)!!  
The default SIP account password is `1234` and the default
[XML-RPC](https://freeswitch.org/confluence/display/FREESWITCH/FreeSWITCH+XML-RPC)
password is `worksnot`.

### Top Level Configuration

FreeSWITCH Confluence: [Default Configuration](https://freeswitch.org/confluence/display/FREESWITCH/Default+Configuration)

The `freeswitch.xml` file is central to the configuration.  This is configured
to load other files.  In this minimal configuration, `vars.xml`,
`autoload_configs/*.xml`, the diaplan, and the directory are loaded.

The `vars.xml` file contains global variable definitions.  They are set here,
and then referenced later on as `$${name}`.  Some of the variables are defined
by FreeSWITCH, such as `local_ip_v4` and `domain`.

### Connecting to FreeSWITCH

The `conf/directory` directory contains the configuration files for endpoints
to connect to the server.  If your phone fails to register, then start
checking here.

These files are copied in whole from the vanilla configuration.  The `default`
directory is the domain named, "default."  Each seperate domain would have its
own directory.

### Dialing to Extensions

FreeSWITCH Confluence: [XML Dialplan](https://freeswitch.org/confluence/display/FREESWITCH/XML+Dialplan)

The `conf/dialplan` directory contains the configuration files for dialing
from one endpoint to another, or outside the server.

The `default.xml` file has been trimmed down from the vanilla configuration.
There are three extension definitions: global, Local_Extension, and show_info.
The Local_Extension block governs the behavior for dialing local extensions.

## Script Environmental Variables

| Variable | Purpose |
|---|---|
| `BRANCH` | Version branch: v1.6, v1.8, master |
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
