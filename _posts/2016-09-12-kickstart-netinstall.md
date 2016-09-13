---
layout: post
title: Kickstarting RHEL7 Net-Installs
tags: rhel, linux, kickstart
---

Nobody ever said it'd be easy, but then again nobody ever said it'd be this hard.

The theory is simple enough, right? Put an ISO in your server, edit the Linux command-line, hit enter, and fifteen
to thirty minutes later, you have a server running, configured just so.™ In reality, getting Kickstarts to actually work
and to do what you need is pretty hard.

One of the most difficult parts of Kickstart is in _testing_ your Kickstarts. Sure, there's [ksvalidate][ksvalidate],
but that only validates that your _syntax_ is right. Fat-fingered a package name? It could break the entire install,
and as I learned firsthand, it can easily waste your entire day. Those ten minutes waiting for the RAM to initialize,
the RAID firmware to load, entering the BIOS and selecting your boot option, then finally carefully typing in your
command-line... well, they add up real fast.

Let's make testing these things easier, and then we'll provide a fully functional net-install Kickstart.

# Testing Kickstarts Using Packer

If you haven't used [Packer][packer], now's a great time to start. Packer is a tool that can be used to build AMIs,
VirtualBox images, and much more. We'll use it to make a VirtualBox image, just to prove to ourselves that our Kickstart
actually works.

**packer-centos7.json**:

```
{
    "variables": {
        "output_directory": "output-virtualbox-iso",
        "gui_scale_factor": "1",
        "boot_wait": "5s",
        "headless": "false"
    },
    "builders": [
        {
            "type": "virtualbox-iso",
            "guest_os_type": "RedHat_64",

            "http_directory": "srv",
            "boot_command": [
                "<tab> linux ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.ks<enter><wait>"
            ],
            "boot_wait": "{{ user `boot_wait` }}",

            "disk_size": 32000,
            "output_directory": "{{ user `output_directory` }}",

            "iso_url": "https://mirrors.kernel.org/centos/7.2.1511/isos/x86_64/CentOS-7-x86_64-NetInstall-1511.iso",
            "iso_checksum": "9ed9ffb5d89ab8cca834afce354daa70a21dcb410f58287d6316259ff89758f5",
            "iso_checksum_type": "sha256",

            "guest_additions_path": "/tmp/VBoxGuestAdditions.iso",

            "headless": "{{ user `headless` }}",

            "vboxmanage": [
                ["modifyvm", "{{.Name}}", "--memory", "2048"],
                ["setextradata", "{{.Name}}", "GUI/ScaleFactor", "{{ user `gui_scale_factor` }}"]
            ],

            "shutdown_command": "echo 'root' | sudo -S poweroff",

            "ssh_username": "root",
            "ssh_password": "lol",
            "ssh_wait_timeout": "20m",
            "ssh_pty": "true"
        }
    ]
}
```

To summarize, we create a set of variables for configuring some things dependent on your host operating system. For
instance, the `gui_scale_factor` is a huge help on high DPI displays, and it can be set to `2` by adding it to the
build command like so:

```
packer build -var gui_scale_factor=2 packer-centos7.json
```

In `builders`, we tell Packer that we'd like to have one build of `type` `virtualbox-iso`, and inform VirtualBox that
this is going to be a RedHat 64bit guest.

Next, Packer does some magic for us and spins up a HTTP server serving out the content in the `srv` directory. We then
tell Packer to wait for five seconds (or whatever the `boot_wait` command-line variable is set to) on boot, and then
Packer will _type_ in the kernel command-line in the VM for us.
[More info on the `boot_command` is available in the Packer docs][packer_boot_command].

