#!/bin/sh
#
#================================
# Hardened iptables Setup Script
#================================
#
# Basic template for hardened server iptables rules.
#
#Copyright (c) 2013 Nikita Solovyev
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
#2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
#in the documentation and/or other materials provided with the distribution.
#
#3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived 
#from this software without specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, 
#BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
#THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
#HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
#ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#clear existing rules in INPUT chain
iptables -F INPUT
#set DROP action by deafault for INPUT and FORWARD(unless the server is a router)
iptables -P INPUT DROP
iptables -P FORWARD DROP
#allow all outgoing traffic
iptables -P OUTPUT ACCEPT
#LOG and DROP if packet's source is from reserved subnets
iptables -A INPUT -s 10.0.0.0/8 -j LOG --log-prefix "DROP: "
iptables -A INPUT -s 172.16.0.0/12 -j LOG --log-prefix " DROP: "
iptables -A INPUT -s 192.168.0.0/16 -j LOG --log-prefix " DROP: "
iptables -A INPUT -s 224.0.0.0/4 -j LOG --log-prefix " DROP: "
iptables -A INPUT -s 240.0.0.0/5 -j LOG --log-prefix " DROP: "
#LOG and DROP if packet's source on etho in local subnet (should be on 'lo' only)
iptables -A INPUT –i eth0 -d 127.0.0.0/8 -j LOG --log-prefix " DROP: "
#allow all local connections
iptables -A INPUT -i lo -j ACCEPT
#don't allow packets in new TCP session unless it's a SYN 
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
#allow only ICMP replies and ping request for diagnosis and limit to 3 per second
iptables -A INPUT -p icmp --icmp-type echo-reply -m limit --limit 3/s --limit-burst 5  -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -m limit --limit 3/s --limit-burst 5 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded  -m limit --limit 3/s --limit-burst 5  -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request  -m limit --limit 3/s --limit-burst 5  -j ACCEPT
#drop all packets with invalid state
iptables –A INPUT –m state --state INVALID –j DROP
#drop all malformed packets
iptables –A INPUT –p tcp --tcp-flags ALL ALL –j DROP 
iptables –A INPUT –p tcp --tcp-flags ALL NONE –j DROP
iptables –A INPUT –p tcp --tcp-flags ALL FIN,URG,PSH –j DROP
iptables –A INPUT –p tcp --tcp-flags SYN,RST SYN,RST –j DROP
iptables –A INPUT –p tcp --tcp-flags SIN,FIN SYN,FIN –j DROP
#allow initiating access to server services, but limit throughput
#IMPORTANT: Comment out unused services!
#SSH, better change the port from default 22
iptables -A INPUT –m state –state NEW -p tcp --destination-port 2222 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#HTTP
iptables -A INPUT –m state –state NEW -p tcp --destination-port 80 -m limit --limit 30/s --limit-burst 50  -j ACCEPT
#HTTPS
iptables -A INPUT –m state –state NEW -p tcp --destination-port 443 -m limit --limit 30/s --limit-burst 50  -j ACCEPT
#SMTP/SMTPS relay
iptables -A INPUT –m state –state NEW -p tcp --destination-port 25 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#SMTP/SMTPS submission
iptables -A INPUT –m state –state NEW -p tcp --destination-port 587 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#POP3S
iptables -A INPUT –m state –state NEW -p tcp --destination-port 995 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#IMAPS
iptables -A INPUT –m state –state NEW -p tcp --destination-port 993 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#FTPS (active mode, passive mode may require additional port range to be enabled)
#iptables -A INPUT –m state –state NEW -p tcp --destination-port 21 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#SMTP/SMTPS submission (legacy)
#iptables -A INPUT –m state –state NEW -p tcp --destination-port 465 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#DNS
#iptables -A INPUT –m state –state NEW -p tcp --destination-port 53 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#POP3
#iptables -A INPUT –m state –state NEW -p tcp --destination-port 110 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#IMAP
#iptables -A INPUT –m state –state NEW -p tcp --destination-port 143 -m limit --limit 10/s --limit-burst 20  -j ACCEPT
#allow packets for already established connections, but limit throughput
iptables -A INPUT –m state –state ESTABLISHED -m limit --limit 10/s --limit-burst 20  -j ACCEPT
service iptables save
service iptables restart
exit 0;