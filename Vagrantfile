# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # No need to define network names; Vagrant will manage them
  
  # WEB01 - Ubuntu 20.04 with dual NICs
  config.vm.define "web01" do |web01|
    web01.vm.box = "ubuntu/focal64"
    web01.vm.hostname = "web01"
    
    # NIC 1: external network (192.168.1.0/24) - host‑only so attacker can reach
    web01.vm.network "private_network", ip: "192.168.1.10",
      auto_config: true
    
    # NIC 2: internal network (10.0.20.0/24) - internal network (isolated)
    web01.vm.network "private_network", ip: "10.0.20.10",
      virtualbox__intnet: "internal_network",
      auto_config: true
    
    # Sync tools directory for easy file transfer
    web01.vm.synced_folder "./tools", "/vagrant/tools"
    
    # Provisioning script
    web01.vm.provision "shell", path: "web01/bootstrap.sh"
    
    # Provider-specific settings
    web01.vm.provider "virtualbox" do |vb|
      vb.name = "web01"
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    end
  end

  # DC - Windows Server 2019
  config.vm.define "dc" do |dc|
    dc.vm.box = "StefanScherer/windows_2019"
    dc.vm.hostname = "dc"
    dc.vm.communicator = "winrm"
    
    # NIC: internal network only
    dc.vm.network "private_network", ip: "10.0.20.5",
      virtualbox__intnet: "internal_network",
      auto_config: true
    
    # Sync tools directory
    dc.vm.synced_folder "./tools", "C:/vagrant/tools"
    
    # Provisioning script
    dc.vm.provision "shell", path: "dc/bootstrap.ps1",
      privileged: false,
      args: "-ExecutionPolicy Bypass"
    
    # Provider settings
    dc.vm.provider "virtualbox" do |vb|
      vb.name = "dc"
      vb.memory = 4096
      vb.cpus = 2
      vb.gui = true  # Show GUI for AD configuration
    end
  end

  # WORKSTATION - Windows 10
  config.vm.define "workstation" do |ws|
    ws.vm.box = "StefanScherer/windows_10"
    ws.vm.hostname = "workstation"
    ws.vm.communicator = "winrm"
    
    # NIC: internal network only
    ws.vm.network "private_network", ip: "10.0.20.20",
      virtualbox__intnet: "internal_network",
      auto_config: true
    
    # Sync tools directory
    ws.vm.synced_folder "./tools", "C:/vagrant/tools"
    
    # Provisioning script
    ws.vm.provision "shell", path: "workstation/bootstrap.ps1",
      privileged: false,
      args: "-ExecutionPolicy Bypass"
    
    # Provider settings
    ws.vm.provider "virtualbox" do |vb|
      vb.name = "workstation"
      vb.memory = 3072
      vb.cpus = 2
      vb.gui = true
    end
  end
end