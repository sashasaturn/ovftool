
#!/bin/bash

#based on thevirtualist.org
#make sure that the folder actually exists
STATE='/tmp/ovfstate'

if [ -e $STATE ]
	then
		date +"%m.%d.%Y %T "
		echo "$STATE file exists. Doing nothing."
		exit 1
	else
		echo "+++++++++++++++++++++++++++++++++++++++++++"
		echo "++++++++++++ OVF Config script ++++++++++++"
		echo "+ System will be rebooted after execution +"
		echo "+++++++++++++++++++++++++++++++++++++++++++"


		# create XML file with settings
		date +"%m.%d.%Y %T " ; echo "Fetcing values"
		vmtoolsd --cmd "info-get guestinfo.ovfenv" > /tmp/ovf_env.xml
		TMPXML='/tmp/ovf_env.xml'

		# gathering values
		date +"%m.%d.%Y %T "; echo "Sorting..."
		IP=`cat $TMPXML| grep -e ipaddress |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		NETMASK=`cat $TMPXML| grep -e netmask |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		GW=`cat $TMPXML| grep -e gateway |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		HOSTNAME=`cat $TMPXML| grep -e hostname |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		DNS0=`cat $TMPXML| grep -e dns |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`
		DOMAIN=`cat $TMPXML| grep -e domain |sed -n -e '/value\=/ s/.*\=\" *//p'|sed 's/\"\/>//'`

		# NMCLI fetch existing netwrok interface device name
		date +"%m.%d.%Y %T "; echo "Gathering info about network interfaces..."
		IFACE=`nmcli dev|grep ethernet|awk '{print $1}'`

		# NMCLI fetch existing connection name. This will have to be recreated.
		CON=`nmcli con show|grep -v NAME| awk '{print $1}'`
		# NMCLI remove connection
		nmcli con delete $CON

		# Create new connection
		date +"%m.%d.%Y %T " ; echo "Setting Network settings...."
		# Check if IP and NETMASk variables exist and are not empty
		if [ -z ${IP+x} ] && [ -z ${NETMASK+x} ]; then
				date +"%m.%d.%Y %T " ; echo "No IP information found. Trying DHCP"
				# IF empty configure connection to use DHCP
				nmcli con add con-name "$IFACE" ifname "$IFACE" type ethernet
			else
				date +"%m.%d.%Y %T " ; echo "Setting..."
				# If variables exist, configure interface with IP and netmask and GW. Also set DNS settings in same step.
				nmcli con add con-name "$IFACE" ifname $IFACE type ethernet ip4 $IP/$NETMASK gw4 $GW && echo "IP set to $IP/$NETMASK. GW set to $GW"
				nmcli con mod "$IFACE" ipv4.dns "$DNS0,$DNS1" && echo "DNS set to $DNS0,$DNS1"
		fi

		# Set Hostname
		date +"%m.%d.%Y %T " ; echo "Setting Hostname..."
		hostnamectl set-hostname $HOSTNAME --static

		# Notification for future
		date +"%m.%d.%Y %T "
		echo "This script will not be executed on next boot if $STATE file exists"
		echo "If you want to execute this configuration on Next boot remove $STATE file"

		date +"%m.%d.%Y %T " ; echo "Creating State file"
		date > $STATE

		# Wait a bit and reboot
		sleep 5
		reboot
fi
