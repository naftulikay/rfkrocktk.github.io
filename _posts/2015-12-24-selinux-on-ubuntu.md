---
layout: post
title: SELinux on Ubuntu
tags: security, linux, ubuntu, selinux
---

Spoiler alert: you're on your own, kid.

[[toc]]

![Good Luck][gif-good-luck] ![You're Gonna Need It][gif-gonna-need-it]

If you're expecting to have a working targeted or strict enforcing system at the end of this post, don't. You're going
to have to do a lot of manual lifting and work to get SELinux working, and I mean a _lot_ of work.

Since the end result is that SELinux probably won't be working anyway, I'm going to take a few liberties here and gloss
over all of the important details.

# Installation

First, you'll need to install SELinux packages. There are a few of them, but you'll at least need `selinux` and
`selinux-policy-default`.

If you want audit logs (you do), you'll also need to install `auditd`. Fun.

If you want tools for working with SELinux (you'll need them), you'll also need to install `policycoreutils`.

The default policy
that's selected by default is the `ubuntu` policy, provided by `selinux-policy-ubuntu`. Guess what? It doesn't contain
any modules, definitions, port types, or anything else useful.

![Does this look dangerous?][gif-dangerous]

The `selinux-policy-default` package is a bit more sane. To change this, edit `/etc/selinux/config` to switch to
`SELINUXTYPE=default`.

Now you'll need to add the following to your kernel command line to get the Ubuntu kernel to use SELinux instead of
AppArmor (even though AppArmor has been uninstalled):

```
security=selinux selinux=1
```

Reboot into permissive mode, and relabel your filesystem manually:

```
sudo restorecon -R /
```

# Configuration

Now that you're at least booted into a properly-labeled SELinux system, make sure that it's in permissive mode:

```
$ sudo getenforce
Permissive
```

Great. I'm on elementary OS Freya, based on 14.04. Feel free to `setenforce 1` whenever you're ready. Things are going
to break. My display manager crashes as soon as I start enforcing.

Let's do this.

![eff yeah][img-fyeah]

```
sudo grep -i networkmanager /var/log/audit/audit.log | audit2allow | tee networkmanager-local.te
```

Awesome, we're getting somewhere:

```
# NetworkManager_var_lib_t, NetworkManager_var_run_t, network_var_run_t, lib_t

allow NetworkManager_t tmpfs_t:dir { search read create write getattr remove_name open add_name };

#!!!! The source type 'NetworkManager_t' can write to a 'file' of the following types:
# NetworkManager_tmp_t, NetworkManager_log_t, NetworkManager_var_lib_t, NetworkManager_var_run_t, net_conf_t, network_var_run_t, var_lock_t

allow NetworkManager_t tmpfs_t:file { rename setattr read create write getattr link unlink open };
allow NetworkManager_t var_lock_t:lnk_file read;
allow NetworkManager_t var_t:lnk_file read;
```

Looks like we've got ourselves a policy module. Let's compile it.

```
checkmodule -M -m -o networkmanager-local.mod networkmanager-local.te
semodule_package -o networkmanager-local.pp -m networkmanager-local.mod
```

Now, insert the module into SELinux:

```
sudo semodule -i networkmanager-local.pp
```

![boogie][gif-boogie]

Boom.

# Targeted? Strict? No, Default.

So wait. Am I running in `targeted` or `strict` mode? What about MLS/MCS? Umm... yes.

```
$ sudo sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             default
Current mode:                   permissive
Mode from config file:          permissive
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Max kernel policy version:      29
```

So evidently MLS and MCS are enabled, and the policy name is just `default`. It sure as hell isn't targeted, because my
display manager shouldn't be crashing with a `targeted` policy: the `targeted` policy usually just runs on specific
network daemons, not on the entire system. Thereforce, I'm pretty sure that it's running in strict mode.

It's nice having MLS/MCS available, though.

# Next Steps

To get to an enforcing boot, it's going to take a lot of work. You'll have to make yourself a `staff_u` user, and be
able to use `staff_r`, possibly up to `sysadm_u` and `sysadm_r`. Additionally, you'll need to make sure that PAM logins
are configured properly.

# Why Not AppArmor?

In a word: because AppArmor isn't as secure as you think it is.

The reason why you want something like [AppArmor][apparmor], [SELinux][selinux], or [SMACK][smack] is because
discretionary access control is not enough. Discretionary access control is the typical Unix filesystem permissions we
all know and love. Ignoring ACLs and special setuid bits, there are three basic permissions on every filesystem object:
read, write, and execute. Directories implement read and execute a little differently, but they're intelligible enough
to figure out.

What's the problem with DAC? The problem is that any user can take files owned by them and make them available to
everyone else on the machine: `chmod -R 0777 $HOME`. Don't you _ever_ do something like that. If any process on the
machine gets compromised, they can get to these files, even if there's no reason that they should. Don't do it.

Mandatory-access-control means that policies can be defined at the system level and can prevent `chown -R 0777 $HOME`
from being so dangerous. Processes can be contained and their access limited.

SELinux and AppArmor are both [Linux Security Modules][lsm] which allow you to enforce mandatory access control.
The problem is that AppArmor lies about being a MAC implementation.

## Lies and Heresy, You Say?

Yes. AppArmor exists _on-demand_, meaning that it only enforces security for the applications you define it for.
SELinux, on the other hand, in strict mode will enforce mandatory access control for _everything_. By labeling the
filesystem, users, ports, and processes, everything has a context and is limited in its ability to do bad things. In
strict mode, you can't just bind to a named service port, even if it's above 1024. SELinux knows about these ports and
won't let you.

In AppArmor, on the other hand, security is only enforced when there's a policy defined for the specific program
executing. Security can be circumvented by renaming the program. Copy `/usr/bin/firefox` to `$HOME/fearfox`, and
AppArmor is out of the picture. SELinux in strict mode will most likely take severe issue with this.

# Conclusion

It'll take you a lot of time and experimentation, but SELinux on Ubuntu is possible. After 7 years of Ubuntu, this
might just be the straw that breaks the camel's back. I've [looked into Gentoo][post-gentoo], thought about Arch, and I think I might
just be going to Fedora, where SELinux is a first-class citizen.

 [selinux]: https://en.wikipedia.org/wiki/Security-Enhanced_Linux
 [apparmor]: https://en.wikipedia.org/wiki/AppArmor
 [smack]: https://en.wikipedia.org/wiki/Smack_(software)
 [lsm]: https://en.wikipedia.org/wiki/Linux_Security_Modules

 [post-gentoo]: /2015/12/why-you-dont-want-gentoo/

 [gif-good-luck]: /images/2015-12-24-selinux-on-ubuntu/good-luck.gif
 [gif-gonna-need-it]: /images/2015-12-24-selinux-on-ubuntu/gonna-need-it.gif
 [gif-dangerous]: /images/2015-12-24-selinux-on-ubuntu/dangerous.gif
 [gif-boogie]: /images/2015-12-24-selinux-on-ubuntu/boogie.gif

 [img-fyeah]: /images/2015-12-24-selinux-on-ubuntu/fyeah.jpg
