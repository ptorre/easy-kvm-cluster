## Notes on easily setting up KVM virtual machines for local k8s cluster development

Simple methods to quickly spin up and tear down virtual machines localy using virt-install and cloud images.

Using prebuilt cloud images is usually much faster than running through a distro install to setup new VMs.

Simple steps:
1. Download the cloud image you want to use: [see full example](#full-example)
    - https://cloud.debian.org/cdimage/cloud/
    - https://cloud-images.ubuntu.com/releases/22.10/release/
    - https://cdn.amazonlinux.com/os-images/2.0.20221004.0/
1. Copy and grow the downloaded cloud image filesystem
1. Create a nocloud data source for cloud-init starting with these:
    - [debian-user-data.yaml](/debian-user-data.yaml)
    - [amzn2-user-data.yaml](/amzn2-user-data.yaml)
    - [fedora-user-data.yaml](/fedora-user-data.yaml)
1. Run virt-install to start the VMs as many as you need, use [vstart.sh](/vstart.sh)

The below is a bash script that can be used to quickly startup multiple local instances.
The instance disk file names will be based on the hostname used.
The Debian _genericcloud_, Ubuntu _kvm_ and Amazon Linux 2 _kvm_ images work well with
only minor user-data tweaks.  _Fedora_ and _Rocky_ have not been as easy to get set up,
as those images need for more package updates and take far longer to be ready.  If you
prefer Red Hat based distros, the Amazon images are a good choice.

***IMPORTANT*** You should add your own public key to admin user's authorized_keys
file intead of mine...
The key can be all on one line, E.g:
```
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAGEA3FSyQwBI6Z+nCSjUUk8EEAnnkhXlukKoUPND/RRClWz2s5TCzIkd3Ou5+Cyz71X0XmazM3l5WgeErvtIwQMyT1KjNoMhoJMrJnWqQPOt5Q8zWd9qG7PBl9+eiH5qV7NZ mykey@host
  - ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3...
```

## Full Example:
- Make sure you have the dependencies installed: `libvirt-daemon`, `libvirt-clients`, `cloud-localds`, `qemu-img` and `virt-install` and that you can successfully run virtual machines using these tools before you start.
- Edit the user-data yaml files to add your own ssh public keys
- Download some cloud images:

```
wget https://cdimage.debian.org/cdimage/cloud/bullseye/20221020-1174/debian-11-genericcloud-amd64-20221020-1174.qcow2
wget https://cloud-images.ubuntu.com/releases/22.10/release/ubuntu-22.10-server-cloudimg-amd64-disk-kvm.img
wget https://cdn.amazonlinux.com/os-images/2.0.20221004.0/kvm/amzn2-kvm-2.0.20221004.0-x86_64.xfs.gpt.qcow2
wget https://download.fedoraproject.org/pub/fedora/linux/releases/36/Cloud/x86_64/images/Fedora-Cloud-Base-36-1.5.x86_64.raw.xz &&
  xz --verbose -d Fedora-Cloud-Base-36-1.5.x86_64.raw.xz
```
- _its a good idea to verify the images using the signatures, but I leave that up to you_
- Start some virtual machines:

```
./vstart.sh control-node-1 debian-11-genericcloud-amd64-20221020-1174.qcow2 user-data.yaml 2048  # 2048MiB for control-plane-node (default is 1024MiB)
./vstart.sh worker-node-debian debian-11-genericcloud-amd64-20221020-1174.qcow2 debian-user-data.yaml
./vstart.sh worker-node-ubuntu ubuntu-22.10-server-cloudimg-amd64-disk-kvm.img debian-user-data.yaml
./vstart.sh worker-node-amzn2 amzn2-kvm-2.0.20221004.0-x86_64.xfs.gpt.qcow2 amzn-user-data.yaml
./vstart.sh worker-node-fedora Fedora-Cloud-Base-36-1.5.x86_64.raw fedora-user-data.yaml
```


_**Running `virsh domifaddr <name>` will give you the ip addresses for a VM.**_

***By default these images will have IP addresses assigned by dhcp.
If you plan on keeping them around for a while You should reserve the
addresses assiged to the control plane nodes (use the mac and ip address
returned by the above command):***
```
virsh net-update default add-last ip-dhcp-host \
  '<host name="control-node" mac="52:54:00:e1:48:63" ip="192.168.122.57"/>' \
  --live --config
```
***If you don't do this the cluster will stop working if the control plane nodes
are ever given new IP addresses by dhcp.***

**`debian`** is the default user for Debian
**`ubuntu`** is the default user for Ubuntu
**`ec2-user`** for Amazon Linux2
**`fedora`** for Fedora, etc...

*Cloud-init should be finished and the VM instances should be ready after a little while (can be several minutes).*

After logging in you, can run `sudo cloud-init status --long --wait` and when that shows `status: done`,
finish installing a k8s cluster with `kubeadm` and `kubectl`. (https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

_After creating a k8s cluster using `kubeadm init` and `kubeadm join`, I have the following:_

```
$ kubectl get nodes -o custom-columns='Name:..name,OS:..osImage,KernelVersion:..kernelVersion,Memory:..capacity.memory'
```
```
Name               OS                                KernelVersion                   Memory
control-node-1     Debian GNU/Linux 11 (bullseye)    5.10.0-19-cloud-amd64           1983768Ki
worker-node-amzn2  Amazon Linux 2                    4.14.296-222.539.amzn2.x86_64   1007756Ki
worker-node-debian Debian GNU/Linux 11 (bullseye)    5.10.0-19-cloud-amd64           977688Ki
worker-node-fedora Fedora Linux 36 (Cloud Edition)   6.0.5-200.fc36.x86_64           986148Ki
worker-node-ubuntu Ubuntu 22.10                      5.19.0-1010-kvm                 1008216Ki
```
