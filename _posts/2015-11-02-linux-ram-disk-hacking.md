---
layout: post
title: "Linux RAM and Disk Hacking with ZRAM and BTRFS"
tags: btrfs, zram, hardware, ram, disk, linux, compression
---

At a recent job, I faced a pretty bleak situation: my MacBook Pro had only 8 gigabytes of RAM and only 256 gigabytes of
disk space. Because of "Apple Reasons™," you can no longer upgrade your disk or add more RAM to new MacBook Pros. On
top of all that, I wasn't supposed to uninstall OSX, even though I _only ever booted Linux._ That meant that my root
partition for my Linux install was only around 170 GB.

[[toc]]

# The Problem

![Wonka Meme][wonka-meme]

Anyone who seriously thinks this is enough RAM and disk _can leave now._ Go buy a Chromebook.

It was a desperate situation. I keep all of my HQ music collection on disk at all times, because I'm old-school like
that. Combine that with standard OS files, tons of Java artifacts in my local Maven repository, and I was quickly
running out of storage space.

Not only that, but I had to run and debug multiple 2GB monolithic Java applications, so there goes 4 of my 8 gigabytes
of RAM. In addition, because these applications required that your system be setup "just so™," I threw together a
[Vagrant][vagrant] VM to house them, so there's another 256MB of RAM to run the OS being used up while I worked. Oh,
and what about an IDE? Eclipse also gobbled up around 1.25GB of RAM, so now I was questioning whether I could even run
a _browser_ at the same time.

![What Year Is It!?][what-year-is-it-meme]

I even switched to _FIREFOX_ for a while. Firefox, as in the browser I left Internet Explorer for in the early 2000's.
And while Firefox is fast, I got incredibly used to my Chrome extensions and was unable to find good equivalents for
them in Firefox-land.

# But Wait, I Run Linux

[![XKCD Linux User][xkcd-linux-user]][xkcd-linux-user-comic]

At last, it dawned upon me. I don't have to put up with this! _I RUN LINUX._

# Hack your RAM with ZRAM

You know what'd be really awesome? What if, instead of swapping to disk, you could just run your least-recently-used
RAM through a compression algorithm? Turns out, [you can][zram].

On recent versions of Ubuntu (think 12.04 and later), a package is provided which automatically configures the ZRAM
virtual swap devices on system boot. On these systems, getting more RAM out of the same physical space is as easy as

```
sudo apt-get install zram-config
```

What this does is install a service script (or Upstart configuration) which mounts `n` swap points, where `n` is the
number of CPU cores, with each swap point having a size of `(r / 2)/n` megabytes, where `r` is the total system RAM
in megabytes. For my 8GB system with 4 CPUs (hyperthreading, but still), it created 4 ZRAM swap points, each with a size
of 1GB.

Depending on `vm.swappiness`, as soon as you start filling your RAM beyond a certain point, certain pages are compressed
and stored in the ZRAM virtual swap devices. When they are needed, they're decompressed and returned to a place in
regular non-swap memory. All of this is _transparent to you_ and you only suffer a slight CPU hit, because CPUs are
pretty good at compression algorithms.

Problem one: solved.

![Yeah][heavy]

# Hack your Disk with BTRFS

The next step isn't as easy as the first, but it's definitely worth it, provided you're on a fairly recent kernel. I
personally follow the latest `linux-image-generic-lts-vivid` kernel, which is kernel 3.19. As soon as [HWE][hwe] lands
from 15.10, I'll be happily running kernel 4.2. Run a recent kernel pls, BTRFS was marked stable in 3.10.

This step is primarily an install-time thing, but if you're not already on BTRFS as a root filesystem, you should
probably make it a priority for your next install. [BTRFS][btrfs] is _awesome_ and is similar in many ways to
[ZFS][zfs], featuring:

   * Copy-on-write snapshots and cloning
   * Subvolumes
   * Error correction and checksumming.
   * RAID support for multiple devices without requiring `mdadm` or LVM
   * On-the-fly compression

This last feature is what we're most interested in here. Personally, I do the following to create my root BTRFS
partition:

```
# make ze filesystem on an LVM LV
sudo mkfs.btrfs -L "Linux Root" /dev/mapper/vg-root
# now that it's made, mount it
sudo mkdir /mnt/root && \
    sudo mount -t btrfs -o defaults,compress=lzo /dev/mapper/vg-root /mnt/root
# create subvolumes for root and home
sudo btrfs subvolume create /mnt/root/@
sudo btrfs subvolume create /mnt/root/@home
```

What this does is:

 1. Create the root filesystem on an LVM LV with the label `Linux Root`.
 2. Mount it at `/mnt/root`, enabling compression using the `compress=lzo` mount option.
 3. Create a subvolume to be mounted at `/` with the name `@`.
 4. Create a subvolume to be mounted at `/home` with the name `@home`.

