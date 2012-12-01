#!/bin/bash

# mysql root/admin username
MYSQL_USER="root"
# mysql admin/root password
MYSQL_PASS=`cat /root/.pdb`
# mysql server hostname
MYSQL_HOST="localhost"
# Email ID to send notification
EMAIL_TO=`cat /root/.techmail`

#Shell script to start MySQL server i.e. path to MySQL daemon start/stop script.
# Debain uses following script, need to setup this according to your UNIX/Linux/BSD OS.
MYSQL_RESTART="service mysql restart"
# path mysqladmin
MYSQLADMIN_BIN=`which mysqladmin`

# path to mail program
MAIL_CMD=`which mail`

#### DO NOT CHANGE anything BELOW ####
MAILMESSAGE="/tmp/mysql.fail.$$"

# see if MySQL server is alive or not
${MYSQLADMIN_BIN} -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASS} ping 2>/dev/null 1>/dev/null
if [ $? -ne 0 ]; then
        echo "" > ${MAILMESSAGE}
        echo "Erreur: Le serveur MySQL Server ne repond plus" >> ${MAILMESSAGE}
        echo "Hostname: $(hostname)" >> ${MAILMESSAGE}
        echo "Date & Heure: $(date)" >> ${MAILMESSAGE}
        
        # try to start mysql
        ${MYSQL_RESTART} > /dev/null
        
        # see if it is started or not
        o=$(ps cax | grep -c ' mysqld$')
        if [ $o -eq 1 ]; then
                sMess="Le serveur MySQL a correctement redemarre. Ouf !"
        else
                sMess="Saperlipopette. Le serveur MySQL n'a PAS REDEMARRE !"
        fi
        
        # Email status too
        echo "Current Status: ${sMess}" >> ${MAILMESSAGE}
        echo "" >> ${MAILMESSAGE}
        echo "*** Ce mail a ete genere par le script $(basename $0) ***" >> ${MAILMESSAGE}
        echo "*** Ne pas repondre a ce mail, le script s'en moque ***" >> ${MAILMESSAGE}
        
        # send email
        $MAIL_CMD -s "[`hostname`] MySQL server" $EMAIL_TO < $MAILMESSAGE
fi

# remove file
rm -f $MAILMESSAGE
