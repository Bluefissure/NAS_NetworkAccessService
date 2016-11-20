#!/usr/bin/env bash

clear
echo ""
echo "#############################################################"
echo "# One click NAS(Network Access Service) Setting Shell       #"
echo "# Author: Bluefissure                                       #"
echo "# Thanks: Shutao Bai, Yuanfa Fang                           #"
echo "#############################################################"
echo ""
eth0=`ifconfig|grep "Link encap:Ethernet"|cut -d ' ' -f 1|head -1`
eth1=`ifconfig|grep "Link encap:Ethernet"|cut -d ' ' -f 1|tail -1`

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

# Check OS
function checkos(){
    if [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS=Ubuntu
    else
        echo "Not supported OS, Please reinstall OS as Ubuntu and retry!"
        exit 1
    fi
	echo "Updating software......"
}


#Configure network adapter
function conf_network_adapter(){
	echo "Press any key to configure Network Adapter......"
	read
	echo "Your External network adapter is $eth0"
	if [[ ${eth1} = ${eth0} ]]; then
			echo "No Inner network adapter"
			exit
	fi
	echo "Your Inner network adapter is $eth1"
	cat > /etc/network/interfaces <<-EOF
source /etc/network/interfaces.d/*
auto ${eth0}
iface ${eth0} inet dhcp
#
auto ${eth1}
iface ${eth1} inet static
address 10.1.1.1
netmask 255.255.255.0
# The loopback network interface
auto lo
iface lo inet loopback
EOF
	service networking restart
}





#Configure dhcp
function conf_dhcp(){
	echo "Press any key to configure DHCP Service......"
	read
	echo "Installing isc-dhcp-server......"
	apt-get -y install isc-dhcp-server
	
	mv /etc/dhcp/dhcpd.conf  /etc/dhcp/bak.dhcpd.conf 
	if [ ! -f "dhcpd.conf" ]; then
        wget --no-check-certificate https://raw.githubusercontent.com/Bluefissure/NAS_NetworkAccessService/master/dhcpd.conf
	else
		echo "dhcpd.conf exists"
	fi
	mv dhcpd.conf /etc/dhcp/
	
	service isc-dhcp-server restart
	sysctl -w net.ipv4.ip_forward=1
}

#Configure apache
function conf_apache(){
	echo "Press any key to configure Apache......"
	read
	echo "Installing Apache......"
	apt-get -y install apache2
	
	mv /var/www/html/index.html /var/www/html/bak_index.html
	
	if [ ! -f "index.html" ]; then
        wget --no-check-certificate https://raw.githubusercontent.com/Bluefissure/NAS_NetworkAccessService/master/index.html
	else
		echo "index.html exists"
	fi
	
	mv index.html /var/www/html/
	if [ ! -f "login.htm" ]; then
        wget --no-check-certificate https://raw.githubusercontent.com/Bluefissure/NAS_NetworkAccessService/master/login.htm
	else
		echo "login.htm exists"
	fi
	mv login.htm /var/www/html/
	
	
	mv /etc/apache2/apache2.conf /etc/apache2/bak.apache2.conf
	if [ ! -f "apache2.conf" ]; then
        wget --no-check-certificate https://raw.githubusercontent.com/Bluefissure/NAS_NetworkAccessService/master/apache2.conf
	else
		echo "apache2.conf exists"
	fi
	mv apache2.conf /etc/apache2/
	

	if [ ! -f "redir.htm" ]; then
        wget --no-check-certificate https://raw.githubusercontent.com/Bluefissure/NAS_NetworkAccessService/master/redir.htm
	else
		echo "redir.htm exists"
	fi
	mv redir.htm /var/www/html/
	
	
	service apache2 restart
	
	
	which iptables 
	chmod +s `which iptables`
	if [ ! -f "checkin.cgi" ]; then
        wget --no-check-certificate https://raw.githubusercontent.com/Bluefissure/NAS_NetworkAccessService/master/checkin.cgi
	else
		echo "checkin.cgi exists"
	fi
	sed -i "s/eth0/$eth0/g" checkin.cgi
	mv checkin.cgi /usr/lib/cgi-bin/
	chmod +x /usr/lib/cgi-bin/checkin.cgi

	
	cat > /etc/nasuser.list <<-EOF
cngi  passwd
user1 passwd
user2 passwd
user3 passwd
EOF


}

#Configure iptables
function conf_iptables(){
	echo "Press any key to configure iptables......"
	read
	echo "Installing iptables......"
	apt-get -y install iptables
	iptables -t nat -F
	iptables -t filter -F 
	iptables -t mangle -F
	iptables -F
	iptables -t nat -A POSTROUTING -s 10.1.1.0/24 -o $eth0 -j MASQUERADE
	iptables-restore < /etc/iptables.rules
	clear
	echo "Test your inner connection now."
	echo "Press any key to continue setting access control......"
	read
	
	conf_apache
	sysctl -w net.ipv4.ip_forward=1
	iptables -F
	iptables -t nat -F
	iptables -t filter -F 
	iptables -t mangle -F
	iptables -t filter -A FORWARD -s 10.1.0.0/16 -d 8.8.8.8/32 -j ACCEPT
	iptables -t filter -A FORWARD -s 10.1.0.0/16 -o ${eth0} -j DROP
	iptables -t nat -A PREROUTING -s 10.1.0.0/16 -p tcp -j DNAT --to 10.1.1.1
	iptables -t nat -A POSTROUTING -s 10.1.0.0/16 -o ${eth0} -j MASQUERADE
	#iptables -t nat -I PREROUTING -s 10.x.y.z/32 -j ACCEPT
	#iptables -t filter -I FORWARD -s 10.x.y.z/32 -o $eth0 -j ACCEPT
	clear
	echo "Complete, test NAS now."
}


rootness
checkos
conf_network_adapter
conf_dhcp
conf_iptables




