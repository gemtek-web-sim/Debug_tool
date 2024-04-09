#!/bin/sh

#Set this to stop the script immediately when error
#set -e

# Version and HW information
version_and_hardware_info() {
    uname -a                > uname
    cat /proc/version      >> uname
    cat /etc/*-release      > distro_version
    version.sh              > version
    cat /proc/uptime        > uptime
    cat /etc/passwd         > passwd
    cat /etc/shadow         > shadow
    #cat /etc/localtime	    > localTimeZone
    #To be updated          > reboot_reason
    #lsb_release -a         > lsb_release
    #lsof                   > lsof
    #lshw                   > lshw # List Hardware information
}

# backup_config
backup_config() {
    # Save all /etc/config files
    for file in /etc/config/*; do
        cat $file > $(basename -- "$file")
    done

    # Save some needed files in /etc/
    set -- fstab resolv.conf  \
               #tinyproxy.conf dropbear
    for file in "$@"; do
        cat "/etc/$file" > "$file"
    done

    cat /tmp/upnp/miniupnpd.conf    > miniupnpd.conf

    # Linux kernel config
    cat /proc/config.gz | gunzip > kernel.config
}

# /proc/
proc_files() {
    cat /proc/net/dev           > dev
    cat /proc/net/ip_mr_cache   > ip_mr_cache
    cat /proc/net/ip_mr_vif     > ip_mr_vif
    cat /proc/kallsyms          > kallsyms
    cat /proc/loadavg           > loadavg

    cat /proc/meminfo           > meminfo
    cat /proc/net/nf_conntrack  > nf_conntrack
    cat /proc/net/nf_conntrack_expect > nf_conntrack_expect

    #cat /proc/slabinfo          > slabinfo
    cat /proc/softirqs          > softirqs
    cat /proc/stat              > stat
    cat /proc/interrupts        > interrupts
    cat /proc/filesystems       > filesystems
}

# CPU load and process
cpu_load_and_process() {
    # lscpu
    # top -o +%MEM -n 1
    # top -o +%CPU -n 1
    top -n 1    > top
    free -m     > freeram

    # Process
    ps         > ps
    # ps -aux >> ps
}

# Interface and connection
interface_and_connection() {
    brctl show           > brctl_show
    netstat -a           > netstat
    ifconfig             > ifconfig
    cat /proc/net/igmp   > igmp
    ubus -v list         > ubus_services

    # Link status and tables
    ip link show         > interfaces
    route -n            >> interfaces
    ip route show       >> interfaces
    ip neighbour show   >> interfaces
    arp                  > arp

    #devstatus <dev>	    > network_device
    #ifstatus <interface>	> network_iface

    # Port stats
    #switch_cli dev=1 GSW_RMON_CLEAR nRmonId=2 # 2: GSW_RMON_PORT_TYPE

    ethtool -S eth0_0                             > eth0_0_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=0  > LAN_ports_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=1 >> LAN_ports_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=2 >> LAN_ports_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=3 >> LAN_ports_stats
    sleep 1
    ethtool -S eth0_0                            >> eth0_0_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=0 >> LAN_ports_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=1 >> LAN_ports_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=2 >> LAN_ports_stats
    switch_cli dev=1 GSW_RMON_PORT_GET nPortId=3 >> LAN_ports_stats

    # Interface stats
    #cat /sys/class/net/%s/statistics/rx_bytes
    #cat /sys/class/net/%s/statistics/tx_bytes
    mkdir class_net_stats
    cd class_net_stats
    for net in /sys/class/net/*; do
        netname=$(basename -- "$net")
        echo $net > $netname
        stats_path="$net/statistics/*";
        for net_param in $stats_path; do
            echo -n "$(basename -- "$net_param"): " >> $netname
            cat $net_param >> $netname
        done
    done
    cd ../
}

# NAT Iptables
iptables_func() {
    ip6tables-save         > ip6tables-save
    ip6tables -L           > ip6tables
    ipset list             > ipset
    iptables-save          > iptables-save
    iptables -L            > iptables
    iptables -t nat -L    >> iptables
    iptables -t mangle -L >> iptables

    iptables -t nat -S    >> iptables-nat
}

# System log
system_logs() {
    # journalctl
    dmesg                   > dmesg
    logread                 > logread

    # cat /var/log/*
    #cat /var/log/kern.log   > kernel
    #cat /var/log/kern.log.1 > kernel.log.1

    cat /var/log/lastlog    > lastlog
    cat /var/log/wtmp       > wtmp
    #cat /var/log/messages  > messages
    #cat /tmp/dnsmasq.log   > lan.dhcp.log
}

read_files_recursive() {
    local dir=$1
    # Loop through all files and subdirectories in the given directory
    for file in "$dir"/*; do
        if [ -d "$file" ]; then
            # If it's a directory, recursively call the function
            dirName=$(basename -- "$file")
            mkdir $dirName && cd $dirName
            read_files_recursive "$file"
            cd ../
        elif [ -f "$file" ]; then
            # Else it's a regular file
            fileName=$(basename -- "$file")
            cat $file > $fileName
        fi
    done
}

# Wifi related log
wifi_logs() {
    # wlan interface info
    iw dev                  > iw_dev
    # physical info
    iw phy                  > iw_phy
    # dump info
    wlan_interfaces=$(iw dev | grep wlan | awk '{print $2}')
    for interface in $wlan_interfaces; do
        # station dump
        iw dev "$interface" station dump >> iw_station_dump
        # survey dump
        iw dev "$interface" survey dump  >> iw_survey_dump
    done
    # hostapd
    cat /var/run/hostapd*   > hostapd.conf
    # mtlk - General Wifi info
    # cp -r /proc/net/mtlk/ mtlk
    mkdir mtlk && cd mtlk
    read_files_recursive "/proc/net/mtlk"
    cd ../
}

# General logs
general_logs() {
    #cat ./tmp/dhcp.leases  > dhcp.leases
    cat /etc/dnsmasq.conf   > dnsmasq.conf
    ebtables -L             > ebtables
    ls -l /proc/*/fd/*      > fd
    cat /etc/hosts          > hosts
    #To be updated          > dhcp.reserv
    #To be updated          > dnsmasq.conf.dnsmasq_lan
    #To be updated          > dsd.env
    #To be updated          > ethers
    #To be updated          > eth_portmap
    #To be updated          > fe_debug_reg
    #To be updated          > fe_reg
    #To be updated          > fw_printenv
    #To be updated          > gsw_link_st
    #To be updated          > gsw_stats

    #To be updated          > ntp_sync_status
    #To be updated          > portmap
    #To be updated          > qos
}

# Memory
memory() {
    df -h                > diskspace
    free -m             >> diskspace
    cat /proc/vmstat     > vmstat
    #cat /proc/zoneinfo  > zoneinfo

    # Memory Leak check
}

# Register
registers() {
    #To be updated
    :
}

# Switch_cli
switch_cli_func() {
    #To be updated

    #XGMAC setting and rmon
    switch_cli xgmac "*" get all    > xgmac_all_settings

    #switch_cli xgmac "*" clear_rmon > xgmac_rmon
    switch_cli xgmac "*" get rmon  >> xgmac_rmon
    sleep 1
    switch_cli xgmac "*" get rmon  >> xgmac_rmon
    sleep 1
    switch_cli xgmac "*" get rmon  >> xgmac_rmon
}

# ethtool
ethtool_func() {
    ethtool -i eth0_0          > ethtool_eth0_0
    ethtool eth0_0            >> ethtool_eth0_0
    ethtool --show-eee eth0_0 >> ethtool_eth0_0
    ethtool -k eth0_0         >> ethtool_eth0_0

    ethtool -i eth0_1          > ethtool_eth0_1
    ethtool eth0_1            >> ethtool_eth0_1
}

generate_debugfile() {
    # Compress debug folder to a file
    compress_file_name="${output_name}.tar"
	tar -cvf "$compress_file_name" "$output_name" > /dev/null && rm -rf "$output_name"

    encrypted_file_name="${compress_file_name}.enc"
    # Encrypt debug file
    printf "$password" | openssl aes-256-cbc -a -salt -pbkdf2 -in "$compress_file_name" -out "$encrypted_file_name" -pass stdin > /dev/null
    rm "$compress_file_name"
}

call_function() {
    # echo "Function $1 was called ...."
    mkdir -p $1
    cd $1
    $1 2>> ../error_log.txt
    cd ../

    # Keep track of progress
    completed_calls=$((completed_calls + 1))
    progress=$((completed_calls * 100 / total_calls))
    percentage=$(echo "$progress%")
    echo -ne "Progress: [$percentage] ["
    j=0
    while [ "$j" -lt "$progress" ]; do
        echo -n "="
        j=$((j + 2))
    done
    while [ "$j" -lt 100 ]; do
        echo -n " "
        j=$((j + 2))
    done
    echo -ne "]\r"
}

help_information() {
    echo "Usage: debuglog.sh [options] ..."
    echo ""
    echo "Options:"
    echo "  -i, --info INFORMATION    Specify the information to collect (choose one):"
    echo "                             version_and_hardware_info, backup_config, proc_file,"
    echo "                             cpu_load_and_process, interface_and_connection, iptables_func,"
    echo "                             system_logs, general_logs, memory, registers, switch_cli_func,"
    echo "                             ethtool_func, wifi_logs"
    echo "  -p, --password PASSWORD   Specify the password for file encryption."
    echo "                             Example: debuglog.sh -i 'backup_config version_and_hardware_info' -p MySecurePassword -t 20220312_123456"
    echo "  -t, --timestamp TIMESTAMP Specify a custom timestamp for the output file."
    echo ""
    echo "Available information:"
    echo "  version_and_hardware_info : Information about hardware and system version."
    echo "  backup_config             : Backup configuration files."
    echo "  proc_file                 : Information from '/proc' folder."
    echo "  cpu_load_and_process      : Information about CPU and processes."
    echo "  interface_and_connection  : Information about network interfaces and connections."
    echo "  iptables_func             : NAT iptables information."
    echo "  system_logs               : System logs."
    echo "  general_logs              : General logs and configurations."
    echo "  memory                    : Information about memory and disk space."
    echo "  registers                 : Information about registers (to be updated)."
    echo "  switch_cli_func           : Information about XGMAC (to be updated)."
    echo "  ethtool_func              : Information about Ethernet network devices."
    echo "  wifi_logs                 : Information about Wifi configuration and status."
    echo ""
    echo "Additional information:"
    echo "  -h, --help                : Display this help message."
    echo ""
}

main() {
    START_TIME=$(date +%s)
    mkdir -p output/$output_name
    cd output/$output_name

    # Run debuglog.sh with default configuration
    if [ $is_getinfo_default -eq 1 ]; then
        set -- \
        version_and_hardware_info \
        backup_config \
        proc_files \
        cpu_load_and_process \
        interface_and_connection \
        iptables_func \
        system_logs \
        general_logs \
        memory \
        registers \
        switch_cli_func \
        ethtool_func \
        wifi_logs

        total_calls=$(echo $@ | wc -w)
        completed_calls=0

        for func in "$@"; do
            call_function $func
        done
    # Run debuglog.sh with configurations from user
    else
        total_calls=$(echo $selected_option | wc -w)
        completed_calls=0
        for debug_option in $selected_option; do
            if [ "$debug_option" = "version_and_hardware_info" ]; then
                call_function "version_and_hardware_info"
            elif [ "$debug_option" = "backup_config" ]; then
                call_function "backup_config"
            elif [ "$debug_option" = "proc_file" ]; then
                call_function "proc_files"
            elif [ "$debug_option" = "cpu_load_and_process" ]; then
                call_function "cpu_load_and_process"
            elif [ "$debug_option" = "interface_and_connection" ]; then
                call_function "interface_and_connection"
            elif [ "$debug_option" = "iptables_func" ]; then
                call_function "iptables_func"
            elif [ "$debug_option" = "system_logs" ]; then
                call_function "system_logs"
            elif [ "$debug_option" = "general_logs" ]; then
                call_function "general_logs"
            elif [ "$debug_option" = "registers" ]; then
                call_function "registers"
            elif [ "$debug_option" = "switch_cli_func" ]; then
                call_function "switch_cli_func"
            elif [ "$debug_option" = "ethtool_func" ]; then
                call_function "ethtool_func"
            elif [ "$debug_option" = "wifi_logs" ]; then
                call_function "wifi_logs"
            else
                echo -e "\n"
                echo " $debug_option is invalid option"
                echo " Try option '--help' or '-h' to show avaiable option"
            fi
        done
    fi

    cd ../
    generate_debugfile

    END_TIME=$(date +%s)
    echo ""
    echo "Done in $(($END_TIME - $START_TIME)) seconds"
}

# Default flags helps setting default config
is_getinfo_default=1
is_password_default=1
is_timestamp_default=1

# Script starts to run here

## Serve query from cURL & wget command
if [ -n "$QUERY_STRING" ]; then
    echo "Query string: $QUERY_STRING"
    # Split the input string by the '&' delimiter
    password=$(echo "$QUERY_STRING" | sed -n 's/^.*enpwd=\([^&]*\).*$/\1/p')
    if [ -n "$password" ]; then
        is_password_default=0
    fi

    timestamp=$(echo "$QUERY_STRING" | sed -n 's/^.*time=\([^&]*\).*$/\1/p')
    if [ -n "$timestamp" ]; then
        is_timestamp_default=0
    fi

    selected_option=$(echo "$QUERY_STRING" | sed -n 's/^.*info=\([^&]*\).*$/\1/p')
    if [ -n "$selected_option" ]; then
        selected_option="${selected_option//+/ }"
        is_getinfo_default=0
    fi
fi

while getopts "i:p:t:h" opt; do
  case "${opt}" in
    i)
        selected_option=$OPTARG
        for element in $selected_option; do
            if [ "$element" != "version_and_hardware_info" ] &&
            [ "$element" != "backup_config" ] &&
            [ "$element" != "proc_file" ] &&
            [ "$element" != "cpu_load_and_process" ] &&
            [ "$element" != "interface_and_connection" ] &&
            [ "$element" != "iptables_func" ] &&
            [ "$element" != "system_logs" ] &&
            [ "$element" != "general_logs" ] &&
            [ "$element" != "registers" ] &&
            [ "$element" != "switch_cli_func" ] &&
            [ "$element" != "ethtool_func" ] &&
            [ "$element" != "wifi_logs" ]; then
                echo "Invalid information: $element"
                exit 1
            fi
        done
        is_getinfo_default=0
        ;;
    p)
        password=$OPTARG
        is_password_default=0
        ;;
    t)
        timestamp=$OPTARG
        is_timestamp_default=0
        ;;
    h)
        help_information
        exit 1
        ;;
    \?)
        echo "Invalid option: -$OPTARG"
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument."
        exit 1
        ;;
    esac
done

if [ $# -eq 0 ]; then
    echo "Start debuglog.sh with default configurations ..."
fi

# Default timestamp
if [ $is_timestamp_default -eq 1 ]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
fi

# Debuglog permission
echo "$(id | awk -F'[()]' '{print $2}')"
if [ "$(id | awk -F'[()]' '{print $2}')" != "root" ]; then
    echo "Please run the tool with sudo permission to gather more information!"
    echo "Running the tool with User permission..."
    output_name="debuglog_nonSudo_${timestamp}"
    [ $is_password_default -eq 1 ] && password="Gemtek@123"
    cd /tmp
else
    echo "Running the tool with Sudo permission..."
    # Create debug output name
    MODEL=$(uci get upnpd.config.model_name)
    SN=$(uci -c /etc/ get boardinfo.gtk.SerialNumber)
    output_name="${MODEL}_${SN}_${timestamp}"
    [ $is_password_default -eq 1 ] && password="Gemtek@123_${SN}"
fi

# Start to obtain debug information
main

# Dont remove or echo below that line -- need for run debug_log from client side
echo "$output_name.tar.enc"