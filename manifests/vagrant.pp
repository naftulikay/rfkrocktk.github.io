node 'vagrant-trusty64' {
    package { 'build-essential':
        ensure => present,
    }

    package { 'ruby2.0':
        ensure => present,
    }

    package { 'ruby2.0-dev':
        ensure => present,
    }

    package { 'git':
        ensure => present,
    }
}
