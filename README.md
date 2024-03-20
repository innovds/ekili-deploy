# Project Ekili Deployment Guide

## Prérequis

- Docker et Docker Compose doivent être installés sur la machine hôte.
- Les sauvegardes de la base de données doivent être présentes dans le répertoire `/backups` si une restauration est nécessaire.

## Démarrer l'Application

Pour démarrer l'application, suivez ces étapes :

1. Clonez le dépôt Git ou téléchargez les fichiers sources dans votre machine locale.
2. Naviguez vers le répertoire contenant le fichier `docker-compose.yml`.
3. Exécutez la commande suivante pour démarrer tous les services définis dans le fichier `docker-compose.yml` :

```sh
docker-compose up -d
```

Cela lancera les conteneurs Docker pour l'application Ekili et pour le service de base de données PostgreSQL.

## Créer la Base de Données Initiale

Les scripts initiaux pour la création de la base de données et des rôles d'utilisateurs se trouvent dans le répertoire `init`. Lors du premier démarrage du service PostgreSQL, ces scripts seront automatiquement exécutés pour initialiser la base de données.

## Restauration de la Base de Données

Pour restaurer la base de données à partir d'une sauvegarde, suivez ces étapes :

1. Assurez-vous que le fichier de sauvegarde se trouve dans le répertoire `/backups` du conteneur PostgreSQL.
2. Connectez-vous au conteneur PostgreSQL :

```sh
docker compose exec -it db  bash
```

3. Exécutez le script `restore.sh` avec les options nécessaires. Par exemple :

```sh
./restore.sh -d ekili -U ekili_user -f /backups/ekili-2024-01-20.sql.gz -R yes
```

Les options sont les suivantes :
- `-d` : nom de la base de données à restaurer.
- `-U` : utilisateur de la base de données.
- `-f` : fichier de sauvegarde à utiliser pour la restauration.
- `-R` : indiquez `yes` pour recréer la base de données avant la restauration.

## Recréation de la Base de Données après Restauration

Si vous avez besoin de recréer la base de données après la restauration, vous pouvez passer l'option `-R yes` au script `restore.sh` comme décrit ci-dessus. Cela va arrêter les sessions actives, supprimer la base de données existante, et la recréer avant de restaurer les données.
