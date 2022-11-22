#created by imxcai <imxcai@gmail.com>
#updated: 20221121

Vagrant.configure("2") do |config|
  config.vm.synced_folder './', '/vagrant', type: 'nfs', nfs_udp: false, nfs_version: 4
  config.vm.provision "shell", inline: <<-SHELL
    echo "10.0.0.10 master01 master01.example.com" >> /etc/hosts
    echo "10.0.0.11 worker01 worker01.example.com" >> /etc/hosts
    echo "10.0.0.12 worker02 worker02.example.com" >> /etc/hosts
  SHELL

  config.vm.define "master01" do |master|
    master.vm.box = "generic/ubuntu2004"
    master.vm.hostname="master01.example.com"
    master.vm.network "private_network",ip: '10.0.0.10',
      libvirt__network_name: 'vagrant-lab'
    master.vm.provider "libvirt" do |kvm|
      kvm.memory = 8192
      kvm.cpus = 2
      kvm.uri = 'qemu:///system'
    end
    master.vm.provision "shell", path: "scripts/common.sh"
    master.vm.provision "shell", path: "scripts/master.sh"
  end

  (1..2).each do |i|
    config.vm.define "worker0#{i}" do |worker|
      worker.vm.box = "generic/ubuntu2004"
      worker.vm.hostname="worker0#{i}.example.com"
      worker.vm.network "private_network",ip: "10.0.0.1#{i}",
        libvirt__network_name: 'vagrant-lab'
      worker.vm.provider "libvirt" do |kvm|
        kvm.memory = 4096
        kvm.cpus = 2
        kvm.uri = 'qemu:///system'
      end
      worker.vm.provision "shell", path: "scripts/common.sh"
      worker.vm.provision "shell", path: "scripts/worker.sh"
    end
  end
end
