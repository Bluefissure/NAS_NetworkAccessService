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
	cat > /etc/dhcp/dhcpd.conf  <<-EOF
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;
authoritative;
subnet 10.1.1.0 netmask 255.255.255.0 {
  range 10.1.1.200 10.1.1.250;
  option broadcast-address 10.1.1.255;
  option domain-name-servers 8.8.8.8,114.114.114.114;
  option routers 10.1.1.1;
}
EOF
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
	cat > /var/www/html/index.html <<-EOF
<html><head>
<meta http-equiv="refresh" content="0; url=http://10.1.1.1/login.htm">
</head>
<body><h1>It works!</h1></body>
</html>
EOF
	cat > /var/www/html/login.htm <<-EOF
<html><title>Login</title><body>
<form name=form1 method=post action="/cgi-bin/checkin.cgi">
<br>
Account:<INPUT TYPE="text" NAME="username" value="user1">
<br><br>
Password:<INPUT TYPE="password" NAME="password" value="passwd">
<br><br>
<INPUT type="radio" CHECKED value="I" name=inout><LABEL>Login</LABEL>
<INPUT type="radio" value="D" name=inout><LABEL>Logout</LABEL>
<br><br>
<INPUT TYPE="submit" VALUE="Submit">
</form></body></html>

EOF
	
	mv /etc/apache2/apache2.conf /etc/apache2/bak.apache2.conf
	cat > /etc/apache2/apache2.conf <<-EOF

ServerRoot "/etc/apache2"
Mutex file:${APACHE_LOCK_DIR} default
PidFile ${APACHE_PID_FILE}
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}
HostnameLookups Off
ErrorLog ${APACHE_LOG_DIR}/error.log
LoadModule cgid_module /usr/lib/apache2/modules/mod_cgid.so
LogLevel warn
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
Include ports.conf

ErrorDocument 404 http://10.1.1.1/redir.htm
<Directory />
	Options FollowSymLinks
	AllowOverride None
	Require all denied
</Directory>

<Directory /usr/share>
	AllowOverride None
	Require all granted
</Directory>

<Directory /var/www/html>
	AllowOverride none
	Options Indexes FollowSymLinks
	Require all granted
</Directory>

<Directory /usr/lib/cgi-bin>
	Options ExecCGI
	AllowOverride None
	Require all granted
</Directory>

AccessFileName .htaccess

<FilesMatch "^\.ht">
	Require all denied
</FilesMatch>

LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent
IncludeOptional conf-enabled/*.conf
IncludeOptional sites-enabled/*.conf

EOF

	cat > /var/www/html/redir.htm <<-EOF
<html><head>
<meta http-equiv="refresh" content="0; url=http://10.1.1.1/login.htm">
</head>
<body>wait 0 second...<br></body>
</html>
EOF
	service apache2 restart
	
	
	which iptables 
	chmod +s `which iptables`
	cat > /usr/lib/cgi-bin/checkin.cgi <<-EOF
#!/bin/sh


echo "Content-type: text/html"
echo 
echo ""

# 
if [ "$REQUEST_METHOD" = "GET" ] ; then
	echo "GET is not expected without https"
	exit                         
fi

#
echo "<html><head>"
#echo '<meta http-equiv="refresh" content="3; url=http://www.sdu.edu.cn/">'
echo "</head><body>"
echo "<pre>"


ip=$REMOTE_ADDR

OIFS="$IFS"
IFS=\&                  
read user passwd inout  
IFS="$OIFS"

user=${user#username=}        # 
passwd=${passwd#password=}    #
inout=${inout#inout=}         #

echo "user, passwd and your ip is: $user $passwd $ip"

userconf='/etc/nasuser.list'    # 
grepstr="grep $userconf -e $user | grep $passwd" # | grep $ip"
userline=`$grepstr`
if [ -z "$userline" ] ; then         
	echo "invalid user"   # 
    exit
fi

echo "ok"

# 
iptcmd1="/sbin/iptables -t nat -D PREROUTING -s $ip/32 -j ACCEPT"
iptcmd2="/sbin/iptables -t nat -I PREROUTING -s $ip/32 -j ACCEPT"
iptcmd3="/sbin/iptables -t filter -D FORWARD -s $ip/32 -o ${eth0} -j ACCEPT"
iptcmd4="/sbin/iptables -t filter -I FORWARD -s $ip/32 -o ${eth0} -j ACCEPT"
#

echo 'before: ipv4'
/sbin/iptables --list -n | grep all
/sbin/iptables --list -n -t nat | grep all


echo ""
echo "action:"
echo $iptcmd1
res=`$iptcmd1`
echo $iptcmd3
res=`$iptcmd3`
if [ $inout = "I" ] ; then
echo $iptcmd2
res=`$iptcmd2`
echo $iptcmd4
res=`$iptcmd4`
fi

echo ""
echo 'after: ipv4'
/sbin/iptables --list -n | grep all
/sbin/iptables --list -n -t nat | grep all


echo "</pre>"

if [ $inout = "I" ] ; then
echo "<font color=red> <strong>Reload if Error occur.</strong>"
fi

echo "</body></html>"

exit
EOF
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
	echo "Test your inner connection now."
	echo "Press any key to continue setting access control......"
	read
	
	conf_apache
	iptables -t nat -F
	iptables -t filter -F 
	iptables -t mangle -F
	iptables -F
	iptables -t filter -A FORWARD -s 10.1.0.0/16 -d 202.194.15.12/32 -j ACCEPT
	iptables -t filter -A FORWARD -s 10.1.0.0/16 -o ${eth0} -j DROP
	iptables -t nat -A PREROUTING -s 10.1.0.0/16 -p tcp -j DNAT --to 10.1.1.1
	iptables -t nat -A POSTROUTING -s 10.1.0.0/16 -o ${eth0} -j MASQUERADE
	#iptables -t nat -I PREROUTING -s 10.x.y.z/32 -j ACCEPT
	#iptables -t filter -I FORWARD -s 10.x.y.z/32 -o $eth0 -j ACCEPT
}


rootness
checkos
conf_network_adapter
conf_dhcp
conf_iptables




