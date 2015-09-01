node 'vagrant-trusty64' {
    package { 'build-essential':
        ensure => present,
    }

    package { 'git':
        ensure => present,
    }

    package { 'nodejs':
        ensure => present,
    }

    class { '::ruby':
        version => '2.2.0',
    }

    package { 'bundler':
        ensure   => present,
        provider => 'gem',
    }

    exec { 'bundler_install':
        command => 'bundler install',
        path    => '/usr/local/bin:/usr/bin:/bin',
        cwd     => '/vagrant',
        user    => 'vagrant',
        require => [
            Package['bundler'],
            Package['nodejs'],
        ],
    }

    Class['::ruby'] -> Package <| provider == 'gem' |>

    class { '::nginx': }

    nginx::resource::upstream { 'jekyll':
        members => ['localhost:4000']
    }

    nginx::resource::vhost { 'default':
        server_name => ['_'],
        proxy       => 'http://jekyll',
    }

    class { '::supervisord':
        install_pip => true,
    }

    supervisord::program { 'jekyll':
        command         => 'bundler exec jekyll serve',
        user            => 'vagrant',
        directory       => '/vagrant',
        autostart       => true,
        autorestart     => true,
        redirect_stderr => true,
        require         => [
            Package['nodejs'],
            Exec['bundler_install'],
        ]
    }
}
