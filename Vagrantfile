# vi: set ft=ruby :

Vagrant.configure("2") do |config|
   config.vm.box = "ubuntu12.04.3"
   config.vm.box_url = "http://nitron-vagrant.s3-website-us-east-1.amazonaws.com/vagrant_ubuntu_12.04.3_amd64_virtualbox.box"
   config.vm.network :private_network, ip: "192.168.50.4"
#   config.vm.network :forwarded_port, guest: 80, host: 8080
   config.vm.provision :shell, :path => "install.sh"
   config.vm.synced_folder "../", "/home/vagrant/tsuru_projects"
end
