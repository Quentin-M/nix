Vagrant.configure("2") do |config|
  config.vm.define "ubuntu" do |a|
    a.vm.box = "ubuntu/jammy64"
    if Vagrant::Util::Platform.darwin?
      a.vm.box = "net9/ubuntu-24.04-arm64"
    end

    a.vm.network :private_network, ip: "192.168.60.2"
    a.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--cpus", 4]
      v.customize ["modifyvm", :id, "--memory", 2048]
      v.customize ["modifyvm", :id, "--name", "nixbuntu"]
    end

    config.vm.synced_folder ".", "/home/vagrant/.config/nixpkgs", owner: "vagrant"
    config.ssh.forward_agent = true

    # Provisioning
    #
    # In case the VBoxGuestAdditions are not pre-installed (esp. given the very few ubuntu vbox arm64 images), they may be installed them with the following commands:
    #   vagrant ssh-config > /Users/mentalow/.config/nixpkgs/.vagrant/machines/ubuntu/virtualbox/ssh_config
    #   rsync -avH -e "ssh -F .vagrant/machines/ubuntu/virtualbox/ssh_config" /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso ubuntu:/tmp 
    #   vagrant ssh -c "sudo mount -o loop /tmp/VBoxGuestAdditions.iso /mnt && sudo /mnt/VBoxLinuxAdditions-arm64.run && mount -a"
    a.vm.provision "shell", inline: <<-SHELL
      cd /home/vagrant/.config/nixpkgs
      make install
      make switch
    SHELL
  end
end

