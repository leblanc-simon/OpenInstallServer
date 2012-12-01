#!/bin/bash
##########################################################################################
#Copyright (c) 2009, Leblanc Simon <contact@leblanc-simon.eu>
#
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification,
#are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#    * Neither the name of the Leblanc Simon nor the names of its contributors
#      may be used to endorse or promote products derived from this software without
#      specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
#CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
#PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
#LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###########################################################################################
#Permet d'activer l'option --single-transition dans le cas d'une erreur au niveau des TABLE LOCKS
SINGLE_TRANS="1"

# Adresse mail d'envoie du rapport
MAIL_TO_OK=`cat /root/.techmail`
MAIL_TO_ERROR=`cat /root/.techmail`

# Répertoire de sauvegarde de base
# A l'intérieur des dossiers pour chaque serveur seront créés
DUMP_DIR_BASE="/home/backup/mysql/"

#Fichier contenant le mot de passe mysql
PDB_FILE="/root/.pdb"

# Paramètres principaux de MySQL
MYSQL_BIN=`which mysql`
MYSQL_DUMP_BIN=`which mysqldump`
 
MYSQL_DUMP_DATA_OPTS="--no-create-db --no-create-info --add-locks --allow-keywords --complete-insert --quick --quote-names"
MYSQL_DUMP_STRUCT_OPTS="--add-drop-table --no-data --create-options --extended-insert --quote-names "

NB_SERVER=1
MYSQL_HOST_ARRAY[0]="localhost"
MYSQL_USER_ARRAY[0]="root"
MYSQL_PASS_ARRAY[0]=`cat ${PDB_FILE}`

# Liste des erreurs possible
ERR[0]="[$HOSTNAME][OK] Aucune erreur"
ERR[1]="[$HOSTNAME][ERROR] Erreur lors de la création du répertoire"
ERR[2]="[$HOSTNAME][ERROR] Erreur lors de la sélection des bases de données"
ERR[3]="[$HOSTNAME][ERROR] Erreur lors de la sauvegarde de la structure de la base de données"
ERR[4]="[$HOSTNAME][ERROR] Erreur lors de la sélection des tables de la base de données"
ERR[5]="[$HOSTNAME][ERROR] Erreur lors de la sauvegarde de la table de la base de données"

# Quelques fonctions
send_email() {
    retour="$1"
    message="$2"
    if [ "${RETOUR}" != "0" ]; then
        mail_to="${MAIL_TO_ERROR}"
    else
        mail_to="${MAIL_TO_OK}"
    fi
    
    echo "${message}"
    echo "${message}" | mail -s "${ERR[$retour]}" ${mail_to}
    
    ERROR=1
}

