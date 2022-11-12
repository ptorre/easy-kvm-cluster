#!/usr/bin/bash
#
# Create and run VMs based on cloud-init images
#

# Allow for being sourced into other scripts
[[ $0 != "${BASH_SOURCE[0]}" ]] && sourced='true' || sourced='false'

vstart () {
    local hostname="$1"
    local image="$2"
    local userdata="$3"
    local memory="${4:-1024}"
    local vcpu=2
    local size='8G'
    local disk="${hostname}.raw"
    local localds="${hostname}.iso"
    local graphics='none'

    # Create a disk for cloud-init to utilize nocloud
    cloud-localds -H "${hostname}" "${localds}" "${userdata}" || return 1

    # Make a raw copy of the base image
    qemu-img convert -p -O raw "${image}" "${disk}" || return 1

    if [[ ${image} =~ [Aa]mzn ]];then
        graphics='spice'
    else
        # Grow root filesystem as base image is small
        qemu-img resize -f raw "${disk}" "${size}" || return 1
    fi

    # Import the copied disk image and boot the VM
    virt-install --import \
        --noautoconsole \
        --os-variant=none \
        --network=default,model=virtio \
        --graphics "${graphics}" \
        --name "${hostname}" \
        --memory "${memory}" \
        --vcpu "${vcpu}" \
        --disk "${disk},device=disk,bus=virtio" \
        --disk "${localds},device=disk,bus=virtio"
}

if [[ "${sourced}" == 'false' ]];then
    if (( $# < 3 )); then
        echo "Usage: $0 <hostname> <generic cloud image source> <user-data.yaml> [memory in Mi]" >&2
    else
        vstart "$1" "$2" "$3" "$4"
    fi
fi

