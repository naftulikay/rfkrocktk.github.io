---
layout: post
title: Managing sudoers in Ansible
tags: ansible, automation, linux
---

Ansible is awesome. You can automate _all the things_, which is a motto to live by.

![Automate ALL THE THINGS][img-automate-att]

Let's automate sudoers permissions. This operation is one of the more dangerous operations you can run in automation,
right after `dd` or `parted`, with a little less risk. If sudoers gets screwed up, you won't be able to gain root, and
that's a perfect way to ruin an otherwise good day.

Luckily, there is a sudoers validation tool called `visudo` as you probably know, and it happens to allow automated
validation like-a-so:

```
visudo -q -c -f filename
```

Ansible's [template module][ansible-template] allows us to call a script to validate our output file before moving it
into place. This makes managing sudoers pretty much bulletproof, as long as you don't push valid-yet-incorrect configuration.

As is pretty standard in Amazon Web Services, we're going to allow all users in group `adm` to have passwordless `sudo`
rights. We're also going to preserve the `SSH_AUTH_SOCK` environment variable in `sudo`, which
[can cause problems][post-rsync-as-root]. Here's our sudoers file we'll be installing:

```
# Preserve SSH_AUTH_SOCK env variable
Defaults env_keep+=SSH_AUTH_SOCK
# Allow users in group adm to gain sudo without password
%adm   ALL=(ALL:ALL) NOPASSWD: ALL
```

Now, here's where how we'll deploy it in Ansible, validating it for syntax:

```
- hosts: all
  tasks:
    - name: add admin sudoers
      template:
        src: conf/sudoers.d/adm
        dest: /etc/sudoers.d/adm
        mode: '0440'
        owner: root
        group: root
        validate: 'visudo -q -c -f %s'
```

This will generate a file from a local [Jinja 2][jinja] template on the destination host, then run the validation step,
and then finally move it into place. If it doesn't pass validation, _nothing happens_. The Ansible step will fail, and
you won't be locked out. Ansible saves the day again!

 [img-automate-att]: /images/2015-12-02-ansible-sudoers/automate-all-the-things.jpg
 [ansible-template]: https://docs.ansible.com/ansible/template_module.html
 [jinja]: http://jinja.pocoo.org/
 [post-rsync-as-root]: /2015/11/rsync-as-root/
