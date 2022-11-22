#!/bin/bash
#created by imxcai <imxcai@gmail.com>

export API_ADDR=10.0.0.10
export POD_CIDR=172.16.0.0/16
export KUBE_VERSION=v1.25.4

echo "TASK[1]: install k8s cluster"
sudo kubeadm init --kubernetes-version=${KUBE_VERSION} \
	--image-repository registry.aliyuncs.com/google_containers \
	--apiserver-advertise-address=${API_ADDR} \
	--pod-network-cidr=${POD_CIDR}

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "TASK[2]: configure config file for vagrant user"
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

echo "TASK[3]: configure kubelet completion"
echo 'source <(kubectl completion bash)' >>/home/vagrant/.bashrc
echo 'alias k=kubectl' >>/home/vagrant/.bashrc
echo 'complete -o default -F __start_kubectl k' >>/home/vagrant/.bashrc

echo "TASK[4]: create join.sh"
kubeadm token create --print-join-command > /vagrant/join.sh
chmod +x /vagrant/join.sh

echo "TASK[5]: Control plane node isolation"
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "TASK[6]: install calico pod network add-on"
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/calico.yaml -O
kubectl apply -f calico.yaml
