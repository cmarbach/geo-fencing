#!/bin/bash
# Purpose: Allow traffic only from specific countries and denying all others (based on ISO_CODES)
# See url for more info - http://www.cyberciti.biz/faq/?p=3402
# Author: C. Marbacher @ 2015
# -------------------------------------------------------------------------------

#
### Configuration section ###
#

# Countries to allow access
ISO="ch fr"

# Subnets that have access
TRUSTEDSUBNETS="10.0.0.0/8
172.16.0.0/12
192.168.0.0/16"

### Set PATH ###
IPT=/sbin/iptables
WGET=/usr/bin/wget
EGREP=/bin/egrep

#
### No editing below ###
#

ZONEROOT="/opt/geo-fencing/data"
DLROOT="http://www.ipdeny.com/ipblocks/data/countries"

# clean up old rules
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X
$IPT -P INPUT DROP
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD DROP
$IPT -N TRUSTED
$IPT -N COUNTRY
$IPT -A INPUT -i lo -s 127.0.0.1/32 -j ACCEPT
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -j TRUSTED

# allow trusted subnets
for subnet in $TRUSTEDSUBNETS
do
    echo "INF: Allow trusted subnet $subnet"
    $IPT -A TRUSTED -s $subnet -j ACCEPT
done

# accept incoming SMTP traffic
$IPT -I INPUT 1 -p tcp --dport 25 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# After trusted subnets, jump to trusted countries
$IPT -A TRUSTED -j COUNTRY

# create a dir
[ ! -d $ZONEROOT ] && /bin/mkdir -p $ZONEROOT

for c in $ISO
do
    echo "INF: Downloading subnets for country $c"
    # local zone file
    tDB=$ZONEROOT/$c.zone

    # get fresh zone file
    $WGET -q -O $tDB $DLROOT/$c.zone
    if [ $? -ne 0 ]
    then
            echo "ERR: Failed downloading IPs for country $c"
            # jump to next country
            continue
    fi
done

for c  in $ISO
do
    echo "INF: Allowing country $c"
    # local zone file
    tDB=$ZONEROOT/$c.zone
    if [ -e $tDB ]
    then
            # get clean ipblocks
            GOODIPS=$(egrep -v "^#|^$" $tDB)
            for ipblock in $GOODIPS
            do
                    $IPT -A COUNTRY -s $subnet -j LOG --log-prefix "geo-fencing - country $c allowed :"
                    $IPT -A COUNTRY -s $ipblock -j ACCEPT
            done
    fi
done
# If the source IP was not allowed, then it must be blocked and logged
$IPT -A COUNTRY -j LOG --log-prefix "geo-fencing - blocked IP:"
$IPT -A COUNTRY -j DROP

# Save rules for quick load at next reboot
echo "INF: Saving rules for next time"
/sbin/iptables-save > /opt/geo-fencing/iptables.rules

echo "INF: Terminated"
exit 0


