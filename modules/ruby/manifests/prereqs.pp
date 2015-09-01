class ruby::prereqs () {

    include stdlib

    if (
        ($::operatingsystem == 'Ubuntu') or
        ($::operatingsystem == 'Debian')
    ) {

        #
        #  'gdbm-devel'
        #  'bison'
        #
        $deps = [
            'build-essential',
            'curl',
            'gcc',
            'libcurl4-openssl-dev',
            'libffi-dev',
            'libreadline6-dev',
            'libssl-dev',
            'make',
            'openssl',
            'zlib1g-dev'
        ]

    } elsif ($::operatingsystem == 'Centos') {

        $deps = [
            'bison',
            'curl',
            'gcc',
            'gdbm-devel',
            'libffi-devel',
            'make',
            'openssl-devel',
            'readline-devel',
            'zlib-devel'
        ]

    }

    ensure_packages($deps)

}