The reason I create these subvolumes is that it gives you a lot of flexibility. If I want to ever snapshot my home
directory, I can do that separately than the rest of the filesystem, meaning that I save a lot of space. On the flip
side, if I want to do a system snapshot, ignoring my home directory, I can do that too.

The reason for the subvolume naming is not well-understood: Ubuntu does this by default during installation if you
select BTRFS as your root filesystem.

## Choosing a Compression Algorithm

BTRFS ships with two compression algorithms, LZO and zlib. Here's a [quick comparison][btrfs-compression-opts] of the two:

<table>
  <thead>
    <tr>
      <th>Algorithm</th>
      <th>Pros &amp; Cons</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>LZO</td>
      <td>Better compression ratio, meaning your files will occupy a little less space on disk; the cost is higher CPU usage.</td>
    </tr>
    <tr>
      <td>zlib</td>
      <td>Lighter CPU usage during compression; less compression ratio as compared to LZO</td>
    </tr>
  </tbody>
</table>

Using compression will obviously slow down I/O a bit, so if I/O is your priority, <s>you should be reading another
post</s> don't use compression. My use-case is a desktop install with insufficient disk space, so compression is
necessary for me.

## One-Off Filesystem Compression Run

The `ubiquity` installer used by most Ubuntu derivatives _probably_ doesn't mount your BTRFS root filesystem with
compression enabled, so it's a good time to run a one-off compression over the entire filesystem:

```
sudo btrfs filesystem defragment -c lzo /
sudo btrfs filesystem defragment -c lzo /home
```

Make sure that your subvolumes are mounted at `/` and `/home` before running this, obviously. This operation will take
some time on an uncompressed filesystem, but subsequent runs will be faster.

## Compression Mount Options

As we did above, we're now going to make sure that our BTRFS volumes are mounted with the `compress` mount option
enabled. My `/etc/fstab` looks a little like this:

```
/dev/mapper/vg-root /      btrfs   defaults,ssd,compress=lzo,subvol=@       0   1
/dev/mapper/vg-root /home  btrfs   defaults,ssd,compress=lzo,subvol=@home   0   1
```

After this change, all writes will be compressed upon syncing to disk. Reads will decompress, and everything will run
pretty seamlessly.

If you want to get super-hacky, instead of mounting with compression options, you could simply run the above one-off
defragment commands with the compression options on a nightly basis, though you really don't need to; Linux already has
a pretty good I/O scheduler and writes are almost always asynchronous without a call to `sync()`.

## The Result: So Much More Storage

I've found that this BTRFS hack allows me to live within a measly 170GB of available disk space pretty efficiently.

If you're a supreme hacker and you want to test that compression works, try this out, making sure that [`pv`][pv] is
installed:

```
df -h /home
dd if=/dev/zero | pv | dd of=$HOME/massive.bin
```

Take note of the output of the first command and establish about how much free disk space you have left on your device.
Let the second process run until the file size exceeds your free disk space.

![Chris Farley's Panic Face][chris-farley-panic]

**EXCEED YOUR FREE DISK SPACE!?**

**Exactly.**

Now that you've got compression enabled, you can keep writing well past your disk space limit for a _long_
time. You're just writing a bunch of zeroes to disk, and the compression algorithm sees that and just keeps a count of
of those zeroes internally, allowing you to write an impossibly big file to disk.

# Conclusion

When you run Linux, you don't settle for less, and where there's a will, there's likely a <s>William</s> way. Now go
forth and use your previously unusable hardware. Run Chrome. Run VMs. Install things. Profit.

![Profit][profit]

 [wonka-meme]: /images/2015-11-02-linux-ram-disk-hacking/wonka-ram-and-disk-meme.jpg
 [what-year-is-it-meme]: /images/2015-11-02-linux-ram-disk-hacking/what-year-is-it.gif
 [vagrant]: https://vagrantup.com
 [xkcd-linux-user]: /images/2015-11-02-linux-ram-disk-hacking/xkcd-linux-user.png
 [xkcd-linux-user-comic]: https://xkcd.com/272/
 [zram]: https://en.wikipedia.org/wiki/Zram
 [hwe]: https://wiki.ubuntu.com/Kernel/LTSEnablementStack
 [btrfs]: https://en.wikipedia.org/wiki/Btrfs
 [zfs]: https://en.wikipedia.org/wiki/ZFS
 [btrfs-compression-opts]: https://docs.oracle.com/cd/E37670_01/E37355/html/ol_use_case1_btrfs.html
 [pv]: http://linux.die.net/man/1/pv
 [chris-farley-panic]: /images/2015-11-02-linux-ram-disk-hacking/chris-farley-panic.gif
 [profit]: /images/2015-11-02-linux-ram-disk-hacking/profit.gif
 [heavy]: /images/2015-11-02-linux-ram-disk-hacking/heavy-computer-nod.gif
