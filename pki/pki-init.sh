#!/bin/bash

set -euo pipefail

# Variables de configuration
CA_DIR="/root/myCA"
CA_KEY="$CA_DIR/private/ca.key"
CA_CERT="$CA_DIR/certs/ca.crt"
CONFIG_FILE="$CA_DIR/openssl.cnf"

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root." >&2
    exit 1
fi

# Création des répertoires et fichiers nécessaires
mkdir -p $CA_DIR/{certs,crl,newcerts,private} || { echo "Erreur lors de la création des répertoires." >&2; exit 1; }
chmod 700 $CA_DIR/private || { echo "Erreur lors du changement des permissions." >&2; exit 1; }
touch $CA_DIR/index.txt || { echo "Erreur lors de la création du fichier index.txt." >&2; exit 1; }
echo 1000 > $CA_DIR/serial || { echo "Erreur lors de la création du fichier serial." >&2; exit 1; }

# Génération de la clé privée pour le CA
openssl genpkey -algorithm RSA -out $CA_KEY -aes256 || { echo "Erreur lors de la génération de la clé privée." >&2; exit 1; }

# Génération du certificat racine pour le CA
openssl req -x509 -new -nodes -key $CA_KEY -sha256 -days 3650 -out $CA_CERT || { echo "Erreur lors de la création du certificat racine." >&2; exit 1; }

# Message de fin
echo "Infrastructure PKI initialisée avec succès."
