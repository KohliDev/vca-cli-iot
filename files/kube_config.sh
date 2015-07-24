#!/bin/bash

## Store the username used to login the system
#logonname=$(logname)

## Add this user to sudoers file
#sudo sed -i.bak "$ a $logonname ALL=NOPASSWD: ALL" /etc/sudoers

echo 'dns-nameservers 8.8.8.8' >> /etc/network/interfaces
ifdown eth0 && ifup eth0

apt-get update
printf "Checking and installing ssh... "
if ! apt-get install -y ssh; then
	printf "apt-get failed\n"
	exit 1
fi
printf "done\n"

if [ ! -e /root/.ssh/id_rsa.pub ]; then
	printf "\nSetting up passwordless ssh login\n"
	ssh-keygen -N '' -t rsa -f /root/.ssh/id_rsa >/dev/null
	# Should work with a fresh install.
	# TODO: Check if the hostname is already present in the authorized_keys file
	cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

else
	echo "Passwordless ssh setup done."
fi

##Add entry in the known_hosts file
ssh-keygen -R `hostname` 
ssh-keygen -R localhost
ssh-keygen -R `hostname`,localhost
ssh-keyscan -H `hostname`,localhost >> /root/.ssh/known_hosts
ssh-keyscan -H localhost >> /root/.ssh/known_hosts
ssh-keyscan -H `hostname` >> /root/.ssh/known_hosts

if [ x$1=x"precustomization" ];
then
mkdir -p /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQBRxivunsJGY/81nj9y+IsdWwm/c2dyYxpzamo1vgNg+i0VOtLx1Mbg23Zdmw44II94m9Py8o1O3J1OIqpgdM92r54jmJWriZrJnmeLdqbtG5+5JkhQB2l++YZI5lUz4brOUODK0Jf5salWbk+uFusk8ljlpxJcOzVJ9cYUlB5EwSNnDQLgOfudm1CdOGcf/ZPXkTjzNqRMXGMlkCdP/ANmeQHXGaZi3jFOwQPH2DD6SZTJpSRaO9ljHEr98hfhdEU52x0JrKB1gwiUlQeHHWRjEtl9drat7qixMd3w3Sixdl74cOZEVBmcvcysxYeT2vlIBeSBBRsHJmCclnRhxz root@master' >> /root/.ssh/authorized_keys
#chown ubuntu.ubuntu /root/.ssh
#chown ubuntu.ubuntu /root/.ssh/authorized_keys
chmod go-rwx /root/.ssh
chmod go-rwx /root/.ssh/authorized_keys

## Check whether packages are installed, if not install them
printf "Configuring kubernetes cluster\n"
printf "Checking for bridge-utils... "
if ! apt-get -s remove bridge-utils 2>&1 > /dev/null; then
	if ! apt-get install -y bridge-utils; then
		printf "apt-get failed\n"
		exit 1
	fi
fi
printf "done\n"

if ! apt-get install -y unzip; then
	printf "apt-get failed\n"
	exit 1
fi

printf "Checking for curl... "
if ! curl --version 2>&1 > /dev/null; then
	if ! apt-get install -y curl; then
		printf "apt-get failed\n"
		exit 1
	fi
fi
printf "done\n"

printf "Checking for git... "
if ! git --version 2>&1 > /dev/null; then
	if ! apt-get install -y git; then
		printf "apt-get failed\n"
		exit 1
	fi
fi
printf "done\n"

## Install docker as well, but it is installed by build.sh below
if ! wget -qO- https://get.docker.com/ | sh; then
	printf "wget docker failed\n"
	exit 1
fi
if ! docker run hello-world; then
	printf "error installing docker\n"
	exit 1
else
	printf "\n\nDocker installed successfully\n"
fi

## Clone the kubernetes repository from git
#if ! git clone http://github.com/GoogleCloudPlatform/kubernetes.git; then
#	printf "git failed\n"
#	exit 1
#fi

## If git is not working, workaround by downloading the master zip.
if ! test -e master.zip; then
	if ! wget -c https://github.com/GoogleCloudPlatform/kubernetes/archive/master.zip; then
		printf "wget failed\nPlease check internet connection\n"
		exit 1
	fi
fi
if ! test -d kubernetes; then
	unzip master.zip
	mv kubernetes-master kubernetes
	cd kubernetes/cluster/ubuntu
	if ! ./build.sh; then
		printf "./build.sh returned errors\n"
		exit 1
	fi
else
	cd kubernetes/cluster/ubuntu
fi

cd binaries
#Make sure that all the binaries are in place
FILE=kubectl
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=master/etcd
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=master/etcdctl
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=master/flanneld
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=master/kube-apiserver
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=master/kube-controller-manager
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=master/kube-scheduler
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=minion/kube-proxy
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=minion/kubelet
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=minion/flanneld
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=minion/etcdctl
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi
FILE=minion/etcd
if ! test -e $FILE; then
	echo $FILE not found
	exit 1
fi

echo All required files are present.
echo Houston, we are good to go.

echo using root
cd /root/kubernetes/cluster/ubuntu
if ! test -e config-default.sh.orig; then
	cp config-default.sh config-default.sh.orig
fi

#sed -i.bak "s/vcap@10.10.103.250 vcap@10.10.103.162 vcap@10.10.103.223/$logonname@localhost/" config-default.sh
sed -i.bak "s/vcap@10.10.103.250 vcap@10.10.103.162 vcap@10.10.103.223/root@localhost/" config-default.sh
sed -i.bak "s/ai i i/ai/" config-default.sh
sed -i.bak "s/NUM_MINIONS:-3/NUM_MINIONS:-1/" config-default.sh
sed -i.bak "s/SERVICE_CLUSTER_IP_RANGE:-192.168.3.0\/24/SERVICE_CLUSTER_IP_RANGE:-11.1.1.0\/24/" config-default.sh
sed -i.bak "s/192.168.3.10/11.1.1.10/" config-default.sh

cd ../
export KUBERNETES_PROVIDER=ubuntu
export PATH=$PATH:/root/kubernetes/cluster/ubuntu/binaries/
./kube-up.sh

#sudo sed -i.bak "s/$logonname ALL=NOPASSWD: ALL//" /etc/sudoers
