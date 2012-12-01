Usage
=====


Installation du serveur
-----------------------

L'installation du serveur se base sur une Ubuntu 12.04

Pour lancer l'installation :

* wget https://raw.github.com/leblanc-simon/OpenInstallServer/master/get.sh -q -O - | sh
* cd /root/travaux/install
* ./install.sh [-w] [-o]
* (répondre aux questions)
* (à la fin du script : faire les modifications au niveau des partitions)
* cd /root/travaux
* ./deploy.sh
* reboot && exit

Le serveur est prêt.


Programmes installés
--------------------

* LAMP 
  * Apache
  * PHP
  * MySQL
  * imagemagick
  * ffmpeg
  * phpmyadmin
  * awstats
  
* Sécurité, maintenance
  * iptables
  * fail2ban
  * munin
  * logwatch
  
* FTP
  * proftpd
  * lftp
  
* Mail
  * postfix
  
* Utilitaire
  * quota
  * bzr
  * subversion
  * git

  
Fin d'installation
------------------

Pour activer les quotas, il faut :
* placer, dans /etc/fstab, les options suivantes au niveau de la partition : usrquota,grpquota 
* remonter la partition : # mount -o remount /home
* activer les quotas avec : # quotacheck -vagum && quotaon -avug

Il faut enfin penser à déployer la configuration du serveur. Pour cela, il suffit d'executer le script :

```bash
/root/travaux/deploy.sh
```

Cela permettra de placer les différents fichiers de configuration, d'ajouter les clés SSH par défaut et de mettre en place le script iptables.sh au démarrage

Redémarrer la machine pour que toutes les configurations soient prise en compte (ou redémarrer les différents services un par un)


Déploiement de configuration
----------------------------

Lors de la première execution du script deploy.sh, celui-ci va se mettre dans le cron.daily. Cela signifie que chaque jour, le script de déploiement sera executé. Cela permet de déployer automatiquement des mises à jour de configuration sur tous les serveurs uniquement en mettant à jour son dépôt OpenInstallServer.

Il existe 3 types de dossier de configuration :
* common : le dossier de la configuration commune à tous les serveurs
* openerp ou web : le dossier de la configuration spécifique à un type de serveur
* $(hostname) : le dossier de la configuration spécifique à un serveur

Pour le déploiement des clés publique SSH, cela fonctionne par utilisateur. Dans le dossier "ssh", il y a un sous-dossier par utilisateur unix. Si vous souhaitez vous connecter sur l'utilisateur "toto" avec votre clé SSH, il faut alors créer un dossier "toto" et mettre votre clé SSH publique dans ce dossier.

Il est également possible de limiter le déploiement d'une clé à un seul serveur. Pour cela, au lieu de mettre votre clé publique SSH dans le dossier portant le nom de l'utilisateur, il faut créer un sous-dossier du nom du hostname (sous dossier au dossier portant le nom d'utilisateur) pour lequel vous souhaitez ajouter votre clé publique SSH.


Outils
======

Divers outils sont présents sur le serveur pour faciliter l'administration. Les scripts se trouvent dans /root/travaux/utils/

Une aide est disponible pour chaque outil en faisant ./[outil.sh] -h


Ajouter un site web
-------------------

Ajout un site web sur le serveur :
* Création d'un compte Unix et donc FTP
* Création des fichiers de configuration Apache (pour gestion domaine et sous-domaine)
* Création (si demandé) de la base de donnée associée

```bash
./add_site.sh --website mon-site.fr --password "mon mot de passe" [--user mon_user] [--quota 500] [--nomysql] [--help]
```


Ajouter un sous-domaine
-----------------------

Ajout d'un sous domaine à un domaine déjà existant
* Ajout de la structure gérant le sous domaine dans le home de l'utilisateur
* Création (si demandé) de la base de donnée associée

```bash
./add_sd.sh --website test.mon-site.fr [--nomysql] [--help]
```


Mettre à jour les quotas
------------------------

Applique un nouveau quota pour un utilisateur

```bash
./fix_quota.sh --user mon_user --quota taille [--help]
```


Supprimer un site web
---------------------

Supprime un site web, cela implique :

* suppresion de la base de données
* suppresion des données utilisateur (site web, sous-domaines, autre donnée du home)
* suppresion de l'utilisateur unix et mysql
* un backup des données utilisateurs est effectué avant

```bash
./remove_site.sh --website mon-site.fr [--help]
```


Supprimer un sous-domaine
-------------------------

Supprime un sous-domaine, cela implique :

* suppresion de la base de données
* suppression durépertoire du sous-domaine

```bash
./remove_sd.sh --website test.mon-site.fr [--help]
```


Iptables
========

Fonctionnement du script iptables
---------------------------------

Par défaut, seul les port SSH et SNMP sont ouvert. On ouvre les ports supplémentaire en éditant le fichier de configuration situé dans security/conf/[nom du hostname].sh


Modification de l'ouverture des ports
-------------------------------------

La modification des ports ouvert se fait en ajoutant dans security/conf/[nom du hostname].sh :

* allow_[service]=true : ouverture des ports correspondants au service
* allow_[service]=false : fermeture des ports correspondants au service

Les services par défaut sont configuré dans le fichier security/conf/default.sh.


Ajout de nouveau service
------------------------

Pour ajouter un nouveau service disponible dans l'iptables, il faut dans le fichier de configuration situé dans security/conf/[nom du hostname].sh :

* [service]_ips=() : tableau vide -> toutes les IP, tableau contenant des adresses IP -> le port ne sera ouvert que pour les adresses IP définies
* [service]_ports=(99) : le ou les ports à ouvrir au niveau du firewall
* [service]_protocols=('tcp') : le ou les protocoles (tcp ou udp principalement) concerné par l'ouverture du port
* allow_[service]=true : true ou false pour ouvrir ou fermer le port
* services=("${services[*]}" '[service]') : ajout du service dans la liste des services

