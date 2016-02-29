#! /bin/bash

#////////////////////////////////////////////////////////////////////////////////////#
# Script de sauvegarde complète d'OpenERP                                            #
# Par Thierry Godin : 2013-06-23                                                     #
# http://thierry-godin.developpez.com/                                               #
#                                                                                    #
# Le script effectue une sauvegarde complète des fichiers OpenERP                    #
# et du fichier de configuration du server openerp-server.conf                       #
# ainsi que de la base de données au format TAR                                      #
#                                                                                    #
# Sauvegarde en local dans le répertoire de l'utilisateur openerp                    #
#                                                                                    #
# Script à mettre en CHMOD : 0755                                                    #
# Et à exécuter en 'root'                                                            #
#                                                                                    #
# 	Utilisation :                                                                #
#	-------------                                                                #
#	Pour executer le fichier sous Debian                                         #
#	Placer le fichier dans le répertoire /root                                   #
#	Ouvrir une invite de commande et entrer                                      #
# 		cd /root                                                             #
#		bash ./save_openerp_all.sh                                           #
#                                                                                    #      
#////////////////////////////////////////////////////////////////////////////////////#

# ---------------------------------------------------------------------------------- #
# !!!                                IMPORTANT                                     !!!
# ---------------------------------------------------------------------------------- #
#                                                                                    #
# Modifier le fichier pg_hba.conf de PostgreSQL pour autoriser la connexion          #
# sans mot de passe en local                                                         #
#                                                                                    #
# Emplacement du fichier = /etc/postgresql/9.1/main/pg_hba.conf :                    #
# Rajouter ou modifier la ligne ci-dessous :                                         #
#                                                                                    #
# TYPE  DATABASE        USER            ADDRESS                 METHOD               #
# local   all          openerp                                  trust                #
#                                                                                    #
# ---------------------------------------------------------------------------------- #

# Fichier de LOG
LOG_FILE='/var/log/openerp_backup.log'

# Création du fichier de log
if [ ! -e ${LOG_FILE} ]; then
	echo 'Creation du fichier de log :'${LOG_FILE}
	touch ${LOG_FILE}	
fi

######################################################################################
#                           SAUVEGARDE DES FICHIERS                                  #
######################################################################################


# Destination de la sauvegarde : répertoire /home/openerp :
DEST_DIR='/home/openerp'

# Nom du répertoire qui contient la sauvegarde
SAVE_DIR=${DEST_DIR}'/SauvegardeOpenERP'

SAVE_PATH=${SAVE_DIR}'/'

# Nom du répertoire où seront stockés les fichiers supprimés (au cas où ..)
DEL_DIR=${SAVE_PATH}'DELETED'

echo `date +%Y-%m-%d_%H:%M:%S`'  - Debut de la sauvegarde complete OpenERP' >> ${LOG_FILE} 2>&1
echo `date +%Y-%m-%d_%H:%M:%S`'  - Debut de la sauvegarde complete OpenERP'

# Création du répertoire SauvegardeOpenERP si il n'existe pas
if [ ! -d ${SAVE_DIR} ]; then
	echo '  - Creation du repertoire :'${SAVE_DIR} >> ${LOG_FILE} 2>&1
	echo '  - Creation du repertoire :'${SAVE_DIR}
	mkdir ${SAVE_DIR}	
fi

# Création du répertoire DELETED si il n'existe pas
if [ ! -d ${DEL_DIR} ]; then
	echo '  - Creation du repertoire :'${DEL_DIR} >> ${LOG_FILE} 2>&1
	echo '  - Creation du repertoire :'${DEL_DIR} 
	mkdir ${DEL_DIR}
fi

# Dossiers à sauvegarder 
# Mettre le chemin de openerp + fichier openerp-server.conf
# Vous pouvez rajouter des repertoires à sauvegarder (vos modules persos)
# Rajoutez simplement des ELEMENT[n] au tableau ci dessous
ELEMENT[0]='/opt/openerp/'
ELEMENT[1]='/etc/openerp-server.conf'


# En cas de suppression de fichier, ils sont sauvegardés ici dans DELETED
# puis supprimés de la sauvegarde complete
DATE_DELETE=DELETED/`date +%Y-%m-%d`

