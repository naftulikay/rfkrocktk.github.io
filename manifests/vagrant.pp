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

    package { 'pygments':
        ensure => present,
        provider => 'pip',
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
    Exec['install_pip'] -> Package <| provider == 'pip' |>

    class { '::nginx': }

    nginx::resource::vhost { 'default':
        server_name => ['_'],
        www_root    => '/vagrant/_site',
        try_files   => ['$uri', '$uri/index.html', '$uri/', '=404'],
        vhost_cfg_prepend => {
            'server_name_in_redirect' => 'off',
            'port_in_redirect'        => 'on',
        },
        rewrite_rules => [
            # redirect everything ending in at least one slash to remove the slash,
            # respecting the scheme and the host header's value.
            '^/(.+)/+$ $scheme://$http_host/$1 permanent'
        ]
    }

    class { '::supervisord':
        install_pip => true,
    }

    class { '::jekyll': }

    supervisord::program { 'jekyll':
        command         => '/usr/local/bin/jekyll-auto-builder',
        user            => 'vagrant',
        directory       => '/vagrant',
        autostart       => true,
        autorestart     => true,
        redirect_stderr => true,
        require         => [
            Package['nodejs'],
            Exec['bundler_install'],
            Class['jekyll'],
        ]
    }
}
