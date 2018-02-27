Serveur LAN CentOS 7
====================

Voici le script de post-installation dont je me sers pour configurer "aux
petits oignons" un serveur LAN basé sur CentOS 7.

Prérequis
---------

Le point de départ, c'est une installation minimale de CentOS 7.

Le réseau n'est pas activé par défaut, il faut donc songer à l'activer
explicitement.

Utilisation
-----------

Une fois qu'on a effectué le redémarrage initial, on peut se connecter en tant
que `root`.

L'utilitaire `git` ne fait pas partie d'une installation par défaut, il va donc
falloir l'installer. 

<pre>
# <strong>yum install git</strong>
</pre>

Récupérer le contenu de ce dépôt.

<pre>
# <strong>git clone https://github.com/kikinovak/centos-7-server-lan</strong>
</pre>

Lancer le script de post-installation.

<pre>
# <strong>cd centos-7-server-lan</strong>
# <strong>./postinstall.sh</strong>
</pre>

L'affichage du script est assez laconique. Pour en savoir un peu plus sur le
détail et la progression des opérations, on peut ouvrir une deuxième console et
afficher le fichier journal "à chaud", comme ceci.

<pre>
# <strong>tail -f /tmp/postinstall.log</strong>
</pre>

Le script se charge automatiquement des opérations suivantes.

  * Activer la gestion des Delta RPM.

  * Effectuer la mise à jour initiale du système.

  * Désactiver l'IPv6.

  * Personnaliser le shell Bash pour `root` et les utilisateurs.

  * Personnaliser la configuration de Vim.

  * Configurer les dépôts de paquets officiels de manière prioritaire.

  * Configurer les dépôts de paquets tiers EPEL et ELRepo.

  * Installer une panoplie d'outils système.

Une fois que le script est arrivé à terme, on peut créer un nouvel utilisateur.

<pre>
# <strong>useradd -c "Nicolas Kovacs" kikinovak</strong>
# <strong>passwd kikinovak</strong>
# <strong>usermod -a -G wheel kikinovak</strong>
</pre>

-- (c) Nicolas Kovacs, 2018
