Name:           genesis_scripts
Version:        0.10
Release:        1%{?dist}
License:        Apache License, 2.0
URL:            http://tumblr.github.io/genesis
BuildArch:      noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
Source0:        src/root-bash_profile
Source1:        src/network-prep.init
Source4:        src/genesis-bootloader
Source5:        src/autologin
Source6:        src/genesis.init
Source7:        src/run-genesis-bootloader
Source8:        src/genesis.sysconfig
Summary:        Scripts used by Genesis in the bootcd image
Group:          System Environment/Base
Requires:       initscripts rootfiles patch

%description
Scripts and configuration files used by Genesis in the bootcd image

%prep
# noop

%build
# noop

%install
mkdir -p $RPM_BUILD_ROOT/root
# add root's bash_profile
install -m 644 -T %{SOURCE0}   $RPM_BUILD_ROOT/root/.bash_profile.genesis_scripts

# add some overrides we need
mkdir -p $RPM_BUILD_ROOT/etc/sysconfig/network-scripts
mkdir -p $RPM_BUILD_ROOT/etc/init
mkdir -p $RPM_BUILD_ROOT/etc/init.d
install -m 755 -T %{SOURCE1}   $RPM_BUILD_ROOT/etc/init.d/network-prep
install -m 755 -T %{SOURCE6}   $RPM_BUILD_ROOT/etc/init.d/genesis
install -m 644 -T %{SOURCE8}   $RPM_BUILD_ROOT/etc/sysconfig/genesis

# add helper for agetty
mkdir -p $RPM_BUILD_ROOT/usr/bin/
install -m 555 -T %{SOURCE5}   $RPM_BUILD_ROOT/usr/bin/autologin

# add the bootloader and its wrapper
install -m 555 -T %{SOURCE4}   $RPM_BUILD_ROOT/usr/bin/genesis-bootloader
install -m 755 -T %{SOURCE7}   $RPM_BUILD_ROOT/usr/bin/run-genesis-bootloader

%clean
# noop

%files
%defattr(-, root, root)
/etc/init.d/genesis
/etc/init.d/network-prep
%config /etc/sysconfig/genesis
/root/.bash_profile.genesis_scripts
/usr/bin/genesis-bootloader
/usr/bin/run-genesis-bootloader
/usr/bin/autologin

%post
sed '/.bash_profile.genesis_scripts/d' -i /root/.bash_profile
echo '. /root/.bash_profile.genesis_scripts' >> /root/.bash_profile

# enable autologin for regular tty devices
sed -e '/ --autologin root/d' -i /etc/init/tty.conf
sed -e 's|^exec /sbin/mingetty|exec /sbin/mingetty --autologin root|' -i /etc/init/tty.conf
# enable autologin for serial tty devices
sed -e '/ -8 -n -l .*autologin/d' -i /etc/init/serial.conf
sed -e 's|^exec /sbin/agetty|exec /sbin/agetty -8 -n -l /usr/bin/autologin|' -i /etc/init/serial.conf

chkconfig --add network-prep
chkconfig --add genesis

%changelog
* Thu May 25 2017 Nahum Shalman <nshalman@uber.com> 0.10
- use an init script to launch genesis bootloader
- all ttys log in and tail the log file until done

* Fri Jan 09 2015 Roy Marantz <marantz@tumblr.com> 0.5-1
- redo networking setup

* Tue Dec 16 2014 Roy Marantz <marantz@tumblr.com> 0.3-1
- add genesis-bootloader

* Mon Jul 07 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.2-2
- bringing up all 4 possible nics on the host machine when doing genesis boot

* Mon Jul 07 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.2-1
- Bringing up all 4 possible nics on the host machine via dhcp

* Tue May 06 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.1-7
- fixing patch in %%post block (jeremy@tumblr.com)

* Tue May 06 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.1-6
- fixing package to get it to install properly (jeremy@tumblr.com)

* Tue May 06 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.1-5
- cleaned up spec file for proper building
* Tue May 06 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.1-4
- updating spec for proper building (jeremy@tumblr.com)

* Tue May 06 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.1-3
- removing stale bootloader from sources (jeremy@tumblr.com)

* Tue May 06 2014 Jeremy Johnstone <jeremy@tumblr.com> 0.1-2
- new package built with tito
