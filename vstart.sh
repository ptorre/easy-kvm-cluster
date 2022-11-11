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
    local disk="${hostname}.raw"
    local size='8G'
    local localds="${hostname}.img"
    local graphics='none'
    local os='generic'
    local needs_expansion='true'

    if [[ ${image} =~ [Aa]mzn ]];then
        os='rhel8.2'
        graphics='spice'
        needs_expansion='false'
    elif [[  "${image}" =~ [Dd]ebian ]];then
        os='debian10'
    elif [[  "${image}" =~ [Uu]buntu ]];then
        os='ubuntu20.04'
    else
        echo "OS unknown ${image} needs to be added to script types!" >& 2
        return 1
    fi

    # Make a raw copy of the base image
    qemu-img convert -p -O raw "${image}" "${disk}" || return 1

    if [[ "${needs_expansion}" == 'true' ]]; then
        # Grow root filesystem as base image is small
        qemu-img resize -f raw "${disk}" "${size}" || return 1
    fi

    # Create a disk for cloud-init to utilize nocloud
    cloud-localds -H "${hostname}" "${localds}" "${userdata}" || return 1

    # Spin up a virtual mahcine
    virt-install --import --noautoconsole \
        --network=default,model=virtio \
        --graphics "${graphics}" \
        --os-variant "${os}" \
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

