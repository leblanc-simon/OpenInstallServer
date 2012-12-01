#!/bin/bash

if [ ${UID} -ne 0 ]; then
    echo "You must be root. No root has small dick :-)"
    exit 1
fi

if [ -d /root/travaux ]; then
    echo "Le repertoire /root/travaux existe deja"
    exit 2
fi

which git > /dev/null || apt-get -y -q install git-core
if [ $? -ne 0 ]; then
    echo "Impossible d'installer Git"
    exit 3
fi

git clone https://github.com/leblanc-simon/OpenInstallServer.git /root/travaux
if [ $? -ne 0 ]; then
    echo "Impossible de recuperer OpenInstallServer"
    exit 4
fi

echo "#############################################"
echo "# "
echo "# Pour installer le serveur :"
echo "# - cd /root/travaux/install"
echo "# - ./install.sh -h"
echo "# "
echo "# Voir le README.md pour plus d'informations"
echo "# "
echo "#############################################"

exit 0
