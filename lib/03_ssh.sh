#!/bin/bash


#
# Met à jour les informations de connexion SSH
# @param    string  user    le nom d'utilisateur
#
function init_ssh()
{
    local user="$1"
    
    if [ "${user}" == "root" ]; then
        local home="/root"
    else
        local home="/home/${user}"
    fi
    
    if [ ! -d "${home}" ]; then
        # Le home n'existe pas, on ne fait rien
        return 0
    fi
    
    # Création du répertoire .ssh
    mkdir -p "${home}/.ssh"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de la creation du repertoire : ${home}/.ssh"
        return 1
    fi
    
    # Affection des droits
    chmod 700 "${home}/.ssh"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de l'affectation des droits au repertoire : ${home}/.ssh"
        return 1
    fi
    
    # Affectation de l'utilisateur
    chown ${user} "${home}/.ssh"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de l'affectation de l'utilisateur a : ${home}/.ssh"
        return 1
    fi
    
    # Suppression de l'ancien fichier
    if [ -f "${home}/.ssh/authorized_keys" ]; then
        rm -f "${home}/.ssh/authorized_keys"
        if [ "$?" != "0" ]; then
            logError "Erreur lors de la suppression de ${home}/.ssh/authorized_keys"
            return 1
        fi
    fi
    
    # Ajout des clés communes à tous les serveurs
    cat ${SSH_DIRECTORY}/${user}/*.pub > "${TMP_DIRECTORY}/${user}_authorized_keys"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de la concatenation des cles SSH : ${SSH_DIRECTORY}/${user}/"
        return 1
    fi
    
    # Ajout des clés spécifiques pour le serveur
    local specific_ssh_directory="${SSH_DIRECTORY}/${user}/$(hostname)"
    if [ -d "${specific_ssh_directory}" ]; then
        cat ${specific_ssh_directory}/*.pub >> "${TMP_DIRECTORY}/${user}_authorized_keys"
    fi
    
    # Application du nouveau fichier
    cp "${TMP_DIRECTORY}/${user}_authorized_keys" "${home}/.ssh/authorized_keys"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de la copie des cles SSH : ${home}/.ssh/authorized_keys"
        return 1
    fi
    
    # Affectation de l'utilsateur
    chown ${user} "${home}/.ssh/authorized_keys"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de l'affectation de l'utilisateur a : ${home}/.ssh/authorized_keys"
        return 1
    fi
    
    # Affectation des droits
    chmod 600 "${home}/.ssh/authorized_keys"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de l'affectation des droits a : ${home}/.ssh/authorized_keys"
        return 1
    fi
    
    # Suppression du fichier temporaire
    rm -f "${TMP_DIRECTORY}/${user}_authorized_keys"
    if [ "$?" != "0" ]; then
        logError "Erreur lors de la suppression des cles SSH temporaire : ${TMP_DIRECTORY}/${user}_authorized_keys"
        return 1
    fi
    
    return 0
}


#
# Met à jour les informations de connexion SSH pour tous les utilisateurs
#
function update_ssh()
{
    users=`ls "${SSH_DIRECTORY}"`
    for user in ${users}; do
        logInfo "Mise a jour des cles SSH pour ${user}"
        init_ssh "${user}"
        if [ "$?" == "0" ]; then
            logInfo "Mise a jour des cles SSH pour ${user} : OK"
        fi
    done
}