In our case, we tell Packer to load our Kickstart file using the `ks` command-line parameter. Most of the rest of the
Packer config file should be pretty self-explanatory:

 - Download and verify the checksum of the given ISO image, in our case CentOS 7 over HTTPS.
 - Tweak some VirtualBox VM settings.
 - Mount the VirtualBox guest additions ISO in the guest at a given path.
 - Tell Packer to try acquiring SSH to the guest for 20 minutes before giving up. (This has to do with other types of
   provisioning, which isn't so important to us in this example)

Now that we've got a Packer build file, let's dive into Kickstart.

# Kickstart Your Engines

Before we get to the Kickstart, we'll need to generate a root (or user) passphrase in a crypted format. The following
Python script will do the trick:

**scripts/gen-crypted-passphrase.py**:

```
#!/usr/bin/env python3

from crypt import crypt
from getpass import getpass
from random import SystemRandom ; random = SystemRandom()
from string import ascii_lowercase, ascii_uppercase, digits

salt_chars = ascii_lowercase + ascii_uppercase + digits

# generate a SHA-512 passphrase from user input with a 16 byte random salt
passphrase = crypt(getpass(), "$6${}".format(''.join([random.choice(salt_chars) for i in range(16)])))
# print the output
print(passphrase)
```

Generate a password, my output was

```
$6$jtOb5fRIV3KNBxk9$lc39iSR0F2SXftduF1dLwR.PNng2PHmQ/WYzTvb699tZXxFDh/Kte4sGqlFtUHK8sA2QKrzCegb6XymzZdqbD1
```

for the horrible password `lol`. SHA-512 is a hash function and not a KDF, but [it's the best we have for now][crypt],
at least until scrypt support is implemented and standardized.

Finally, the Kickstart:

**srv/kickstart.ks**:

```
# text installer
text
# install from net boot
install
url --url https://mirrors.kernel.org/centos/7.2.1511/os/x86_64/
# restart after finished
reboot

# run the Setup Agent on first boot
firstboot --enable

# localization
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

# this is necessary to prevent x installation
skipx

# configure auth method
auth --enableshadow --passalgo=sha512
# root password
rootpw --iscrypted "$6$jtOb5fRIV3KNBxk9$lc39iSR0F2SXftduF1dLwR.PNng2PHmQ/WYzTvb699tZXxFDh/Kte4sGqlFtUHK8sA2QKrzCegb6XymzZdqbD1"

# system services
services --enabled="chronyd,sshd"

# timezone
timezone UTC --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

# bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda

# Partitioning
# ------------

# only operate on /dev/sda
ignoredisk --only-use=sda

# remove all partitions and recreate the partition table on device sda
clearpart --all --initlabel --drives=sda

part / --fstype="xfs" --ondisk=sda --grow
part /boot --fstype="ext4" --ondisk=sda --size=512
part swap --fstype="swap" --ondisk=sda --size=4096


# Networking
# ----------
network --device=eth0 --bootproto=dhcp


%packages
@^minimal
@core
chrony
kexec-tools
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

%post --interpreter /bin/bash
set -ex

# install puppetlabs repository
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm

# install puppet
yum install -y puppet-agent
%end
```

I'm not going to walk line-by-line through this Kickstart file, as [the docs do a pretty good job][kickstart-syntax]
of explaining everything.

The most critical lines are:

```
# text installer
text
# install from net boot
install
url --url https://mirrors.kernel.org/centos/7.2.1511/os/x86_64/
# restart after finished
reboot
```

The `text` clause will cause the installer to run from a tmux session, making it easy to get shell and poke around if
need be. `install` tells the installer to, well, install, and the `url` clause tells it _where_ to attempt the
installation from. If you pass `cdrom` instead of `url` with a netinstall ISO, installation will fail with an unhelpful
message.

On a real server, it's important that networking works so that the server can download the Kickstart file and fetch
packages from the repositories. If you are so unfortunate as to not have DHCP in your datacenter (I feel your pain in a
very personal way), the kernel command-line you need will likely look like this:

```
ip=10.0.0.4 gateway=10.0.0.1 netmask=255.255.255.0 nameserver=10.0.0.3 ks=http://10.0.0.5/kickstart.ks
```

Pass in your own static IP address, gateway, netmask, and nameserver to get off and running. The
[documentation][kickstart-boot-opts] covers all of the boot parameters.

 [ksvalidate]: https://pypi.python.org/pypi/pykickstart
 [packer]: https://www.packer.io/
 [packer_boot_command]: https://www.packer.io/docs/builders/virtualbox-iso.html#boot_command
 [crypt]: https://stackoverflow.com/a/12660941/128967
 [kickstart-syntax]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/sect-kickstart-syntax.html
 [kickstart-boot-opts]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/chap-anaconda-boot-options.html
