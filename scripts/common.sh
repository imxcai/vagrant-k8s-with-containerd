#!/bin/bash
#created by imxcai <imxcai@gmail.com>

#set env
export CONTAINERD_VERSION=1.6.10
export RUNC_VERSION=v1.1.4
export CNI_PLUGINS_VERSION=v1.1.1
export KUBE_VERSION=1.25.4



echo "TASK[1]: configure system"
echo "TASK[1.1]: upgrade system"
sudo sed -i 's/us.archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
sudo apt-get update
sudo apt-get upgrade -y

echo "TASK[1.2]: disable swap"
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

echo "TASK[1.3]: configure kenerl module and sysctl"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl -p /etc/sysctl.d/k8s.conf

echo "TASK[2]: install and configure container Runtime"
echo "TASK[2.1]: install containerd version: $CONTAINERD_VERSION"
if [ ! -f /vagrant/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz ];then
	curl -o /vagrant/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz https://github.com/containerd/containerd/releases/download/${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz;
fi
sudo tar Cxzvf /usr/local /vagrant/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

echo "TASK[2.2]: install runc version $RUNC_VERSION"
if [ ! -f /vagrant/runc.amd64 ];then
	curl -o /vagrant/runc.amd64 https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.amd64
fi
sudo install -m 755 /vagrant/runc.amd64 /usr/local/sbin/runc

echo "TASK[2.3] install CNI plugin"
if [ ! -f /vagrant/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz ];then
	curl -o /vagrant/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz
fi
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin /vagrant/cni-plugins-linux-amd64-${CNI_PLUGINS_VERSION}.tgz

echo "TASK[2.4]: configure systemd cgroup drive and pause"
sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo sed -i 's/registry.k8s.io/registry.aliyuncs.com\/google_containers/g' /etc/containerd/config.toml

echo "TASK[2.5]: configure containerd systemd unit"
if [ ! -f /vagrant/containerd.service ];then
	curl -o /vagrant/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
fi
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp /vagrant/containerd.service /usr/local/lib/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

echo "TASK[2.6] configure crictl.yaml"
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

echo "TASK[3]: install k8s packages"
echo "TASK[3.1]: configure apt repository"
sudo apt-get install -y apt-transport-https

curl  https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubenetes.list
deb https://mirrors.ustc.edu.cn/kubernetes/apt/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-get install -y kubeadm=${KUBE_VERSION}-00 kubelet=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
sudo apt-mark hold kubeadm kubelet kubectl
