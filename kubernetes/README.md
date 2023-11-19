---
author: fccagou
status: draft
---

# Présentation

Ce script est utilisé pour tester la construction d'un cluster kubernetes from
scratch.

Il doit, pour chaque logiciel

- recueillir les informations de configuration
- installer les binaires
- générer les fichiers de configuration
- générer les certificats
- afficher les actions à éxécuter pour finir les installations.

# Acteurs

Le `control plan` est le centre de décision du cluster. Il est composé :

- d'un serveur par lequel passent toutes les communication à travers de
  différentes api appelé `api server̀`
- d'un service de contrôle de la cohérence d'ensemble appelé ̀`control manager`
- d'un service d'ordonnancement des actions appelé `scheduler`
- d'un système de stockage des configurations. Le choix technique est d'utiliser
  le serveur de type clé/valeur `etcd`

Les services peuvent être hébergés sur un même serveur ou être déployés sur des
systèmes séparés en fonctiion de la stratégie de haute disponibilité choisie.

Les `workers` ou `nodes` sont les systèmes qui vont exécuter les services. Un
service est en charge de mettre en oeuvre les configurations qui lui sont attribués
par le `scheduler`. Dans kubernetes, c'est le rôle de `kubelet`.
Il a en charge de :

- lancer des conteneurs et/ou des VM
- configurer les redirectiions réseau
- superviser les systèmes

# Bibliographie

- [Kubernetes](https://kubernetes.io/)
- [etcd](https://etcd.io/docs/)
- [Kubernetes the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way/tree/master)
- [Démystifions Kubernetes](https://github.com/zwindler/demystifions-kubernetes/tree/main)

# Usage

     ./build.sh [PARAMETER]

     Sans parametre affiche cette aide.

     PARAMETERS LIST:

        --help|-h                 : Cette aide.
        --build-sources           : Créé les binaires depuis les dépôts Git
        --show-versions           : Affiche les versions des binaires
        --show-env                : Génère un fichier d'environnement
        --create-cluster-conf     : Créé la configuration du cluster
        --create-kubelet-conf     : Créé la configuration d'un worker
        --all                     : Construit tout
        --cluster-ip              : Ip du cluster
        --cluster-dns             : Ip du snd utilisé par le cluster
        --cluster-domain          : Domaine du cluster
        --pod-cidr                : CIDR des POD
