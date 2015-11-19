---
layout: post
title: rsync as root
tags: ssh, rsync, root, linux
---

It often happens, at least to me, that I need to synchronize a directory to another server while maintaining permissions
and original ownership. While `ssh root@box` is a _terrible idea™_, you can use some epic hacks to do what you need to,
securely.

I'll first start out by SSHing into the server I'll be grabbing files _from_:

```
ssh -o "ForwardAgent yes" naftuli@source
```

`ForwardAgent` is assumed to be necessary, because you're really not entering passwords, are you?

If you want to make this more permanent, add the following entry to `$HOME/.ssh/config`:

```
Host source
    ForwardAgent yes
```

Next, run the synchronization on `source` to `dest`:

```
rsync -azvP --rsync-path "sudo rsync" /path/to/deployment/ \
    naftuli@dest:/path/to/deployment/
```

This will use your current user _locally_ to grab the files and transfer them to the remote server. On the remote
server, `rsync` will run as `sudo rsync`, acquiring `root` for you without requiring you to directly SSH into the root
account, because that should seriously be disabled on your box.

This should work about 75% of the time, unless your current user doesn't have access to the files you'd like to send
over the network.

In that case, run `rsync` with `sudo`, passing in the `SSH_AUTH_SOCK` environment variable so that SSH will still be
able to use your agent to connect:

```
sudo SSH_AUTH_SOCK="$SSH_AUTH_SOCK rsync -azvP --rsync-path "sudo rsync" \
    /path/to/deployment/ \
    naftuli@dest:/path/to/deployment/
```

`rsync` will now acquire root locally to be able to read the unreadable, will SSH into the remote machine as `naftuli`,
acquire `root` using `sudo`, and then install the files with the permissions and ownership as expected.

The need for `SSH_AUTH_SOCK` in the command is because `sudo` [nukes environment variables][sudo-fix].

Throw this in your toolbox :)

 [sudo-fix]: https://stackoverflow.com/a/8636711/128967
