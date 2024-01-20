#!/bin/bash

# Valeurs par défaut pour les options
PGHOST="localhost"
PGPORT="5432"
PGDATABASE="postgres"
SUPERUSER="postgres"
BACKUP_DIR="/backups"
db="ekili"

# Utilisation de getopts pour traiter les options
while getopts h:p:d:U:P:f:b:D:S:C:R: flag
do
    case "${flag}" in
        h) PGHOST=${OPTARG};;
        p) PGPORT=${OPTARG};;
        d) db=${OPTARG};;
        U) role=${OPTARG};;
        P) PGPASSFILE=${OPTARG};;
        f) BACKUP_FILE=${OPTARG};;
        b) BACKUP_DIR=${OPTARG};;
        D) PGDATABASE=${OPTARG};;
        S) SUPERUSER=${OPTARG};;
        C) POST_RESTORE_SCRIPT=${OPTARG};;
        R) RECREATE_DB=${OPTARG};;
    esac
done

# Si aucun fichier n'a été spécifié, utiliser la valeur par défaut
if [ -z "$PGPASSFILE" ]
then
    PGPASSFILE="$BACKUP_DIR/.pgpass"
fi

# Si le rôle n'est pas spécifié, utiliser SUPERUSER
if [ -z "$role" ]
then
    role=$SUPERUSER
fi

# Si aucun fichier n'a été spécifié, utiliser la valeur par défaut
if [ -z "$BACKUP_FILE" ]
then
    BACKUP_FILE="$BACKUP_DIR/$db-$(date +%Y-%m-%d).sql.gz"
fi

# Set PGPASSFILE
export PGPASSFILE=$PGPASSFILE

# Check if role is superuser
IS_SUPERUSER=$(psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $SUPERUSER -tAc "SELECT rolsuper FROM pg_roles WHERE rolname='$role'")

# If role is not superuser, grant it
if [ "$IS_SUPERUSER" != "t" ] && [ "$role" != "$SUPERUSER" ]; then
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $SUPERUSER -c "ALTER USER $role WITH SUPERUSER;"
fi

# Vérification de la nécessité de recréer la base de données
# Si la variable RECREATE_DB est définie (non vide), le script arrête les sessions actives
# de la base de données spécifiée, supprime la base de données existante, puis en crée une nouvelle.
# Cela est utile pour s'assurer que la base de données est dans un état propre pour la restauration.
if [ -n "$RECREATE_DB" ]
then
    # Arret des sessions
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $SUPERUSER -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$db' AND pid <> pg_backend_pid();"
    # Suppression de la base de données existante
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $SUPERUSER -c "DROP DATABASE IF EXISTS $db;"
    # Création d'une nouvelle base de données
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $SUPERUSER -c "CREATE DATABASE $db owner $role;"
fi

# Restauration de la sauvegarde
pg_restore -h $PGHOST -p $PGPORT -U $role -d $db -O -x -Fc $BACKUP_FILE

# Exécution du script SQL post-restauration
if [ -n "$POST_RESTORE_SCRIPT" ]
then
    psql -h $PGHOST -p $PGPORT -U $role -d $db -f $POST_RESTORE_SCRIPT
fi

# If role is not superuser, revoke it
if [ "$IS_SUPERUSER" != "t" ] && [ "$role" != "$SUPERUSER" ]; then
    psql -h $PGHOST -p $PGPORT -d $PGDATABASE -U $SUPERUSER -c "ALTER USER $role WITH NOSUPERUSER;"
fi
