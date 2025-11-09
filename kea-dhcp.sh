#!/bin/bash


sudo dnf -y update
sudo dnf -y install kea
interface2=$(ip -brief addr | grep UP | sed -n '2p' | awk '{print $1}')
  echo "Escolha a tua rede:"
  read rede

	echo "Escolha o teu ip:"
	read ip

	#Inserir Gateway
	echo "Defina o gateway:"
	read gateway

	#Inserir DNS
	echo "Escolha o teu DNS:"
	read dns
 

  echo "Insere o IP inicial da Pool:"
  read ip_start
  echo "Insere o IP final da Pool:"
  read ip_end


sudo ip link set "$interface2" up
sudo ip addr add "$ip" dev "$interface2"
sudo ip route add default via "$gateway"

echo "Qual é o teu domínio?"
read domain


echo "
{
  "\"Dhcp4\"": {
    "\"interfaces-config\"": {
      "\"interfaces\"": [ "\"$interface2\"" ] 
    },

    "\"expired-leases-processing\"": {
      "\"reclaim-timer-wait-time\"": 10,
      "\"flush-reclaimed-timer-wait-time\"": 25,
      "\"hold-reclaimed-time\"": 3600,
      "\"max-reclaim-leases\"": 100,
      "\"max-reclaim-time\"": 250,
      "\"unwarned-reclaim-cycles\"": 5
    },

    "\"renew-timer\"": 900,         
    "\"rebind-timer\"": 1800,       
    "\"valid-lifetime\"": 3600,     

    "\"option-data\"": [
      {
        "\"name\"": "\"domain-name-servers\"",
        "\"data\"": "\"$dns\""       
      },
      {
        "\"name\"": "\"domain-name\"",
        "\"data\"": "\"$domain\""     
      },
      {
        "\"name\"": "\"domain-search\"",
        "\"data\"": "\"$domain\""     
      }
    ],

    "\"subnet4\"": [
      {
        "\"id\"": 1,
        "\"subnet\"": "\"$rede\"", 
        "\"pools\"": [
          { "\"pool\"": "\"$ip_start - $ip_end\"" } 
        ],
        "\"interface\"": "\"$interface2\"",
        "\"option-data\"": [
          {
            "\"name\"": "\"routers\"",
            "\"data\"": "\"$gateway\""   
          }
        ]
      }
    ],

    "\"loggers\"": [
      {
        "\"name\"": "\"kea-dhcp4\"",
        "\"output-options\"": [
          {
            "\"output\"": "\"/var/log/kea/kea-dhcp4.log\""
          }
        ],
        "\"severity\"": "\"INFO\"",
        "\"debuglevel\"": 0
      }
    ]
  }
}
" > dhcp.txt

sudo mv dhcp.txt /etc/kea/kea-dhcp4.conf

sudo chown root:kea /etc/kea/kea-dhcp4.conf
sudo chmod 640 /etc/kea/kea-dhcp4.conf
sudo systemctl enable --now kea-dhcp4

sudo firewall-cmd --add-service=dhcp
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --reload

sudo systemctl start kea-dhcp4
