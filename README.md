### Attempting to revive SocketPlane base project
Done:
Base components installable
Can start containers
Can download images

Next:
Same but copy and update the images to ubuntu 22.04
Update the dockerfiles and compose so I can use the current versions for security and ease of use

Later:
Complete the demo
Update vagrant files
Check out how the network layer is built

## Current steps to install:

#Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

```bash
#Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

VERSION_STRING=5:20.10.13~3-0~ubuntu-jammy
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

cd ./scripts/
chmod +x install.sh
sudo ./install.sh
```

#SocketPlane

[![Circle CI](https://circleci.com/gh/socketplane/socketplane/tree/master.svg?style=svg)](https://circleci.com/gh/socketplane/socketplane/tree/master) [![Coverage Status](https://img.shields.io/coveralls/socketplane/socketplane.svg)](https://coveralls.io/r/socketplane/socketplane) 

Developers don't want to care about VLANs, VXLANs, Tunnels or TEPs. People responsible for managing the infra expect it to be performant and reliable. SocketPlane provides a networking abstraction at the socket-layer in order to solve the problems of the network in a manageable fashion.

## SocketPlane Technology Preview

This early release is just a peek at some of the things we are working on and releasing to the community as open source. As we are working upstream with the Docker community to bring in native support for network driver/plugin/extensions, we received a number of request to try the proposed socketplane solution with existing Docker versions. Hence we came up with a temporary wrapper command : `socketplane` that is used as a front-end to the `docker` CLI commands. This enables us to send hooks to the SocketPlane Daemon.

In this release we support the following features:

- Open vSwitch integration
- ZeroConf multi-host networking for Docker
- Elastic growth of a Docker/SocketPlane cluster
- Support for multiple networks
- Distributed IP Address Management (IPAM)

Overlay networking establishes tunnels between host endpoints, and in our case, those host endpoints are Open vSwitch. The advantage to this scenario is the user doesn't need to worry about subnets/vlans or any other layer 2 usage constraints. This is just one way to deploy container networking that we will be presenting. The importance of Open vSwitch is performance and the defacto APIs for advanced networking.

Our 'ZeroConf' technology is based on [multicast DNS](http://en.wikipedia.org/wiki/Zero-configuration_networking). This allows us to discover other SocketPlane cluster members on the same segment and to start peering with them. This allows us to elastically grow the cluster on demand by simply deploying another host - mDNS handles the rest. Since multicast availability is hit and miss in most networks, it is aimed at making it easy to deploy Docker and SocketPlane to start getting familiar with the exciting marriage of advanced, yet sane networking scenario with the exciting Docker use cases. We will be working with the community on other clustering technologies such as swarm that can be in used in conjunction to provide a more provisioning oriented clustering solutions.

Once we've discovered our neighbors, we're able to join an embedded [Consul] instance, giving us access to an eventually consistent key/value store for network state.

We support mutiple networks, to allow you to divide your containers in to subnets to ease the burden of enforcing firewall policy in the network.

Finally, we've implemented a distributed IP address management solution that enables non conflicting address assignment throughout a cluster.


> Note: As we previously mentioned, it's not an *ideal* approach, but it allows people to start kicking the tyres as soon as possible. All of the functionality in `socketplane.sh` will move in to our Golang core over time.

[ See Getting Started Demo Here ] ( https://www.youtube.com/watch?v=ukITRl58ntg ) 

[ See Socketplane with a LAMP Stack Demo Here ] ( https://www.youtube.com/watch?v=5uzUSk3NjD0 ) 

[ See Socketplane with Powerstrip Demo Here ] ( https://www.youtube.com/watch?v=Icl0L8tQybs ) 

## Installation

### Base socketplane stuff
```bash
cd ./scripts/
chmod +x install.sh
sudo ./install.sh
```

### Vagrant

Update vagrant through the proper channels

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant

```


A Default Vagrant file has been provided to setup a a demo system. By default three Ubuntu 14.04 VM hosts will be installed each with an installed version of Socketplane.

You can change the number of systems created as follows:

    export SOCKETPLANE_NODES=1
    #or
    export SOCKETPLANE_NODES=10

To start the demo systems:

    git clone https://github.com/socketplane/socketplane
    cd socketplane
    vagrant up

The VM's are named `socketplane-{n}`, where `n` is a number from 1 to `SOCKETPLANE_NODES || 3`

 Once the VM's are started you can ssh in as follows:

    vagrant ssh socketplane-1
    vagrant ssh socketplane-2
    vagrant ssh socketplane-3

You can start Docker containers in each of the VM's and they will all be in a default network.

    sudo socketplane run -itd ubuntu

You can also see the status of containers on a specific host VM by typing:

    sudo socketplane info

If you want to create multiple networks you can do the following:

    sudo socketplane network create web 10.2.0.0/16

    sudo socketplane run -n web -itd ubuntu

You can list all the created networks with the following command:

    sudo socketplane network list

For more options use the HELP command

    sudo socketplane help

### Non-Vagrant install / deploy

If you are not a vagrant user, please follow these instructions to install and deploy socketplane.
While Golang, Docker and OVS can run on many operating systems, we are currently running tests and QA against [Ubuntu](http://www.ubuntu.com/download) and [Fedora](https://getfedora.org/).

> Note: If you are using Virtualbox, please take care of the following before proceeding with the installation :
* Clustering over NAT adapter will not work. Hence, the Virtualbox VMs must have either **Host-Only Adapter (or) Internal Network (or) Bridged adapter** installed for clustering to work.
* The VMs/Hosts must have **unique hostname**. Make sure that /etc/hosts in the VMs have the unique hostname updated.

    First Node:
    curl -sSL http://get.socketplane.io/ | sudo BOOTSTRAP=true sh

    Subsequent Nodes:
    curl -sSL http://get.socketplane.io/ | sudo sh

or

    First Node:
    wget -qO- http://get.socketplane.io/ | sudo BOOTSTRAP=true sh

    Subsequent Nodes:
    wget -qO- http://get.socketplane.io/ | sudo sh

> Warning: The BOOTSTRAP=true should be used on the first node only. Without it, it won't work. If used on subsequent nodes, bad things will happen.
 
This should ideally start the Socketplane agent container as well.
You can use **sudo docker ps | grep socketplane** command to check the status.
If, the agent isnt already running, you can install it using the following command :

    sudo socketplane install

Next start an image, for example a bash shell:

    sudo socketplane run -i -t ubuntu /bin/bash

You can also see the status of containers on a specific host VM by typing:

    sudo socketplane info

If you want to create multiple networks you can do the following:read

    sudo socketplane network create web 10.2.0.0/16

    sudo socketplane run -n web -itd ubuntu

You can list all the created networks with the following command:

    sudo socketplane network list

For more options use the HELP command

    sudo socketplane help

## Useful Agent Commands

The Socketplane agent runs in its own container and you might find the following commands useful :

1. Socketplane agent troubleshooting/debug logs :

        sudo socketplane agent logs

2. Socketplane agent stop :

        sudo socketplane agent stop

3. Socketplane agent start :

        sudo socketplane agent start

## Hacking

See [HACKING.md](HACKING.md)

## Contact us

For bugs please file an [issue](https://github.com/socketplane/socketplane/issues). For any assistance, questions or just to say hi, please visit us on IRC, `#socketplane` at `irc.freenode.net`

Stay tuned for some exciting features coming soon from the SocketPlane team.

## License

    Copyright 2014 SocketPlane, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.Code is released under the Apache 2.0 license.
