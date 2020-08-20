#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

target=$1

portsTCP="Null"
portsUDP="Null"

if [[ $(id -u) -ne 0 ]]; then
	echo "[!] Please run as root"
	exit 2
else
	if [ $# -ne 1 ];then
		echo -e "${RED}[*] Usage: $0 <TARGET-IP> <TYPE>"
		exit 1
	else
		ifconfig tun0 &> /dev/null
		if [ $? -eq  0 ]; then
			if [[ $target =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
				echo -e "${GREEN}------------------------------------------------------------------------"
				echo -e "${GREEN}---------------------Starting Discovering TCP ports---------------------"
				echo -e "${GREEN}------------------------------------------------------------------------"
				echo -e "${NC}"
				echo -e "${YELLOW}nmap -p- --open -T5 -oG allPortsTCP $target -n"
				echo -e "${NC}"
				nmap -p- --open -T5 -oG allPortsTCP $target -n
				
				echo -e "${GREEN}------------------------------------------------------------------------"
				echo -e "${GREEN}---------------------Starting Discovering UDP ports---------------------"
				echo -e "${GREEN}------------------------------------------------------------------------"
				echo -e "${NC}"
				echo -e "${YELLOW}nmap -sU -open -top-ports 300 -T5 -oG allPortsUDP $target -n"
				echo -e "${NC}"
				nmap -sU -open -top-ports 300 -T5 -oG allPortsUDP $target -n
				
				if [ $? -eq 0 ]; then
					#portsTCP=$(cat tmptcp.grep | awk '{print $5}' | cut -d "/" -f1 | tr "\n" ",")
					portsTCP=$(cat allPortsTCP | grep -oP '\d{2,5}/open' | awk '{print $1}' FS="/" | xargs | tr ' ' ',')
					
				fi

				if [ $? -eq 0 ]; then
					portsUDP=$(cat allPortsUDP | grep -oP '\d{2,5}/open' | awk '{print $1}' FS="/" | xargs | tr ' ' ',')
				fi

				if [ $portsTCP != "Null" ]; then
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${GREEN}---------------------Starting Scan TCP ports NMAP-----------------------"
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${NC}"
					echo -e "${YELLOW}nmap $target -p $portsTCP -n -sC -sV -Pn -oA nmap"
					echo -e "${NC}"
					nmap $target -p $portsTCP -n -sC -sV -Pn -oA nmap.tcp

				fi
				if [ $portsUDP != "Null" ]; then
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${GREEN}----------------------Starting Scan UDP ports NMAP----------------------"
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${NC}"
					echo -e "${YELLOW}nmap $target -sU -p $portsUDP -n -sC -sV -Pn"
					echo -e "${NC}"
					nmap $target -sU -p $portsUDP -n -T4 -sC -sV -Pn -oA nmap.udp
					

				fi
				if [ $portsTCP != "Null" ]; then
					echo "[+] Vuln Scan TCP ports NMAP"
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${GREEN}--------------------Starting Vuln Scan TCP ports NMAP-------------------"
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${NC}"
					echo -e "${YELLOW}nmap -sV --script vuln -p$(echo "${portsTCP}") "$target""
					echo -e "${NC}"
					nmap -sV --script vuln -p$(echo "${portsTCP}") -oN Vulns_TCP_"$target".nmap "$target"
					
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${GREEN}----------------Starting Searchsploit TCP services Check----------------"
					echo -e "${GREEN}------------------------------------------------------------------------"
					echo -e "${NC}"
					searchsploit --nmap nmap.tcp.xml | tee searchsploit-tcp

				fi
				
				#if [ $portsUDP != "Null" ]; then
					#echo -e "${GREEN}------------------------------------------------------------------------"
					#echo -e "${GREEN}-------------------Starting Vuln Scan UDP ports NMAP--------------------"
					#echo -e "${GREEN}------------------------------------------------------------------------"
					#echo -e "${NC}"
					#echo -e "${YELLOW}nmap -sV --script vuln -p$(echo "${portsUDP}") "$target""
					#echo -e "${NC}"
					#nmap -sV --script vuln -p$(echo "${portsUDP}") -oN Vulns_UDP_"$target".nmap "$target"
					
					#echo -e "${GREEN}------------------------------------------------------------------------"
					#echo -e "${GREEN}----------------Starting Searchsploit UDP services Check----------------"
					#echo -e "${GREEN}------------------------------------------------------------------------"
					#echo -e "${NC}"
					#searchsploit --nmap nmap.udp.xml | tee searchsploit-udp

				#fi
				echo -e "${RED}-------------------------------------------------------"
				echo -e "${YELLOW}---------------------Scan Finished---------------------"
				echo -e "${RED}-------------------------------------------------------"
			else
				echo -e "${RED}[!] Invalid IP"
				exit 2
			fi
		else
			echo "[-] You are not connected to OSCP VPN"
		fi
	fi
fi
