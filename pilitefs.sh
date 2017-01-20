#!/bin/bash

# FreeSWITCH for Raspberrian Lite

set -x
set -e

# git ls-remote --heads https://freeswitch.org/stash/scm/fs/freeswitch.git/ | grep '/v[0-9]'
# branches from 'git branch -a'
# master
# remotes/origin/master
# remotes/origin/v1.2
# remotes/origin/v1.2.stable
# remotes/origin/v1.4
# remotes/origin/v1.6
# remotes/origin/v1.8

: ${BRANCH:=v1.6}
: ${BUILDHOME:=~}
: ${BUILDDIR:=$BUILDHOME/freeswitch.git}
: ${FSHOME:=/usr/local/freeswitch}
export LD_PRELOAD=/usr/lib/arm-linux-gnueabihf/libfakeroot/libfakeroot-sysv.so

GetPackages()
{
  # The following packages are based on building FreeSWITCH for all
  # of the available modules.  Fewer packages would be needed for a
  # minimal installation.

  # Do a quick check to see if system needs packages.
  NEEDPKG=0
  for pkg in autoconf automake devscripts gawk g++ git-core libjpeg-dev
  do
    dpkg -s "$pkg" > /dev/null 2>&1
    NEEDPKG=$(($? | NEEDPKG))
  done
  if [ "$NEEDPKG" -eq 0 ]; then return; fi

  echo PACKAGES......................................
  sudo apt-get -y update
  sudo apt-get -y install \
    autoconf automake devscripts gawk g++ git-core libjpeg-dev \
    libncurses5-dev libtool make python-dev gawk pkg-config libtiff5-dev \
    libperl-dev libgdbm-dev libdb-dev gettext equivs mlocate git dpkg-dev \
    devscripts sox flac

  sudo apt-get -y install \
    dh-systemd libtool-bin libpcre3-dev libedit-dev libsqlite3-dev yasm \
    libogg-dev libspeex-dev libspeexdsp-dev libssl-dev unixodbc-dev libpq-dev \
    python-all-dev python-support erlang-dev doxygen uuid-dev

  sudo apt-get -y install \
    libcurl4-openssl-dev libcurlpp0 libavformat-dev libswscale-dev \
    libopencv-dev libldns-dev libhiredis-dev ladspa-sdk libmemcached-dev

  sudo apt-get -y install \
    libsoundtouch-dev libflite1 flite1-dev libpjmedia-codec2 libopus-dev \
    libasound2-dev portaudio19-dev libx11-dev librabbitmq-dev libsnmp-dev

  sudo apt-get -y install \
    libmagickcore-dev libvorbis-dev libmp3lame-dev libmpg123-dev \
    libshout3-dev libsndfile1-dev libflac-dev libvlc-dev default-jdk \
    liblua5.2-dev libmono-2.0-dev mono-mcs libyaml-dev bison libbison-dev

  sudo update-alternatives --set awk /usr/bin/gawk
}

GetSource()
{
  # Get source or update from git repository.

  FREESWITCHGIT=https://freeswitch.org/stash/scm/fs/freeswitch.git

  if [ -d "$BUILDDIR/$BRANCH" ]
  then
    pushd "$BUILDDIR/$BRANCH"
    git clean -fdx
    git reset --hard "origin/$BRANCH"
    git pull
    popd
  else
    mkdir -p "$BUILDDIR"
    pushd "$BUILDDIR"
    if [ -z "$BRANCH" -o "$BRANCH" = "master" ]
    then
      # Master branch
      git clone "$FREESWITCHGIT" "master"
    else
      git clone -b "$BRANCH" "$FREESWITCHGIT" "$BRANCH"
    fi
    popd
  fi
}

