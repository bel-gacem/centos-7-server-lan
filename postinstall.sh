#!/bin/bash
#
# postinstall.sh
#
# Script post-installation pour serveur LAN CentOS 7
#
# (c) Nicolas Kovacs, 2018

# Exécuter en tant que root
if [ $EUID -ne 0 ] ; then
  echo "::"
  echo ":: Vous devez être root pour exécuter ce script."
  echo "::"
  exit 1
fi

# Répertoire courant
CWD=$(pwd)

# Interrompre en cas d'erreur
set -e

# Couleurs
VERT="\033[01;32m"
GRIS="\033[00m"

# Journal
LOG=/tmp/postinstall.log

# Pause entre les opérations
DELAY=1

# Nettoyer le fichier journal
echo > $LOG

# Bannière
sleep $DELAY
echo
echo "     ##############################################" | tee -a $LOG
echo "     ### Serveur LAN CentOS 7 Post-installation ###" | tee -a $LOG
echo "     ##############################################" | tee -a $LOG
echo | tee -a $LOG
sleep $DELAY
echo "     Pour suivre l'avancement des opérations, ouvrez une"
echo "     deuxième console et invoquez la commande suivante :"
echo
echo "       # tail -f /tmp/postinstall.log"
echo
sleep $DELAY

# Pour l'instant on n'utilise que l'IPv4
echo -e ":: Désactivation de l'IPv6... \c"
sleep $DELAY
cat $CWD/config/sysctl.d/disable-ipv6.conf > /etc/sysctl.d/disable-ipv6.conf
if [ -f /etc/ssh/sshd_config ]; then
  sed -i -e 's/#AddressFamily any/AddressFamily inet/g' /etc/ssh/sshd_config
  sed -i -e 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
fi
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Personnalisation du shell Bash pour root
echo "::"
echo -e ":: Configuration du shell Bash pour l'administrateur... \c"
sleep $DELAY
cat $CWD/config/bash/bashrc-root > /root/.bashrc 
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Personnalisation du shell Bash pour les utilisateurs
echo "::"
echo -e ":: Configuration du shell Bash pour les utilisateurs... \c"
sleep $DELAY
cat $CWD/config/bash/bashrc-users > /etc/skel/.bashrc
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Quelques options pratiques pour Vim
echo "::"
echo -e ":: Configuration de Vim... \c"
sleep $DELAY
cat $CWD/config/vim/vimrc > /etc/vimrc
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Passer le système en anglais
echo "::"
echo -e ":: Passer le système en anglais... \c"
sleep $DELAY
localectl set-locale LANG=en_US.UTF8
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Configuration de l'affichage de la console
echo "::"
echo -e ":: Configuration de l'affichage de la console... \c"
sleep $DELAY
sed -i -e 's/"rhgb quiet"/"nomodeset quiet vga=791"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Activer les dépôts [base], [updates] et [extras] avec une priorité de 1
echo "::"
echo -e ":: Configuration des dépôts de paquets officiels... \c"
sleep $DELAY
cat $CWD/config/yum/CentOS-Base.repo > /etc/yum.repos.d/CentOS-Base.repo
sed -i -e 's/installonly_limit=5/installonly_limit=2/g' /etc/yum.conf
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Activer le dépôt [cr] avec une priorité de 1
echo "::"
echo -e ":: Configuration du dépôt de paquets CR... \c"
sleep $DELAY
cat $CWD/config/yum/CentOS-CR.repo > /etc/yum.repos.d/CentOS-CR.repo
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Activer la gestion des Delta RPM
if ! rpm -q deltarpm 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Activer la gestion des Delta RPM... \c"
  yum -y install deltarpm >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Mise à jour initiale
echo "::"
echo -e ":: Mise à jour initiale du système... \c"
yum -y update >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Installer le plugin Yum-Priorities
if ! rpm -q yum-plugin-priorities 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Installation du plugin Yum-Priorities... \c"
  yum -y install yum-plugin-priorities >> $LOG 2>&1
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Activer le dépôt [epel] avec une priorité de 10
if ! rpm -q epel-release 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Configuration du dépôt de paquets EPEL... \c"
  rpm --import http://mirrors.ircam.fr/pub/fedora/epel/RPM-GPG-KEY-EPEL-7 >> $LOG 2>&1
  yum -y install epel-release >> $LOG 2>&1
  cat $CWD/config/yum/epel.repo > /etc/yum.repos.d/epel.repo
  cat $CWD/config/yum/epel-testing.repo > /etc/yum.repos.d/epel-testing.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Activer le dépôt [nux-dextop] avec une priorité de 10
if ! rpm -q nux-dextop-release 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Configuration du dépôt de paquets Nux-Dextop... \c"
  yum -y localinstall $CWD/config/yum/nux-dextop-release-*.rpm >> $LOG 2>&1
  rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-nux.ro >> $LOG 2>&1
  cat $CWD/config/yum/nux-dextop.repo > /etc/yum.repos.d/nux-dextop.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Configurer les dépôts [elrepo], [elrepo-kernel], etc. sans les activer
if ! rpm -q elrepo-release 2>&1 > /dev/null ; then
  echo "::"
  echo -e ":: Configuration du dépôt de paquets ELRepo... \c"
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org >> $LOG 2>&1
  yum -y localinstall $CWD/config/yum/elrepo-release-*.rpm >> $LOG 2>&1
  cat $CWD/config/yum/elrepo.repo > /etc/yum.repos.d/elrepo.repo
  echo -e "[${VERT}OK${GRIS}] \c"
  sleep $DELAY
  echo
fi

# Installer les outils Linux listés dans config/pkglists/outils-linux.txt
echo "::"
echo -e ":: Installation des outils système Linux... \c"
PAQUETS=$(egrep -v '(^\#)|(^\s+$)' $CWD/config/pkglists/outils-linux.txt)
yum -y install $PAQUETS >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

# Supprimer les paquets inutiles listés dans config/pkglists/cholesterol.txt
echo "::"
echo -e ":: Suppression des paquets inutiles... \c"
CHOLESTEROL=$(egrep -v '(^\#)|(^\s+$)' $CWD/config/pkglists/cholesterol.txt)
yum -y remove $CHOLESTEROL >> $LOG 2>&1
echo -e "[${VERT}OK${GRIS}] \c"
sleep $DELAY
echo

echo

exit 0
