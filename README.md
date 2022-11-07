## Notes on easily setting up KVM virtual machines for local k8s cluster development

Simple methods to quickly spin up and tear down virtual machines localy using virt-install and cloud images

Simple steps:
1. Download the cloud image you want to use: [see full example](#full-example)
  - https://cloud.debian.org/cdimage/cloud/
  - https://cloud-images.ubuntu.com/releases/22.10/release/
  - https://cdn.amazonlinux.com/os-images/2.0.20221004.0/
1. Copy and grow the downloaded cloud image filesystem
1. Create a nocloud data source for cloud-init starting with these:
    [user-data.yaml](/user-data.yaml) and [amzn2-user-data.yaml](/amzn2-user-data.yaml)
1. Run virt-install to start the VMs as many as you need, use [vstart.sh](/vstart.sh)

The below is a bash script that I use to quickly startup multiple local instances.
The instance disk file names will be based on the hostname used.
The Debian _genericcloud_, Ubuntu _kvm_ and Amazon Linux 2 images work well with some
minor user-data tweaks.

***IMPORTANT*** You should add your own public key to admin user's authorized_keys
file intead of mine...
The key can be all on one line, E.g:
```
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAGEA3FSyQwBI6Z+nCSjUUk8EEAnnkhXlukKoUPND/RRClWz2s5TCzIkd3Ou5+Cyz71X0XmazM3l5WgeErvtIwQMyT1KjNoMhoJMrJnWqQPOt5Q8zWd9qG7PBl9+eiH5qV7NZ mykey@host
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3...
```

## Full Example:
- Save the bash script [vstart.sh](/vstart.sh) and make it executable `chmod +x vstart`
- Save the [user-data.yaml](/user-data.yaml) and modify to add your own ssh public keys
- Download some cloud images:
  - `wget https://cdimage.debian.org/cdimage/cloud/bullseye/20221020-1174/debian-11-genericcloud-amd64-20221020-1174.qcow2`
  - `wget https://cloud-images.ubuntu.com/releases/22.10/release/ubuntu-22.10-server-cloudimg-amd64.img`
  - `wget https://cdn.amazonlinux.com/os-images/2.0.20221004.0/kvm/amzn2-kvm-2.0.20221004.0-x86_64.xfs.gpt.qcow2`
    - you'll need to download and modify [amzn2-user-data.yaml](/amzn2-user-data.yaml) as well in this case
- _its a good idea to verify the images using the signatures, but I leave that up to you_
- Start some virtual machines:
```
./vstart control-node-1 user-data.yaml debian-11-genericcloud-amd64-20221020-1174.qcow2
./vstart worker-node-debian user-data.yaml debian-11-genericcloud-amd64-20221020-1174.qcow2
./vstart worker-node-ubuntu user-data.yaml ubuntu-22.10-server-cloudimg-amd64.img
./vstart worker-node-amzn2 amzn-user-data.yaml amzn2-kvm-2.0.20221004.0-x86_64.xfs.gpt.qcow2
...etc.
```

***After a little while (can be several minutes) the VM instances should be ready for you to ssh into them***

_**Running `virsh net-dhcp-leases default` or `virsh domifaddr <name>` will give you the
ip addresses for the created VMs**_
**`debian`** is the default user for Debian and **`ubuntu`** is the default user for Ubuntu, **`ec2-user`** for Amazon Linux2, etc...

After logging in you can run `cloud-init status --long --wait` and when that shows `status: done`,
finish installing a k8s cluster with `kubeadm` and `kubectl`. (https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
