#! /bin/bash
# Author: Jialiang Chen
# Date: 08-03-2023
# Initialization script for router container
#
# Router's IP = 203.0.113.33
# Server's IP = 203.0.113.62

#Labx5 dhclient.conf
grep "gsx.int" /etc/dhcp/dhclient.conf > /dev/null
if [[ $? -ne 0 ]]; then
	echo -e "supersede domain-name \"gsx.int, gsx.gei\";
prepend domain-name-servers 127.0.0.1;
" >> /etc/dhcp/dhclient.conf
fi

# A)
ip -f inet addr show eth1 | grep "203.0.113.33" > /dev/null
if [ $? -ne 0 ]; then
	ip address add 203.0.113.33/27 broadcast \ 203.0.113.63 dev eth1
else
	echo "ip address is already set up for router."
fi
ip link set eth1 up

# B)
sysctl -w net.ipv4.ip_forward=1

# C)
cat /etc/hosts | grep -e $'203.0.113.62\tserver' > /dev/null
if [ $? -ne 0 ]; then
	echo -e "203.0.113.62\tserver" >> /etc/hosts
else
	echo "hosts is already set up for router."
fi

# D)

# Flush existing rules
iptables -F
iptables -t nat -F

# Check if the first rule exists
if ! iptables-save -t nat | grep -q "POSTROUTING -s 203.0.113.32/27 -o eth0 -j MASQUERADE"; then
	echo "SNAT for DMZ does not exist, setting it up ..."
	iptables -t nat -A POSTROUTING -s 203.0.113.32/27 -o eth0 -j MASQUERADE
else
	echo "iptables is already set up."
fi

# E)
echo "searching for ssh services..."
grep ssh /etc/services > /dev/null
echo "searching for processes that are listening to tcp/numeric..."
ss -4ltn
echo "checking if SSH is installed..."
dpkg -s openssh-server > /dev/null
if [ $? -ne 0 ]; then
	echo "ATTENTION: ssh not installed.\nProceding to install SSH..."
	apt install -y openssh-server > /dev/null
	systemctl status ssh > /dev/null
	ss -4lnt | grep ":22"
else
	echo "SSH is installed."
fi

grep $'PermitRootLogin\tyes' /etc/ssh/sshd_config > /dev/null
if [ $? -ne 0 ]; then
	echo "Setting PermitRootLogin to yes"
	echo -e 'PermitRootLogin\tyes' >> /etc/ssh/sshd_config
else
	echo "PermitRootLogin is already set to yes"
fi

echo "Restarting SSH..."
systemctl restart ssh


# Author: Jialiang Chen
# Date: 26-03-2023
# Initialization script for router container
#
# Router's IP = 192.168.0.1
# Broadcast = 192.168.63.255
# Gateway (eth0)
# Note: Sudo is needed to change the IP configuration.


#Setting up eth2
ip -f inet addr show eth2 | grep "192.168.0.1" > /dev/null
if [ $? -ne 0 ]; then
	echo "*IP address not set uo for eth2, setting it up now ..."
	ip address add 192.168.0.1/18 broadcast \ 192.168.63.255 dev eth2
else
	echo "OK: IP address is already set up for eth2."
fi
ip link set eth2 up

# Configure DHCP server:
dpkg -s isc-dhcp-server | grep "Status: install ok installed" > /dev/null
if [ $? -ne 0 ]; then
	echo "*isc-dhcp-server package not installed, proceeding to install..."
	apt install -y isc-dhcp-server
else
	echo "OK: isc-dhcp-server is installed."
fi
# Checking if DHCP is listening to eth1/2
cat /etc/default/isc-dhcp-server | grep 'INTERFACESv4="eth1 eth2"' > /dev/null
if [ $? -ne 0 ] ; then
	echo "*isc-dhcp-server is not listening to eth1 and eth2, proceeding to change it..."
	sed -i 's/INTERFACESv4=""/INTERFACESv4="eth1 eth2"/g' /etc/default/isc-dhcp-server
