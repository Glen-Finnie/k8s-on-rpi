#!/usr/bin/env bash

set -e

check_overlay_module_loaded_function () {

    # lsmod - show the status of all the loaded Linux Kernel modules
    # then pipe through grep for the overlay module
    if lsmod | grep -q overlay
    then

        echo
        echo "######## overlay module loaded ########"

        # 0 = true
        return 0
    else

        echo
        echo "##### overlay module not loaded #######"

        # 1 = false
        return 1
    fi
}

check_br_netfilter_module_loaded_function () {

    # lsmod - show the status of all the loaded Linux Kernel modules
    # then pipe through grep for the br_netfilter module
    if lsmod | grep -q br_netfilter
    then

        echo
        echo "##### br_netfilter module loaded #####"

        # 0 = true
        return 0
    else

        echo
        echo "### br_netfilter module not loaded ####"

        # 1 = false
        return 1
    fi
}

check_overlay_and_br_netfilter_modules_loaded_function () {

    if check_overlay_module_loaded_function && check_br_netfilter_module_loaded_function
    then

        # 0 = true
        return 0
    else

        # 1 = false
        return 1
    fi
}


check_ip_forward_enabled_function () {

    ### Check ip_forward is enabled
    ### net.ipv4.ip_forward
    ### The value below must be 1 (not 0)
    # sysctl net.ipv4.ip_forward

    if sysctl net.ipv4.ip_forward | grep -q "net.ipv4.ip_forward = 1"
    then

        echo
        echo "######## ip_forward enabled ########"

        # 0 = true
        return 0
    else

        echo
        echo "###### ip_forward not enabled #######"

        # 1 = false
        return 1
    fi
}

check_bridged_packets_sent_to_iptable_function () {

    ### Check whether packets crossing a bridge are sent to iptables for processing enabled
    ### net.bridge.bridge-nf-call-iptables
    ### The value below must be 1 (not 0)
    # sysctl net.bridge.bridge-nf-call-iptables

    if sysctl net.bridge.bridge-nf-call-iptables | grep -q "net.bridge.bridge-nf-call-iptables = 1"
    then

        echo
        echo "##### bridged packets sent to iptable #####"

        # 0 = true
        return 0
    else

        echo
        echo "### bridged packets not sent to iptable ###"

        # 1 = false
        return 1
    fi
}

check_bridged_IP6_packets_sent_to_iptable_function () {

    ### Check whether IP6 packets crossing a bridge are sent to iptables for processing enabled
    ### net.bridge.bridge-nf-call-ip6tables
    ### The value below must be 1 (not 0)
    # sysctl net.bridge.bridge-nf-call-ip6tables

    if sysctl net.bridge.bridge-nf-call-ip6tables | grep -q "net.bridge.bridge-nf-call-ip6tables = 1"
    then

        echo
        echo "##### bridged IP6 packets sent to iptable #####"

        # 0 = true
        return 0
    else

        echo
        echo "### bridged IP6 packets not sent to iptable ###"

        # 1 = false
        return 1
    fi
}

check_containerd_installed_function () {

    if command -v containerd &> /dev/null
    then
        echo
        echo "##### containerd installed #####"

        # 0 = true
        return 0
    else

        echo
        echo "#### containerd not installed ####"

        # 1 = false
        return 1
    fi
}

check_containerd_service_running_function () {

    # systemctl - list services that are in a running state
    # then pipe through grep for the containerd service
    if systemctl --type=service --state=running | grep -q containerd.service
    then

        echo
        echo "######## containerd service running ########"

        # 0 = true
        return 0
    else

        echo
        echo "##### containerd not service running #######"

        # 1 = false
        return 1
    fi
}

check_containerd_service_file_function () {

    FILE=/usr/local/lib/systemd/system/containerd.service

    if test -f "$FILE"
    then

        echo
        echo "# containerd.service systemd file present #"

        # 0 = true
        return 0
    else

        echo
        echo "# containerd.service systemd file not present #"

        # 1 = false
        return 1
    fi
}

check_runc_installed_function () {

    if command -v runc &> /dev/null
    then
        echo
        echo "##### runc installed #####"

        # 0 = true
        return 0
    else

        echo
        echo "#### runc not installed ####"

        # 1 = false
        return 1
    fi
}

check_cni_plugins_installed_function () {

    # checking for a selection of plugins, there are more.
    FILE1=/opt/cni/bin/bridge
    FILE2=/opt/cni/bin/ipvlan
    FILE3=/opt/cni/bin/loopback
    FILE4=/opt/cni/bin/macvlan
    FILE5=/opt/cni/bin/ptp
    FILE6=/opt/cni/bin/vlan
    FILE7=/opt/cni/bin/host-device

    if test -f "$FILE1" && test -f "$FILE2" && test -f "$FILE3" && test -f "$FILE4" && test -f "$FILE5" && test -f "$FILE6" && test -f "$FILE7"
    then

        echo
        echo "# cni plugins present #"

        # 0 = true
        return 0
    else

        echo
        echo "# cni plugins not present #"

        # 1 = false
        return 1
    fi   
}

check_containerd_config_file_function () {

    FILE=/etc/containerd/config.toml

    if test -f "$FILE"
    then

        echo
        echo "# containerd config.toml file present #"

        # 0 = true
        return 0
    else

        echo
        echo "# containerd config.toml file not present #"

        # 1 = false
        return 1
    fi
}

check_kubernetes_apt_repository_function () {

    FILE1=/etc/apt/sources.list.d/kubernetes.list
    FILE2=/etc/apt/keyrings/kubernetes-apt-keyring.gpg

    if test -f "$FILE1" && test -f "$FILE2"
    then

        echo
        echo "# kubernetes apt repository present #"

        # 0 = true
        return 0
    else

        echo
        echo "# kubernetes apt repository not present #"

        # 1 = false
        return 1
    fi
}

check_crictl_config_file_function () {

    FILE=/etc/crictl.yaml

    if test -f "$FILE"
    then

        echo
        echo "# crictl.yaml file present #"

        # 0 = true
        return 0
    else

        echo
        echo "# crictl.yaml file not present #"

        # 1 = false
        return 1
    fi
}
