# To install stdlib module run:
# sudo puppet module install puppetlabs-stdlib
#

include stdlib

class { ubuntu: stage => setup }

class { ruby: }