ITERATION=0
while [ ${ITERATION} -lt ${NB_SERVER} ]; do
    MYSQL_HOST=${MYSQL_HOST_ARRAY[${ITERATION}]}
    MYSQL_USER=${MYSQL_USER_ARRAY[${ITERATION}]}
    MYSQL_PASS=${MYSQL_PASS_ARRAY[${ITERATION}]}
    
    # Mise en place de l'option password si nécessaire
    if [ "${MYSQL_PASS}" = "" ]; then
        pass=""
    else
        pass="--password=${MYSQL_PASS}"
    fi
    
    # On crée le répertoire de la sauvegarde
    DUMP_DIR="${DUMP_DIR_BASE}${MYSQL_HOST}/"
    mkdir -p ${DUMP_DIR}
    if [ $? -ne 0 ]; then
        send_email 1 "Le répertoire \"${DUMP_DIR}\" n'a pas été créé !\n\nSauvegarde non effectuée!!!"
        exit 1
    fi
    
    # On vide le répertoire de backup    
    rm -f ${DUMP_DIR}*
    
    # On récupère toutes les tables
    bases=`${MYSQL_BIN} -u ${MYSQL_USER} -h ${MYSQL_HOST} ${pass} -e "SHOW DATABASES"`
    if [ $? -ne 0 ]; then
        send_email 2 "La requête suivante n'a pas réussie : '${MYSQL_BIN} -u \"${MYSQL_USER}\" -h \"${MYSQL_HOST}\" ${pass} -e \"SHOW DATABASES\"'\n\nSauvegarde non effectuée!!!"
        exit 2
    fi
    
    # On parcourt chaque base de données
    for base in ${bases};
    do
        if [ "${base}" != "Database" ]; then # La commande SQL renvoie "Database", on ne le prend pas en compte
            echo "Base : ${base}"
            
            # On évite les erreurs mysql en protégeant le nom de la base de données
            req_base="\`${base}\`"
            
            # On contourne un problème de MySQL en adaptant les options
            mysql_dump_struct_opts_use="${MYSQL_DUMP_STRUCT_OPTS}"
            mysql_dump_data_opts_use="${MYSQL_DUMP_DATA_OPTS}"
            if [ "${SINGLE_TRANS}" = "1" ]; then
                if [ "${base}" = "information_schema" -o "${base}" = "mysql" -o "${base}" = "performance_schema" ]; then
                    mysql_dump_struct_opts_use="${MYSQL_DUMP_STRUCT_OPTS} --single-transaction"
                    mysql_dump_data_opts_use="${MYSQL_DUMP_DATA_OPTS} --single-transaction"
                fi
            fi
            
            # On exporte la structure de la bases
            ${MYSQL_DUMP_BIN} -u "${MYSQL_USER}" -h "${MYSQL_HOST}" ${pass} ${mysql_dump_struct_opts_use} ${base} > ${DUMP_DIR}${base}_structure.sql
            if [ $? -ne 0 ]; then
                send_email 4 "La requête suivante n'a pas réussie : '${MYSQL_DUMP_BIN} -u \"${MYSQL_USER}\" -h \"${MYSQL_HOST}\" ${pass} ${MYSQL_DUMP_STRUCT_OPTS} ${base} > ${DUMP_DIR}${base}_structure.sql'\n\nSauvegarde non effectuée!!!"
            fi
            
            # On récupère les tables de la bases de données
            tables=`${MYSQL_BIN} -u "${MYSQL_USER}" -h "${MYSQL_HOST}" ${pass} -e "SHOW TABLES FROM ${req_base}"`
            if [ $? -ne 0 ]; then
                send_email 4 "La requête suivante n'a pas réussie : '${MYSQL_BIN} -u \"${MYSQL_USER}\" -h \"${MYSQL_HOST}\" ${pass} -e \"SHOW TABLES FROM ${req_base}\"'\n\nSauvegarde non effectuée!!!"
            fi
            
            # On parcourt chaque table de la base de données
            for table in ${tables};
            do
                if [ "${table}" != "Tables_in_${base}" ]; then # La commande SQL renvoie "Tables_in_base", on ne le prend pas en compte
                    echo "  Table : ${table}"
                    # On exporte les données de la table
                    ${MYSQL_DUMP_BIN} -u "${MYSQL_USER}" -h "${MYSQL_HOST}" ${pass} ${mysql_dump_data_opts_use} ${base} ${table} > ${DUMP_DIR}${base}_${table}_data.sql
                    if [ $? -ne 0 ]; then
                        send_email 5 "La requête suivante n'a pas réussie : '${MYSQL_DUMP_BIN} -u \"${MYSQL_USER}\" -h \"${MYSQL_HOST}\" ${pass} ${MYSQL_DUMP_DATA_OPTS} ${base} ${table} > ${DUMP_DIR}${base}_${table}_data.sql'\n\nSauvegarde non effectuée!!!"
                    fi
                fi
            done
        fi
    done
    
    let ITERATION=${ITERATION}+1
done

# Si tout s'est bien déroulé, on envoie un mail d'information
if [[ ${ERROR} -ne 1 ]]; then
    send_email 0 "Sauvegarde des bases de données bien réalisée"
    exit 0
else
    exit 10
fi
