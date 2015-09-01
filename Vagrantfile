# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "phusion/ubuntu-14.04"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"

  # Machine hostname
  config.vm.hostname = "vagrant-trusty64"

  # Fix for "is not a TTY" bug
  config.ssh.pty = true

  # Configure VirtualBox
  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true

      # Customize the amount of memory on the VM:
      vb.memory = "1024"

      # Use the host's NAT DNS resolver
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Configure one-off Puppet upgrade shell provisioner
  config.vm.provision :shell, run: "once",
    inline: "echo Upgrading Puppet... && apt-get update &>/dev/null && apt-get install -y puppet &>/dev/null"

  # Configure Puppet Provisioning
  config.vm.provision :puppet do |puppet|
    puppet.hiera_config_path = "conf/hiera/hiera.yml"
    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.manifest_file = "vagrant.pp"

    if ENV.key("PUPPET_OPTS")
      puppet.options = ENV['PUPPET_OPTS'].split(' ')
    end

    puppet.facter = {
      "fqdn"       => "vagrant-trusty64.local",
      "is_vagrant" => true,
    }
  end

  # Enable cachier to cache DEBs and Ruby gems.
  if Vagrant.has_plugin?("vagrant-cachier")
      # Set the caching scope to be shared across instances of this box
      config.cache.scope = :box

      # Enable specific providers
      config.cache.enable :apt
      config.cache.enable :gem
  end
end
