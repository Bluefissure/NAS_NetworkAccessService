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
