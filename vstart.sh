#!/usr/bin/bash

vstart () {
    local hostname=$1
    local userdata="$2"
    local image="$3"
    local memory=2000
    local vcpu=2
    local disk=$hostname.raw
    local size=8G
    local localds=$hostname.img

    # Convert downloaded image to raw
    qemu-img convert -p -O raw "$image" $disk

    # Grow root filesystem
    qemu-img resize -f raw $disk $size

    # Create a disk for cloud-init to utilize nocloud
    cloud-localds -H $hostname $localds "$userdata" &&

    # Spin up a virtual mahcine
    virt-install --os-variant debian10 --graphics none --import \
        --noautoconsole \
        --network=default,model=virtio \
        --name $hostname --memory $memory --vcpu $vcpu \
        --disk "$disk,device=disk,bus=virtio" \
        --disk "$localds,device=disk,bus=virtio"

    # For debugging remove --noautoconsole above to watch the console messages.
    # You do that you can hit ctrl-] to exit the guest console after get back to
    # the host prompt.  It will generally not be possible to log in at the console.
}



if (( $# == 3 )); then
	vstart "$1" "$2" "$3"
	rc=$?
else
    echo "Usage: $0 <hostname> <user-data.yaml> <generic cloud image source>"
	rc=1
fi

exit $rc