else
	echo "OK: DHCP already listening to eth1 and eth2."
fi
# Check /etc/dhcp/dhcpd.conf
cat /etc/dhcp/dhcpd.conf | grep 'subnet 192.168.0.0 netmask 255.255.192.0' > /dev/null
if [ $? -ne 0 ]; then
	echo "*subnet 192.168.0.0 not set up, proceeding to do so"
	echo -e "subnet 192.168.0.0 netmask 255.255.192.0 {\n  range 192.168.0.2 192.168.63.253;\n  option subnet-mask 255.255.192.0;\n  option broadcast-address 192.168.63.255;\n  option domain-name \"gsx.int\";\n  option domain-search \"gsx.int\", \"gsx.gei\";\n  option routers 192.168.0.1;\n  option domain-name-servers 192.168.0.1;\n  max-lease-time 86400;\n  default-lease-time 28800;\n}" >> /etc/dhcp/dhcpd.conf
else
	echo "OK: subnet 192.168.0.0 is already set up."
fi

cat /etc/dhcp/dhcpd.conf | grep 'subnet 203.0.113.32 netmask 255.255.255.224' > /dev/null
if [ $? -ne 0 ]; then
	echo "*subnet 203.0.113.32 not set up, proceeding to do so"
	echo -e "subnet 203.0.113.32 netmask 255.255.255.224 {\n  range 203.0.113.34 203.0.113.61;\n  option broadcast-address 203.0.113.63;\n  option domain-name \"gsx.gei\";\n  option domain-search \"gsx.int\", \"gsx.gei\";\n  option routers 203.0.113.33;\n  option domain-name-servers 203.0.113.33;\n  max-lease-time 86400;\n  default-lease-time 28800;\n}" >> /etc/dhcp/dhcpd.conf
else
	echo "OK: subnet 203.0.113.32 is already set up."
fi

cat /etc/dhcp/dhcpd.conf | grep 'host server' > /dev/null
if [ $? -ne 0 ]; then
	echo "*Host Server not set up, proceeding to do so"
	echo -e "host server {\n  hardware ethernet 92:6f:e6:d7:78:52;\n  fixed-address 203.0.113.62;\n  default-lease-time -1;\n  max-lease-time -1;\n  option host-name \"server\";\n}" >> /etc/dhcp/dhcpd.conf
else
	echo "OK: Host already set up."
fi

cat /etc/dhcp/dhcpd.conf | grep 'host admin' > /dev/null
if [ $? -ne 0 ]; then
	echo "*Host Admin not set up, proceeding to do so"
	echo -e "host admin {\n  hardware ethernet ca:99:ea:89:55:bf;\n  fixed-address 192.168.63.254;\n  default-lease-time -1;\n  max-lease-time -1;\n  option host-name \"admin\";\n}" >> /etc/dhcp/dhcpd.conf
else
	echo "OK: Admin is already set up."
fi

systemctl restart isc-dhcp-server
# Adding default gateway
ip route add default via 10.0.2.2 dev eth0
# Check if the second rule exists
if ! iptables-save -t nat | grep -q "POSTROUTING -s 192.168.0.0/18 -o eth0 -j MASQUERADE"; then
	echo "Setting up SNAT for intranet"
	iptables -t nat -A POSTROUTING -s 192.168.0.0/18 -o eth0 -j MASQUERADE
else
	echo "iptables is already set up."
fi

#Set SNAT
echo "Setting up SNAT for DNS requests..."
#iptables -t nat -A PREROUTING -i eth1 -d 203.0.113.33 -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53
#iptables -t nat -A PREROUTING -i eth2 -d 192.168.0.1 -p tcp --dport 53 -j DNAT --to-destination 8.8.8.8:53
#iptables -t nat -A PREROUTING -i eth1 -d 203.0.113.33 -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53
#iptables -t nat -A PREROUTING -i eth2 -d 192.168.0.1 -p udp --dport 53 -j DNAT --to-destination 8.8.8.8:53
