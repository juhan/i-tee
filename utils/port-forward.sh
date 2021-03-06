#!/bin/bash

#Port forwarding script
for ip in $(seq 102 220); do
/sbin/iptables -t nat -A PREROUTING -p tcp -i br0 -d 192.168.13.2 --dport 8${ip} -j DNAT --to 192.168.13.${ip}:4200
done


for ip in $(seq 102 220); do
/sbin/iptables -t nat -A PREROUTING -p tcp -i br1 -d 193.40.194.185 --dport 8${ip} -j DNAT --to 192.168.13.${ip}:4200
done

