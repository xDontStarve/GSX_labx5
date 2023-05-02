#!/bin/bash
# Script to set up a Linux container to function as a DNS server, managing two networks (DMZ & Intranet).
# Author: Jialiang Chen
# Date: 01-05-2023
# Note: Sudo needed to execute apt install commands, or become a superuser.

#Uncomment to delete previous config files [PROCEED WITH CAUTION]
#rm named.conf.local named.conf.options db.192 db.203 db.gsx.gei db.gsx.int

#Check for packages

if ! dpkg -s bind9 >/dev/null 2>/dev/null; then
	apt install -y  bind9 >/dev/null
else
	echo "[OK] bind9 is installed."
fi

if ! dpkg -s bind9-doc >/dev/null 2>/dev/null; then
	apt install -y bind9-doc >/dev/null
else
	echo "[OK] bind9-doc is installed."
fi

if ! dpkg -s dnsutils >/dev/null 2>/dev/null; then
	apt install -y dnsutils
else
	echo "[OK] dnsutils is installed"
fi

#Create config files
touch ./named.conf.local

echo -e "zone \"gsx.int\" {
	type master;
	file \"/etc/bind/db.gsx.int\";
};
" >> ./named.conf.local

echo -e "zone \"gsx.gei\" {
	type master;
	file \"/etc/bind/db.gsx.gei\";
};
" >> ./named.conf.local

echo -e "zone \"0.168.192.in-addr.arpa\" {
	type master;
	file \"/etc/bind/db.192\";
};
" >> ./named.conf.local

echo -e "zone \"113.0.203.in-addr.arpa\" {
	type master;
	file \"/etc/bind/db.203\";
};
" >> ./named.conf.local

#Create & Configure named.conf.options
touch ./named.conf.options

echo -e "options {
        directory \"/var/cache/bind\";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable 
        // nameservers, you probably want to use them as forwarders.  
        // Uncomment the following block, and insert the addresses replacing 
        // the all-0's placeholder.

        forwarders { 10.45.1.2; 193.144.16.4; };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-validation no;

        listen-on-v6 { any; };

	allow-recursion { 192.168.0.0/18; 203.0.113.32/27; };
	allow-transfer { localhost; 192.168.63.254; };

};" > ./named.conf.options

#Configure /etc/default/named to listen to IPv4

echo -e "#
# run resolvconf?
RESOLVCONF=no

# startup options for the server
OPTIONS=\"-u bind -4\"" > /etc/default/named

#Edit zone files

echo -e "\$TTL	86400
@	IN	SOA	ns.gsx.int. root.ns.gsx.int. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
; Name Server / hosts
@	IN	NS	ns.gsx.int.
ns	IN	A	192.168.0.1
router	IN	A	192.168.0.1
dhcp	IN	A	192.168.0.1

@	IN	MX  10	correu.gsx.int.
correu	IN	A	192.168.0.1
smtp	IN	CNAME	correu
pop3	IN	CNAME	correu

; Hosts
admin	IN	A	192.168.63.254
pc1	IN	A	192.168.0.2
pc2	IN	A	192.168.0.3
pc3	IN	A	192.168.0.4
pc4	IN	A	192.168.0.5
pc5	IN	A	192.168.0.6
pc6	IN	A	192.168.0.7
pc7	IN	A	192.168.0.8
pc8	IN	A	192.168.0.9
pc9	IN	A	192.168.0.10
pc10	IN	A	192.168.0.11
pc11	IN	A	192.168.0.12
pc12	IN	A	192.168.0.13
pc13	IN	A	192.168.0.14
pc14	IN	A	192.168.0.15
pc15	IN	A	192.168.0.16
" > ./db.gsx.int


echo -e "\$TTL	86400
@	IN	SOA	ns.gsx.gei. root.ns.gsx.gei. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
; Name Server / hosts
@	IN	NS	ns.gsx.gei.
ns	IN	A	203.0.113.33
router	IN	A	203.0.113.33
dhcp	IN	A	203.0.113.33
ldap	IN	A	203.0.113.62
www	IN	A	203.0.113.62

@	IN	MX  10	correu.gsx.gei.
correu 	IN	A	203.0.113.33
smtp	IN	CNAME	correu
pop3	IN	CNAME	correu


