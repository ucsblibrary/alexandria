# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # Vagrant configuration options are fully documented at
  # https://docs.vagrantup.com.

  config.vm.box = 'centos7'

  config.vm.network 'forwarded_port', guest: 80, host: 8484 # apache
  config.vm.network 'forwarded_port', guest: 8080, host: 2424 # tomcat

  # Provider-specific configuration for VirtualBox:
  config.vm.provider 'virtualbox' do |vb|
    # Display the VirtualBox GUI when booting the machine?
    vb.gui = false
    # Customize the amount of memory on the VM:
    vb.memory = 2048
    vb.cpus = 2
  end

  # Enable provisioning with Ansible
  config.vm.provision 'ansible' do |ansible|
    ansible.verbose = 'vv'
    ansible.playbook = 'ansible/adrl.yml'
    ansible.raw_arguments = %w(--ask-vault-pass -e @ansible/dev_vars.yml)
  end
end
