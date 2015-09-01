# Puppet Module
# `gajdaw/ruby`

#### Table of Contents

1. [Overview](#overview)
2. [Setup](#setup)
3. [Usage](#usage)
4. [Limitations](#limitations)
5. [Development](#development)

## Overview

The module installs ruby compiling it from sources.

Sources are downloaded from:

    ftp://ftp.ruby-lang.org/pub/ruby/X.Y/ruby-X.Y.Z.tar.gz

The commands used to compile and install:

    $ cd ruby-X.Y.Z
    $ sudo ./configure --disable-install-rdoc
    $ sudo make
    $ sudo make install

The commands used to install dependencies:
- Ubuntu 14.04

    ```
    sudo apt-get update -y
    sudo apt-get install -y curl make
    sudo apt-get install -y zlib1g-dev libffi-dev
    sudo apt-get install -y openssl libssl-dev libcurl4-openssl-dev
    sudo apt-get install -y libreadline6-dev
    sudo apt-get install -y build-essential
    ```

## Setup

To install the module run:

    sudo puppet install module gajdaw-ruby

## Usage

You can use the module running the following command:

    sudo puppet apply -e 'include ruby'

You can also use the class in your manifests like this:

    include ruby

Remember that before applying `ruby` class your system needs to be
updated. You can do it using `gajdaw-ubuntu` and `puppetlabs-stdlib` classes:

    include stdlib
    class { ubuntu: stage => setup }
    class { ruby: }

The examples are located in `examples/` directory.

## Limitations

The module was tested on all the platforms that appear in `metadata.json`.

The results of tests are available in
[test-output.txt](https://github.com/puppet-by-examples/puppet-ruby/blob/master/test-output.txt) file.

###Procedure to test

**CAUTION**

Script:

    /etc/puppet/modules/puppet/update-puppet-ubuntu-with-facter.sh

comes from `gajdaw-puppet` Puppet module.
In order to use it you have to install the module:

    sudo puppet module install gajdaw-puppet

* Debian
    - 6.0 (squeeze) (Vagrant box: chef/debian-6.0.8)

    ```
    vagrant up
    sudo /etc/puppet/modules/puppet/update-puppet-with-param.sh squeeze
    sudo puppet apply /etc/puppet/modules/ruby/examples/default.pp
    ruby --version
    ```

* Ubuntu
    - 12.04 (precise) (Vagrant box: ubuntu/precise32)
    - 14.04 (trusty) (Vagrant box: ubuntu/trusty32)

    ```
    vagrant up
    sudo /etc/puppet/modules/puppet/update-puppet-ubuntu-with-facter.sh
    sudo puppet apply /etc/puppet/modules/ruby/examples/with-update.pp
    ruby --version
    ```

* CentOS
    - 6.5 (Vagrant box: puppetlabs/centos-6.5-64-puppet)

    ```
    vagrant up
    sudo puppet apply /etc/puppet/modules/ruby/examples/default.pp
    ruby --version
    ```

## Development

For development instructions visit
[Puppet Modules Factory](https://github.com/puppet-by-examples/puppet-modules-factory)
