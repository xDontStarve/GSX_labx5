#!/bin/sh

# Assignatura: GSX
# Autor: Josep M Banús Alsina
# Versió: 1.0

# Descripció:
# Comprova la configuració actual i la guarda
# a un fitxer (ex: 'sortida_admin_labx5.txt').
# Aquest fitxer l'adjuntareu al moodle 
# per a avaluar si ho heu fet bé.

# Execució: 
# Al contenidor admin: ./genera_sortida_labx5.sh
# Al final, quan ja us funcionin els scripts.

# Important:
############
# no modifiqueu aquest script ni els seus resultats,
# doncs l'avaluació no seria correcta.

qui=$(hostname -s)
case $qui in
	'admin')	peer='router'
		;;
	*)	echo "error en el hostname '$qui'"
		exit 1
esac
out="./sortida_${qui}_labx5.txt"

date > $out
echo HOSTNAME >> $out
hostname -f >>$out
echo >>$out

dgw=$(ip route | grep default | cut -f3 -d' ')
nmap -p U:53,T:22,53 $dgw >> $out
echo >>$out

echo RESOLVCONF >> $out
cat /etc/resolv.conf >>$out
echo >>$out

if [ -f /var/lib/dhcp/dhclient.eth0.leases ]; then
	n=$(grep -n "^lease" /var/lib/dhcp/dhclient.eth0.leases | tail -1 | cut -f1 -d':')
	nl=$(cat /var/lib/dhcp/dhclient.eth0.leases| wc -l)
	tail -$(($nl-$n+1)) /var/lib/dhcp/dhclient.eth0.leases >> $out
else
	echo "No existeix el fitxer de lloguers!" >> $out
fi

echo HOSTS >> $out
cat /etc/hosts >> $out
sed -i "/^[ 	]*203\.0\.113\..*$/d" /etc/hosts
sed -i "/^[ 	]*192\.168\..*$/d" /etc/hosts
ping -q -c1 -W1 router >> $out
ping -q -c1 -W1 admin >> $out
ping -q -c1 -W1 ldap >> $out

echo BOAXFR1 >>$out
dig AXFR gsx.gei >> $out
echo EOAXFR1 >>$out
echo >>$out
echo "ENTRA el passwd del root al router per a fer una connexió ssh que TARDARÂ"
echo BOAXFR2 >>$out
ssh $dgw "dig AXFR gsx.gei ; dig AXFR 113.0.203.in-addr.arpa. ; dig AXFR gsx.int ; dig AXFR 168.192.in-addr.arpa." >> $out
echo EOAXFR2 >>$out
echo >>$out
echo HOSTINET >>$out
host tinet.cat 8.8.8.8 >> $out
echo >>$out
