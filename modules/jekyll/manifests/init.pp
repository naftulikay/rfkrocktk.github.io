class jekyll {

    file { 'jekyll_builder_script':
        ensure => present,
        path   => '/usr/local/bin/jekyll-auto-builder',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        content => template('jekyll/jekyll-auto-builder.sh.erb'),
    }
}