" > ./db.gsx.gei

echo -e "\$TTL	86400
@	IN	SOA	ns.gsx.int. root.ns.gsx.int. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
; Name Server / hosts
@	IN	NS	ns.gsx.gei.
33.113.0.203.in-addr.arpa.	IN	PTR	ns.gsx.gei.
62.113.0.203.in-addr.arpa.	IN	PTR	ldap.gsx.gei.
62.113.0.203.in-addr.arpa.	IN	PTR	www.gsx.gei.

" > ./db.203

echo -e "\$TTL	86400
@	IN	SOA	ns.gsx.int. root.ns.gsx.int. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			  86400 )	; Negative Cache TTL
; Name Server / hosts
@	IN	NS	ns.gsx.int.

; Services
;	PTR	Records
2	IN	PTR	pc1.gsx.int.
3	IN	PTR	pc2.gsx.int.
4	IN	PTR	pc3.gsx.int.
5	IN	PTR	pc4.gsx.int.
6	IN	PTR	pc5.gsx.int.
7	IN	PTR	pc6.gsx.int.
8	IN	PTR	pc7.gsx.int.
9	IN	PTR	pc8.gsx.int.
10	IN	PTR	pc9.gsx.int.
11	IN	PTR	pc10.gsx.int.
12	IN	PTR	pc11.gsx.int.
13	IN	PTR	pc12.gsx.int.
14	IN	PTR	pc13.gsx.int.
15	IN	PTR	pc14.gsx.int.
16	IN	PTR	pc15.gsx.int.		
1	IN	PTR	router.gsx.int.
254	IN	PTR	admin.gsx.int.
1	IN	PTR	ns.gsx.int.
1	IN	PTR	dhcp.gsx.int.
1	IN	PTR	smtp.gsx.int.
1	IN	PTR	pop3.gsx.int.
1	IN	PTR	correu.gsx.int.
" > ./db.192

#copy files over
chmod 644 named.conf.options
chown 644 named.conf.options
chmod 644 named.conf.local
chown 644 named.conf.local
chmod 644 db.192
chown 644 db.192
chmod 644 db.203
chown 644 db.203
chmod 644 db.gsx.int
chown 644 db.gsx.int
chmod 644 db.gsx.gei
chown 644 db.gsx.gei

cp -p named.conf.options /etc/bind/named.conf.options
cp -p named.conf.local /etc/bind/named.conf.local
cp -p db.192 db.203 db.gsx.int db.gsx.gei /etc/bind/

echo "removing local temporary files..."
rm named.conf.options named.conf.local db.192 db.203 db.gsx.gei db.gsx.int

#Delete dnat rules if exist:
echo "deleting port 53 dnat rules ..." 
iptables -D PREROUTING -d 203.0.113.33 -i eth1 -p tcp -m tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2> /dev/null
iptables -D PREROUTING -d 192.168.0.1 -i eth2 -p tcp -m tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2> /dev/null
iptables -D PREROUTING -d 203.0.113.33 -i eth1 -p udp -m udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2> /dev/null
iptables -D PREROUTING -d 192.168.0.1 -i eth2 -p udp -m udp --dport 53 -j DNAT --to-destination 8.8.8.8:53 2> /dev/null
#Reject ingoing DNS requests:
iptables -A FORWARD -p tcp --dport 53 -j DROP
iptables -A FORWARD -p udp --dport 53 -j DROP

#Uncomment the following lines if nat rules cannot be deleted.
#iptables -t nat -D PREROUTING 1
#iptables -t nat -D PREROUTING 1
#iptables -t nat -D PREROUTING 1
#iptables -t nat -D PREROUTING 1

#Labx5 dhclient.conf
grep "gsx.int" /etc/dhcp/dhclient.conf > /dev/null
if [[ $? -ne 0 ]]; then
	echo -e "supersede domain-name \"gsx.gei\";
supersede domain-search \"gsx.int\", \"gsx.gei\";
prepend domain-name-servers 127.0.0.1;
" >> /etc/dhcp/dhclient.conf
fi
ifdown eth0
ifup eth0

#Restart  DNS
systemctl restart bind9
echo "restarting dns..."
systemctl restart named
