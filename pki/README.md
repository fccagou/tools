# PKI

[English version](README-en.md)

## Description

De simples scripts bash pour gérer PKI avec openssl.

Il s'agit de scripts de tests pour manipuler openssl
et comprendre les mécanismes de gestion d'une PKI.

## Attention

La gestion des secrets n'est pas faite convenablement
pour un usage en production, à moins que ce soit pour
générer des environnements de tests ou de qualification.

## Quickstart

```bash
    # Ajouter la completion à votre environnement
    . pki-completion.sh

    # Initialiser la pki
    pki init

    # Créer une requête de certificat pour le server myhost.local
    pki request new myhost.local

    # Vérifier la liste des certicat en attente de signature
    pki requests

    # Signer le certificat en attente pour myhost.local
    pki cert sign myhost.local

    # Afficher la liste des certificats de la pki
    pki certs

    # Vérifier l'état d'un certificat en donnat le chemin du fichier
    pki cert status ./myCA/certs/myhost.local.pem

    # Ou en utiisant le numéro de série.
    pki cert status 1000

    # Pour avoir une vision globale
    pki status

```

Plus d'aide

```bash
    pki help <TAB> <TAB>
```

## Automatisation pour des tests

```bash
   export BATCHMODE=yes
   export C="FR"
   export ST="Bourgogne"
   export L="Dijon"
   export O="Ma petit entreprise de Mayonnaise"
   export OU="IT de $O"
   export CN="CA de $O"

   hosts=( host1.local host2.local, host3.local)
   pki init
   for h in "${hosts[@]}"; do
       pki request new "$h"
       pki cert sign "$h"
   done
   pki status
```