BuildPackages()
{
  # Build *.deb packages.
  # This will attempt to build the marjority of the packages.

  pushd "$BUILDDIR/$BRANCH"

  DCH_DISTRO=UNRELEASED
  DISTRO="$(lsb_release -is)$(lsb_release -cs)"
  FS_VERSION="$(sed -e 's/-/~/g' ./build/next-release.txt)~n$(date +%Y%m%dT%H%M%SZ)-1~${DISTRO}+1"
  PACKAGES="package.${BRANCH}"

  echo BUILDING PACKAGES......................................
  ./build/set-fs-version.sh "$FS_VERSION"
  (cd debian && \
   dch -b -m -v "$FS_VERSION" \
     --check-dirname-level 0 \
     --force-distribution -D "$DCH_DISTRO" "Custom build.")

  # Look for a custom modules.conf in the home directory, copy it in
  # if it exists.  Otherwise, do a minimal build.
  if [ -f ~/modules.conf ]
  then
    cp ~/modules.conf ./debian/
  else
    cp conf/minimal/modules.conf ./debian/
  fi

#  Create modules.conf based on all of the available modules.
#  Some of these will not be able to be built, due to lack of libraries.
#  The following will create a modules.conf for all available modules.  Modify
#  the file for what actually works.
#
#  for moddir in $(find src/mod -mindepth 2 -maxdepth 2 -type d)
#  do
#    echo "${moddir#src/mod/}" >> ./debian/modules.conf
#  done
  (cd debian && ./bootstrap.sh -c "${DISTRO}")
  if [ -f ./debian/control ]; then sudo mk-build-deps -i ./debian/control; fi
  dpkg-buildpackage -b -uc

  mkdir "../$PACKAGES"
  mkdir "../$PACKAGES/dbg"
  mv ./*.deb "../$PACKAGES"
  mv ../*-dbg_*.deb "../$PACKAGES/dbg"
  mv ../*.deb "../$PACKAGES"
  mv ../*.changes "../$PACKAGES"

  popd
}

BuildUsrLocal()
{
  # By default FreeSWITCH installs into /usr/local/freeswitch.

  pushd "$BUILDDIR/$BRANCH"

  # Remove old binaries
  if [ -d "$FSHOME/bin" ]
  then
    sudo rm -rf $FSHOME/{bin,mod,lib}/*
  fi

  cp -n conf/minimal/modules.conf .
  if [ ! -d configure ] ; then ./bootstrap.sh -j ; fi
  ./configure -C
  make -j 3

  sudo make install

  if [ ! -d "$FSHOME/sounds/en" ]
  then
    sudo make uhd-sounds-install
    sudo make uhd-moh-install
  fi

  popd
}

ConfigureUsrLocal()
{
#  TODO, part of security configuration below.
#  # Make basic configuration changes to the installation, once.
#  [ "$(stat -c %U /usr/local/freeswitch)" = freeswitch ] && return

  # Put the database into shared memory, essential for Pi.
  sudo sed -i -e '/core-db-name/s/<!-- \(.*\) -->/\1/' \
    "$FSHOME/conf/autoload_configs/switch.conf.xml"

  # There's a bug in the logging module, disable rollover, reduce messages.
  sudo sed -i \
    -e '/rollover/s/value="[0-9]*"/value="0"/' \
    -e '/map name="all"/s/value="[^"]*"/value="warning,err,crit,alert"/' \
    "$FSHOME/conf/autoload_configs/logfile.conf.xml"

  sudo cp -R "./conf/minimal/*" "$FSHOME/conf"
#  Use the following to automatically configure modules.conf for the
#  available modules.
#
#  # A number of modules in the minimal configuration are not compiled.
#  # Comment out all active modules, then enable only the modules that
#  # have been installed.
#  sudo sed -i -e '/^    \(<load.*>\)/s//    <!-- \1 -->/' \
#    "$FSHOME/conf/autoload_configs/modules.conf.xml"
#  for module in $FSHOME/mod/*
#  do
#    modName=${module##*/}
#    regex='/'${modName%%.*}'/s/<!-- *\([^>]*>\).*/\1/'
#    sudo sed -i -e "$regex" \
#      "$FSHOME/conf/autoload_configs/modules.conf.xml"
#  done

# The following is in progress for configuring the 'service XX start|stop'
# for Raspberrian, and doing a little bit of security modifications.
#
# sudo mkdir /usr/local/etc/init.d
# sudo cp "$BUILDDIR/$BRANCH"/debian/freeswitch-sysvinit.freeswitch.init /usr/local/etc/init.d/freeswitch.sh
# TODO: do substitutions for /usr/local
# sudo useradd -M freeswitch
# sudo usermod -L freeswitch
# sudo chmod +x /usr/local/etc/init.d/freeswitch.sh
# sudo chown -R freeswitch:freeswitch /usr/local/freeswitch
}

# Default:
# Get prerequesite Debian packages
# Get source
# Do not build *.deb packages
# Build for /usr/local/freeswitch
# Configure /usr/local/freeswitch

if [ -z "$NOPREREQUESITES" ]     ; then GetPackages ; fi
if [ -z "$NOSOURCE" ]            ; then GetSource ; fi
if [ -n "$BUILDDEBPACKAGES" ]    ; then BuildPackages ; fi
if [ -z "$NOBUILDUSRLOCAL" ]     ; then BuildUsrLocal ; fi
if [ -z "$NOCONFIGUREUSRLOCAL" ] ; then ConfigureUsrLocal ; fi

echo
echo Build is complete.
echo "Default password in vars.xml is $(sed -n -e '/.*default_password=\([^"]*\)".*/s//\1/p' $FSHOME/conf/vars.xml)"
