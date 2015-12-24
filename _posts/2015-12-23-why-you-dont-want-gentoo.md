---
layout: post
title: Why You Don't Want Gentoo
tags: linux, gentoo, security
---

[Gentoo][gentoo] has a lot of curb appeal. At first glance, it offers a lot of incredibly powerful features, is
incredibly configurable, and seems to be able to do just about anything you'd ever want it to do. It checks a lot of my
boxes, but unfortunately falls short on a few critical features that any modern Linux distribution should have.

[[toc]]

# An Excellent From-Source Distro

Don't get me wrong, when I first grokked the idea of Gentoo, I was like

![woah][gif-woah]

Think about the possibilities. Before you do, don't be a [Gentoo Ricer][gentoo-is-for-ricers]: the _performance_
increases you get will likely get are pretty insignificant.

## Security

On the other hand, the _security_ implications are awesome:

 * PGP-signed install media.
 * PGP-signed stage 3 tarballs to start from.
 * PGP-signed packages like most distros.
 * [Gentoo Hardened][gentoo-hardened]:
    * [Security-critical compiler and linker flags on everything][cflags].
    * [Position Independent Code and Executables][pie-and-pic].
    * [PaX][pax] and advanced ASLR, which isn't available in the mainline kernel.
    * [GrSecurity][grsecurity] patches for ridiculous kernel hardening.
 * [SELinux][selinux]:
    * Pretty up-to-date maintained policies for most things that you'd install.
    * `targeted`, `strict`, and even `mcs`+`mls` modes.

## Custom Software

Also, since you're compiling _everything_, including the kernel, you can configure _everything_ to your liking.
Normally, compiling software on a binary distribution like Fedora or Ubuntu is a sucky process at best, and if you want
a stable system like an Ubuntu LTS release, you're going to have a bad time.

I'm on Ubuntu 14.04 LTS and my version of [OpenVPN][openvpn], from 2014, mind you, _doesn't support TLS 1.1 or 1.2_.
Pretty astounding if you ask me. [FFMPEG][ffmpeg] has started shipping in later versions of Ubuntu, but what if it
doesn't have the codecs you want or need?

 1. Find the source code.
 2. Try to verify it, hoping that there's some PGP signatures out there.
 3. Download it.
 4. Read docs on how to build it.
 5. Figure out what configure options you need.
 6. Get stuck, find incompatible local library versions.
 7. Give up.

Not so on Gentoo. Here's how you install a custom FFMPEG on Gentoo:

 1. Open up `/etc/portage/package.use/ffmpeg` in an editor and paste the following:   
     ```
     media-video/ffmpeg x265 openssl faac snappy
     ```
 2. Install it:
    ```
    emerge -aq media-video/ffmpeg
    ```

![yes][gif-yes]

Now, you're playing with power.

# So Why Not?

With all of these awesome features, why not Gentoo?

In three words: __automated security updates__. In Gentoo, everything is so DIY that if you want some semblance of
automated security updates, you're gonna need to do it yourself.

![egads][gif-egads]

But wait: it can't be _that_ bad. I mean, surely there's _some_ way to just apply incremental security-only patches to
your system, right?

You could whip up a cron job. Don't forget to install a cron provider, as Gentoo doesn't come with that by default. Oh,
and don't forget to install a system logger if you haven't done that: a stage3 doesn't come with that either. Okay,
now that we have the software we need, how hard could it be?

Impossible. That's how hard.

![mind blown][gif-mind-blown]

The problem is, you can't just update your packages for security related patches only. You're going to have to `emerge`
the world, and _everything_ will get upgraded. Prepare your system for breakage.

A lot of the work done by distributions like Ubuntu and Fedora is in backporting security fixes and pinning a given
distribution release to a specific minor version of a package. For example, the kernel image in Ubuntu follows a
specific kernel major and minor version like `3.19` or `4.2`. When security updates come down the tubes, they update
the package version with a fourth field, the packaging version. Therefore, you get packages named like this:

 * `linux-image-4.2.0-22-generic`
 * `linux-image-4.2.0-23-generic`

Nothing has changed in the kernel, but the packaging version has been updated because security fixes have been
backported into the kernel package.

With Gentoo, there's no notion of this kind of patching, so when it comes to security updates, you're on your own. On
Ubuntu or Fedora, you can set a cron job every 15 minutes to update the package repositories and automatically install
all security updates. There's no real way to do this in Gentoo without unintended consequences.
Yes, [really][gentoo-security]:

