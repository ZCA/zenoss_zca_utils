# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant Configuratoin Files for Building Zenoss Build Servers
# On Various Platforms
# Some nice basebox templates: http://vagrant.sensuapp.org/list

Vagrant::Config.run do |config|
  #Configure a Cento
  config.vm.define :centos5 do |centos5_config|
    centos5_config.vm.box = "centos5"
	config.vm.host_name = "centos5"
    centos5_config.vm.forward_port 8080, 5080
    centos5_config.vm.boot_mode = :headless #(gui or headless)
    centos5_config.vm.box_url = "http://dl.dropbox.com/u/8072848/centos-5.7-x86_64.box"
    centos5_config.vm.customize ["modifyvm", :id, "--memory", 2048]
	centos5_config.vm.customize ["modifyvm", :id, "--cpus", 2]
  end
  config.vm.define :centos6 do |centos6_config|
    centos6_config.vm.box = "centos6"
	config.vm.host_name = "centos6"
    centos6_config.vm.forward_port 8080, 6080
    centos6_config.vm.boot_mode = :headless #(gui or headless)
    centos6_config.vm.box_url = "http://dl.dropbox.com/u/9227672/CentOS-6.0-x86_64-netboot-4.1.6.box"
    centos6_config.vm.customize ["modifyvm", :id, "--memory", 2048]
	centos6_config.vm.customize ["modifyvm", :id, "--cpus", 2]
  end
  config.vm.define :ubuntu10 do |ubuntu10_config|
    ubuntu10_config.vm.box = "ubuntu10"
	config.vm.host_name = "ubuntu10"
    ubuntu10_config.vm.forward_port 8080, 10080
    ubuntu10_config.vm.boot_mode = :headless #(gui or headless)
    ubuntu10_config.vm.box_url = "http://files.vagrantup.com/lucid64.box"
    ubuntu10_config.vm.customize ["modifyvm", :id, "--memory", 2048]
	ubuntu10_config.vm.customize ["modifyvm", :id, "--cpus", 2]
  end
  config.vm.define :ubuntu11 do |ubuntu11_config|
    ubuntu11_config.vm.box = "ubuntu11"
	config.vm.host_name = "ubuntu11"
    ubuntu11_config.vm.forward_port 8080, 11080
    ubuntu11_config.vm.boot_mode = :gui #(gui or headless)
    ubuntu11_config.vm.box_url = "http://timhuegdon.com/vagrant-boxes/ubuntu-11.10.box"
    ubuntu11_config.vm.customize ["modifyvm", :id, "--memory", 2048]
	ubuntu11_config.vm.customize ["modifyvm", :id, "--cpus", 2]
  end
  config.vm.define :ubuntu12 do |ubuntu12_config|
    ubuntu12_config.vm.box = "ubuntu12"
	config.vm.host_name = "ubuntu12"
    ubuntu12_config.vm.forward_port 8080, 12080
    ubuntu12_config.vm.boot_mode = :headless #(gui or headless)
    ubuntu12_config.vm.box_url = "http://vagrant.sensuapp.org/ubuntu-1204-amd64.box"
    ubuntu12_config.vm.customize ["modifyvm", :id, "--memory", 2048]
	ubuntu12_config.vm.customize ["modifyvm", :id, "--cpus", 2]
  end
end