NB_ELEMENT=${#ELEMENT[@]}

for((i=0; i < $NB_ELEMENT; i++))
do
	echo '  - Sauvegarde de '${ELEMENT[i]}' . Veuillez patienter'
	rsync -aRcxvuz --stats --delete --backup --backup-dir=$DATE_DELETE ${ELEMENT[i]} $SAVE_PATH >/dev/null 2>&1 
	#rsync -aRcxvuz --verbose --stats --delete --backup --backup-dir=$DATE_DELETE ${ELEMENT[i]} $SAVE_PATH

done

echo '  - Sauvegarde des fichiers OpenERP terminee' >> ${LOG_FILE} 2>&1
echo '  - Sauvegarde des fichiers OpenERP terminee'

######################################################################################
#                               SAUVEGARDE DE LA DB                                  #
######################################################################################

# Nom du sous-répertoire de sauvegarde de la DB
DB_DIR='DB'

# Utilisateur 
#DB_USER='openerp'
DB_USER='openerp'

# Rôle
DB_ROLE='openerp'

# Nom de la base de données
#DB_NAME='Vapostore'
DB_NAME='oerp7_base'

# Nom du fichier de sauvegarde
FILE_NAME=${DB_NAME}'_DB_'

# Date de la sauvegarde
DATE_SAVE=`date +%Y-%m-%d`

# Extension du fichier de sauvegarde
FILE_EXT='.backup'

# Adresse IP serveru sauvegarde
IP_BACKUP='10.254.30.42'

# Port ssh backup server
PORT_SSH='22'

# Dossier de sauvegarde sur le serveur
SAVE_PATH_BACKUP='/opt/BACKUP_DATABASE/TEST/'

# Le nom complet du fichier de sauvegarde ressemblera à ça:
#	FILE_NAME + DATE_SAVE + FILE_EXT
#	Exemple : MaDb_DB_ + 2013-06-24 + .backup = MaDb_DB_2013-06-24.backup



# Chemin du Fichier de sauvegarde
DB_SAVE_PATH=${SAVE_PATH}${DB_DIR}'/'${FILE_NAME}${DATE_SAVE}${FILE_EXT}

# Création du répertoire DB si il n'existe pas
if [ ! -d ${SAVE_PATH}${DB_DIR} ]; then
	echo '  - Creation du repertoire :'${SAVE_PATH}${DB_DIR} >> ${LOG_FILE} 2>&1
	echo '  - Creation du repertoire :'${SAVE_PATH}${DB_DIR}
	mkdir ${SAVE_PATH}${DB_DIR}
fi

echo '  - Sauvegarde de la base de donnees OpenERP '${DB_NAME}'. Veuillez patienter...'

psql -U ${DB_USER}
pg_dump --verbose --username ${DB_USER} --role ${DB_ROLE} --no-password --format t --blobs --file ${DB_SAVE_PATH} ${DB_NAME} >> ${LOG_FILE} 2>&1

echo '  - Sauvegarde de la base de donnees OpenERP terminee' >> ${LOG_FILE} 2>&1
echo '  - Sauvegarde de la base de donnees OpenERP terminee' 


# Attribution des droits à l'utilisateur openerp/openerp : 0755
echo '  - Mise a jour des permissions' >> ${LOG_FILE} 2>&1
echo '  - Mise a jour des permissions'
chown openerp:openerp ${SAVE_DIR} -R
chmod 0755 ${SAVE_DIR} -R

echo '  - Envoi de la sauvegarde de la base de donnees OpenERP '${DB_NAME}' au serveur de BACKUP. Veuillez patienter...'

#rsync -aRcxvuz --stats ${DB_SAVE_PATH} $SAVE_PATH_BACKUP >/dev/null 2>&1
ssh -p ${PORT_SSH} root@${IP_BACKUP} cp ${SAVE_PATH_BACKUP}${FILE_NAME}${DATE_SAVE}${FILE_EXT} ${SAVE_PATH_BACKUP}${FILE_NAME}${DATE_SAVE}${FILE_EXT}.old
rsync -e "ssh -p${PORT_SSH}" -avz ${DB_SAVE_PATH} root@${IP_BACKUP}:${SAVE_PATH_BACKUP}${FILE_NAME}${DATE_SAVE}${FILE_EXT}


echo '  - Envoi de la sauvegarde de la base de donnees OpenERP au serveur de BACKUP terminee' >> ${LOG_FILE} 2>&1
echo '  - Envoi de la sauvegarde de la base de donnees OpenERP au serveur de BACKUP terminee' 



echo `date +%Y-%m-%d_%H:%M:%S`'  - Sauvegarde complete OpenERP terminee' >> ${LOG_FILE} 2>&1
echo `date +%Y-%m-%d_%H:%M:%S`'  - Sauvegarde complete OpenERP terminee'
echo '------------------------------------' >> ${LOG_FILE} 2>&1

# EOF
