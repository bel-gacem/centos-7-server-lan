#!/bin/sh
#
# firewall-gateway.sh

# Commandes
IPT=/usr/sbin/iptables
MOD=/usr/sbin/modprobe
SYS=/usr/sbin/sysctl
SERVICE=/usr/sbin/service

# Internet
IFACE_INET=enp2s0

# Réseau local
IFACE_LAN=enp3s1
IFACE_LAN_IP=192.168.3.0/24

# Serveur
SERVER_IP=192.168.3.1

# Activer le relais des paquets ? (yes/no)
MASQ=yes

# Tout accepter
$IPT -t filter -P INPUT ACCEPT
$IPT -t filter -P FORWARD ACCEPT
$IPT -t filter -P OUTPUT ACCEPT
$IPT -t nat -P PREROUTING ACCEPT
$IPT -t nat -P POSTROUTING ACCEPT
$IPT -t nat -P OUTPUT ACCEPT
$IPT -t mangle -P PREROUTING ACCEPT
$IPT -t mangle -P INPUT ACCEPT
$IPT -t mangle -P FORWARD ACCEPT
$IPT -t mangle -P OUTPUT ACCEPT
$IPT -t mangle -P POSTROUTING ACCEPT

# Remettre les compteurs à zéro
$IPT -t filter -Z
$IPT -t nat -Z
$IPT -t mangle -Z

# Supprimer toutes les règles actives et les chaînes personnalisées
$IPT -t filter -F
$IPT -t filter -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X

# Désactiver le relais des paquets
$SYS -q -w net.ipv4.ip_forward=0

# Politique par défaut
$IPT -P INPUT DROP
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT

# Faire confiance à nous-mêmes ;o)
$IPT -A INPUT -i lo -j ACCEPT

# Ping
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT

# Connexions établies
$IPT -A INPUT -m state --state ESTABLISHED -j ACCEPT

# SSH local
$IPT -A INPUT -p tcp -i $IFACE_LAN --dport 22 -j ACCEPT

# SSH limité en provenance de l'extérieur
$IPT -A INPUT -p tcp -i $IFACE_INET --dport 22 -m state \
  --state NEW -m recent --set --name SSH
$IPT -A INPUT -p tcp -i $IFACE_INET --dport 22 -m state \
  --state NEW -m recent --update --seconds 60 --hitcount 2 \
  --rttl --name SSH -j DROP
$IPT -A INPUT -p tcp -i $IFACE_INET --dport 22 -j ACCEPT

# Activer le relais des paquets
if [ $MASQ = 'yes' ]; then
  $IPT -t nat -A POSTROUTING -o $IFACE_INET -s $IFACE_LAN_IP \
    -j MASQUERADE
  $SYS -q -w net.ipv4.ip_forward=1
fi

# Enregistrer les connexions refusées
$IPT -A INPUT -m limit --limit 2/min -j LOG \
  --log-prefix "+++ IPv4 packet rejected +++ "
$IPT -A INPUT -j DROP
  
# Enregistrer la configuration
$SERVICE iptables save
