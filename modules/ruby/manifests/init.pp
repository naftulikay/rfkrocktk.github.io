# Class: ruby
#
# This class installs ruby compiling it from sources
#
# Paremeters:
#
#   $version - the version as denoted in source filename
#
#

class ruby (
    $version    = '2.2.0',
    $with_clean = true
) {

    # validate_platform() function comes from
    # puppet module gajdaw/diverse_functions
    #
    #     https://forge.puppetlabs.com/gajdaw/diverse_functions
    #
    if !validate_platform($module_name) {
        fail("Platform not supported in module '${module_name}'.")
    }

    validate_re(
        $version,
        '^\d+\.\d+\.\d+(-p\d+)?$',
        'Required format of version parameter: "^\d+\.\d+\.\d+(-p\d+)?$"!'
    )

    validate_bool($with_clean)

    Exec { path => [
        '/usr/local/sbin',
        '/usr/local/bin',
        '/usr/sbin',
        '/usr/bin',
        '/sbin',
        '/bin'
    ]}

    $minor_version = inline_template('<%= @version.slice(/^\d+\.\d+/) -%>')

    class { 'ruby::prereqs': }

    exec { 'ruby::cached::get':
        command => "wget -N -P /var/cache/wget ftp://ftp.ruby-lang.org/pub/ruby/${minor_version}/ruby-${version}.tar.gz",
        onlyif  => "test ! -f /var/cache/wget/ruby-${version}.tar.gz",
        require => Class['ruby::prereqs'],
    }

    exec { 'ruby::cached::extract':
        command => "tar zxf /var/cache/wget/ruby-${version}.tar.gz -C /tmp",
        onlyif  => "test ! -d /tmp/ruby-${version}.tar.gz",
        require => Exec['ruby::cached::get'],
    }

    exec { 'ruby::configure':
        command => "/tmp/ruby-${version}/configure --disable-install-rdoc",
        cwd     => "/tmp/ruby-${version}",
        unless  => "ruby --version | grep -q 'ruby ${version}'",
        require => Exec['ruby::cached::extract'],
    }

    exec { 'ruby::make':
        command => 'make',
        cwd     => "/tmp/ruby-${version}",
        unless  => "ruby --version | grep -q 'ruby ${version}'",
        timeout => 6000,
        require => [Exec['ruby::configure']],
    }

    exec { 'ruby::install':
        command => 'make install',
        cwd     => "/tmp/ruby-${version}",
        unless  => "ruby --version | grep -q 'ruby ${version}'",
        require => [Exec['ruby::make']],
    }

    if $with_clean {
        exec { 'ruby::clean':
            command => "rm -rf /tmp/ruby-${version}",
            unless  => "ruby --version | grep -q 'ruby ${version}'",
            require => [Exec['ruby::install']],
        }
    }

}