![proof][img-gentoo-security]

In text:

> To stay up-to-date with the security fixes you should subscribe to receive GLSAs and apply GLSA instructions whenever
> you have an affected package installed. Alternatively, syncing your portage tree and **upgrading every package**
> should also keep you up-to-date security-wise.

Emphasis mine. These are your options:

 1. Subscribe to a mailing list and go manually apply security patches whenever one drops.
 2. Sync the repository and upgrade **every** package, hoping that your system doesn't break.

![ain't nobody got time for that][gif-nobody-got-time]

Sorry, but [ain't nobody got time for that][yt-nobody-got-time].

## The Dealbreaker

The lack of automated security updates is a deal-breaker for me with Gentoo. All of the hardening and MAC isn't going to
protect you if you don't get automated package updates.

Case-in-point: OpenSSH. OpenSSH had a [number of CVEs posted recently][openssh-cves] which wouldn't have been stopped by
good hardening or by SELinux. Since OpenSSH is supposed to give shells to valid logins, SELinux allows it to do that. If
a software vulnerability can allow someone to gain a shell, they're in. At that point, you hope and pray that your due
diligence will help prevent an attacker from staging a kernel exploit on the machine. GrSecurity, SELinux, and PaX/ASLR
will make the attacker's job more difficult, but all of this could have been prevented by a simple security patch and
a restart of the daemon.

# Addendum: I Have a Life

There were about four phases of Gentoo for me:

 1. Denial: Hey, I'll run this on my desktop machines!
 2. Bargaining: Meh, it takes a lot of time to do things, I'll run it on my servers!
 3. Testing: Oh, security updates. Maybe I'll run it on my Raspberry Pi?
 4. Acceptance: I'd also like security updates on my Raspberry Pi.

The other motivating factor for not settling on Gentoo was time. I can get Ubuntu installed on a fresh system in under
30 minutes. To install a stage 3, compile a kernel, and get booting on Gentoo is going to take at least a couple of
hours. At least. You're probably not a master of kernel configuration flags either, so it's going to take longer.
Hardly anything is turned on by default in either `sys-kernel/gentoo-sources` or `sys-kernel/hardened-sources`, so
you're going to have to go get lost in `make menuconfig`. Good luck with that.

# Until Next Time, Gentoo

![i'm out][gif-elsewhere]

Gentoo, I wanted to love you. I did love a lot about you actually, and I really wish it were possible to get some of
your features with whatever distribution I end up using.

 [gentoo]: https://gentoo.org
 [gentoo-is-for-ricers]: http://funroll-loops.info/
 [pie-and-pic]: https://wiki.gentoo.org/wiki/Hardened/Introduction_to_Position_Independent_Code
 [cflags]: https://wiki.gentoo.org/wiki/Hardened/FAQ#Do_I_need_to_pass_any_flags_to_LDFLAGS.2FCFLAGS_in_order_to_turn_on_hardened_building.3F
 [gentoo-hardened]: https://wiki.gentoo.org/wiki/Hardened_Gentoo
 [pax]: https://wiki.gentoo.org/wiki/Hardened/PaX_Quickstart
 [grsecurity]: https://wiki.gentoo.org/wiki/Hardened/Grsecurity2_Quickstart
 [selinux]: https://wiki.gentoo.org/wiki/SELinux
 [openvpn]: https://openvpn.net/
 [ffmpeg]: https://ffmpeg.org
 [gentoo-security]: https://www.gentoo.org/support/security/
 [yt-nobody-got-time]: https://www.youtube.com/watch?v=bFEoMO0pc7k
 [openssh-cves]: https://security.gentoo.org/glsa/201512-04

 [img-gentoo-security]: /images/2015-12-23-why-you-dont-want-gentoo/security-updates.png
 [gif-woah]: /images/2015-12-23-why-you-dont-want-gentoo/woah.gif
 [gif-yes]: /images/2015-12-23-why-you-dont-want-gentoo/yes.gif
 [gif-egads]: /images/2015-12-23-why-you-dont-want-gentoo/egads.gif
 [gif-mind-blown]: /images/2015-12-23-why-you-dont-want-gentoo/mind-blown.gif
 [gif-nobody-got-time]: /images/2015-12-23-why-you-dont-want-gentoo/aintnobodygottimeforthat.gif
 [gif-elsewhere]: /images/2015-12-23-why-you-dont-want-gentoo/elsewhere.gif
