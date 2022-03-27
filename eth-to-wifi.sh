#!/bin/bash

# Share Eth with WiFi Hotspot
#
# This script is created to work with Raspbian Stretch
# but it can be used with most of the distributions
# by making few changes.
#
# Make sure you have already installed `dnsmasq` and `hostapd`
# Please modify the variables according to your need
# Don't forget to change the name of network interface
# Check them with `ifconfig`
#-----------------------------------
#ethUp script works fine, but the pop message does not appear on reboot.
ethUp=$(cat /sys/class/net/eth0/operstate)
if [ "$ethUp" = "down" ]
then
	zenity --warning --text="<span size=\"xx-large\">\nThe eth0 interface is down!\n</span>The routing functions will not be executed." --title="WARNING " --no-wrap --ok-label="Close"
	exit 0
else
	route
fi

route () {
ip_address="192.168.100.111"
netmask="255.255.255.0"
dhcp_range_start="192.168.1.150"
dhcp_range_end="192.168.1.170"
dhcp_time="3000d"
eth="eth0"
wlan="wlan0"
ssid="BlockChanger"
psk="12345678"

sudo killall wpa_supplicant &> /dev/null
sudo rfkill unblock wlan &> /dev/null
sleep 2

sudo systemctl start network-online.target

sudo iptables --flush # deleting all the rules one by one.
sudo iptables --table nat --flush # deleting all the rules attached to nat table one by one.
sudo iptables --table nat -append POSTROUTING --out-interface $eth --jump MASQUERADE # --jump: what to do if the packet matches it, 
								#MASQUERADE to specifying a mapping to the IP address of the interface the packet is going out
sudo iptables --append FORWARD --in-interface $eth --out-interface $wlan --match state --state RELATED,ESTABLISHED -jump ACCEPT
sudo iptables --append FORWARD --in-interface $wlan --out-interface $eth -jump ACCEPT

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

sudo ifconfig $wlan $ip_address netmask $netmask

# Remove default route
sudo ip route del 0/0 dev $wlan &> /dev/null

sudo rm -rf /etc/dnsmasq.d/* &> /dev/null

echo -e "interface=$wlan \n\
bind-interfaces \n\
server=172.17.0.4 \n\
domain-needed \n\
bogus-priv \n\
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time" > /etc/dnsmasq.d/custom-dnsmasq.conf

sudo systemctl restart dnsmasq

echo -e "interface=$wlan\n\
driver=nl80211\n\
ssid=$ssid\n\
hw_mode=g\n\
ieee80211n=1\n\
wmm_enabled=1\n\
macaddr_acl=0\n\
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]\n\
channel=6\n\
auth_algs=1\n\
ignore_broadcast_ssid=0\n\
wpa=2\n\
wpa_key_mgmt=WPA-PSK\n\
wpa_passphrase=$psk\n\
rsn_pairwise=CCMP" > /etc/hostapd/hostapd.conf

sudo systemctl stop hostapd
sudo hostapd /etc/hostapd/hostapd.conf &
}
