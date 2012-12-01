#!/bin/bash

DUMP_DIR="/home/backup/postgres"

PSQL_BIN=`which psql`
PGDUMP_BIN=`which pg_dump`
PGDUMP_OPT=" -C -b -o -O -Fp -f"
USER_BACKUP="postgres"
GROUP_BACKUP="postgres"

# Création du répertoire parent au répertoire de backup et affectation des bons droits
parent_dir=`dirname "${DUMP_DIR}"`
mkdir -p "${parent_dir}" && chmod 711 "${parent_dir}"
if [ $? -ne 0 ]; then
    echo "Impossible de creer le repertoire ${parent_dir} et de lui affecter les bons droits"
    exit 1
fi

# Création du répertoire de backup
mkdir -p ${DUMP_DIR}
if [ $? -ne 0 ]; then
    echo "Impossible de creer le repertoire ${DUMP_DIR}"
    exit 2
fi

# On applique les bons droits sur le répertoire
chmod 770 ${DUMP_DIR}
if [ $? -ne 0 ]; then
    echo "Impossible d'appliquer les droits sur ${DUMP_DIR}"
    exit 3
fi

# On vide le répertoire de backup
rm -fr ${DUMP_DIR}/*
if [ $? -ne 0 ]; then
    echo "Impossible de vider le repertoire ${DUMP_DIR}"
    exit 4
fi

chown ${USER_BACKUP}:${GROUP_BACKUP} ${DUMP_DIR}
if [ $? -ne 0 ]; then
    echo "Impossible de modifier l'utilisateur sur ${DUMP_DIR}"
    exit 5
fi

# Pour éviter des alertes, on se place dans le dossier sur lequel on a les droits
cd ${DUMP_DIR}

# Récupération des bases de données
BASES=`sudo -u ${USER_BACKUP} ${PSQL_BIN} -l -t | sed 's/^\s//' | grep -vE -e "^ |^$|^template0|^template1" | awk '{print $1}'`
if [ $? -ne 0 ]; then
    echo "Impossible de recuperer les bases de donnees"
    exit 6
fi

# Sauvegarde de chaque base de données
for base in ${BASES}; do
    echo "Backup : ${base}"
    
    base_file="${DUMP_DIR}/${base}"
        
    sudo -u ${USER_BACKUP} ${PGDUMP_BIN} ${base} -s ${PGDUMP_OPT} ${base_file}_schema
    if [ $? -ne 0 ]; then
        echo "Impossible de sauvegarder ${base}"
        exit 7
    fi
        
    sudo -u ${USER_BACKUP} ${PGDUMP_BIN} ${base} -a ${PGDUMP_OPT} ${base_file}_data
    if [ $? -ne 0 ]; then
        echo "Impossible de sauvegarder ${base}"
        exit 8
    fi
done

exit 0
