#!/bin/bash -eu

# Copyright 2014 tsuru authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

host_ip=192.168.50.4

echo Installing curl
apt-get update
apt-get install curl -qqy

echo Installing apt-add-repository
apt-get install python-software-properties -qqy

echo Adding Docker repository
curl https://get.docker.io/gpg | apt-key add -
echo "deb http://get.docker.io/ubuntu docker main" | sudo tee /etc/apt/sources.list.d/docker.list

echo Adding Tsuru repository
apt-add-repository ppa:tsuru/lvm2 -y
apt-add-repository ppa:tsuru/ppa -y

echo Adding MongoDB repository
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" | sudo tee /etc/apt/sources.list.d/mongodb.list

echo Installing MongoDB
apt-get update
apt-get install mongodb-10gen -qqy

echo Installing remaining packages
apt-get update
apt-get install screen mercurial git bzr lxc-docker beanstalkd redis-server node-hipache gandalf-server -qqy

echo Starting hipache
start hipache

echo Configuring and starting Docker
echo -e "\nexport DOCKER_HOST=127.0.0.1:4243" >> .bashrc
sed -i.old -e 's;-d;-d -H tcp://127.0.0.1:4243;' /etc/init/docker.conf
rm /etc/init/docker.conf.old
stop docker
start docker

echo Installing bare-template for Gandalf repositories
hook_dir=/home/git/bare-template/hooks
mkdir -p $hook_dir
curl https://raw.github.com/globocom/tsuru/master/misc/git-hooks/post-receive -o ${hook_dir}/post-receive
chmod +x ${hook_dir}/post-receive
chown -R git:git /home/git/bare-template

echo Configuring Gandalf
cp /vagrant/gandalf.conf /etc/gandalf.conf
sed -i.old -e "s/{{{HOST_IP}}}/${host_ip}/" /etc/gandalf.conf

echo Starting Gandalf
start gandalf-server

echo Starting git-daemon
start git-daemon

echo Configuring and starting beanstalkd
cat > /etc/default/beanstalkd <<EOF
BEANSTALKD_LISTEN_ADDR=127.0.0.1
BEANSTALKD_LISTEN_PORT=11300
DAEMON_OPTS="-l \$BEANSTALKD_LISTEN_ADDR -p \$BEANSTALKD_LISTEN_PORT -b /var/lib/beanstalkd"
START=yes
EOF
service beanstalkd start

echo Installing python platform
curl -OL https://raw.github.com/globocom/tsuru/master/misc/platforms-setup.js
mongo tsuru platforms-setup.js

echo Configuring GO
VAGRANT_HOME=/home/vagrant
GOPATH=$VAGRANT_HOME/go
PATH=$GOPATH/bin:$PATH
sudo -u vagrant echo -e "\nexport GOPATH=$VAGRANT_HOME/go\nexport PATH=$GOPATH/bin:$PATH" >> .bashrc
curl -O https://godeb.s3.amazonaws.com/godeb-amd64.tar.gz
tar -zxpvf godeb-amd64.tar.gz
./godeb install

echo Configuring Tsuru
mkdir -p /etc/tsuru
cp /vagrant/tsuru.conf $/etc/tsuru/tsuru.conf
sed -i.old -e "s/{{{HOST_IP}}}/${host_ip}/" $/etc/tsuru/tsuru.conf
rm $/etc/tsuru/tsuru.conf.old

echo Building Tsuru
sudo -u vagrant mkdir -p $GOPATH/src/github.com/globocom
sudo -u vagrant ln -s $VAGRANT_HOME/tsuru_projects/tsuru $GOPATH/src/github.com/globocom/tsuru
sudo -E -u vagrant go get github.com/globocom/tsuru/cmd/tsr

echo Exporting TSURU_HOST AND TSURU_TOKEN env variables
token=$($GOPATH/bin/tsr token)
echo -e "export TSURU_TOKEN=$token\nexport TSURU_HOST=http://127.0.0.1:8080" | sudo -u git tee -a ~git/.bash_profile

echo Running Tsuru
sudo -u vagrant yes | ssh-keygen -t rsa -b 4096 -N "" -f $VAGRANT_HOME/.ssh/id_rsa
su - vagrant -c "/vagrant/tsr-screen.sh"
