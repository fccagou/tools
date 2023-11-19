#!/usr/bin/bash
#

set -o errexit
set -o pipefail
set -o nounset

doc () {
	cat <<'EOF_DOC'
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

EOF_DOC

    cat <<EOF_USAGE
# Usage

     $0 [PARAMETER]

     Sans parametre affiche cette aide.

     PARAMETERS LIST:

EOF_USAGE

grep -- '--.*)' "$0" \
	| grep -vE 'grep|printf' \
	| while read e
	do
		printf -- "        %-25s :%s\n" "${e//)*/}" "${e//*#/}"
	done

}


action () {
	printf -- "[+] %s\n" "$@"
}

info () {
	printf -- "[*] %s\n" "$@"
}

error () {
	printf -- "[-] %s\n" "$@"
}

_true="true"
_false="false"


prefix="$(realpath "$(dirname "$0")" )"
devpath="$prefix"/src
cluster_conf_path="$devpath"/conf
certpath="${cluster_conf_path}"/certs


build_from_sources () {
	local pkgname
	local url
	local cmd
	local branch

	pkgname="$1"
	url="$2"
	cmd="${3:-make}"
	branch="${4:-""}"


	action "Bulding $pkgname"
	if [ -d "$pkgname" ]
	then
        pushd "$pkgname" > /dev/null || {
			error "Can't enter in $pkgname"
		    exit 1
		}

		# No branch, update repo
		if [ -z "$branch" ]
		then
			git pull --rebase
		fi
	else
		[ -n "$branch" ] && branch="-b $branch"
		git clone $branch "$url" "$pkgname" || {
			error "Cloning $pkgname"
	    	exit 1
		}
        pushd "$pkgname" > /dev/null || {
			error "Can't enter in $pkgname"
		    exit 1
		}
	fi
	$cmd

	popd >/dev/null

}


check_prereqist () {

    [ -d "$devpath" ] || mkdir "$devpath"

    pushd src >/dev/null || {
    	error "Can't cd in $devpath dir"
    }

}


build_sources () {

	build_from_sources cfssl \
		https://github.com/cloudflare/cfssl.git

	build_from_sources etcd \
	  https://github.com/etcd-io/etcd.git \
	  ./build.sh \
	  v3.5.9

	build_from_sources kubernetes \
	  https://github.com/kubernetes/kubernetes

}


show_versions () {

	info "App versions"


	action "cfssl"
	cfssl version
	action "etcd"
	etcd --version
	action "kubectl"
	kubectl --version
}

show_env () {

	info "Create env file and source it"

	cat <<EOF_ENV
export PATH="$k8s"/_output/bin:"$etcddir"/bin:"$cfssldir"/bin:\$PATH
export KUBECONFIG="${cluster_conf_path}"/admin.conf
export PS1="(k8s)\$PS1"
source <(kubectl completion bash)
EOF_ENV
}


pki::ca::init () {
	local certdir
	local C
	local L
	local O
	local OU
	local ST

	certdir="$1"
	C="$2"
	L="$3"
#	O="$4"
#	OU="$5"
	ST="$4"

	[ -d "$certdir" ] || {
		error "Certdir absent ($certdir)"
	    exit 1
	}

	pushd "$certdir" || {
		error "Can't cd in $certdir"
	    exit 1
	}

	cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
	cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$C",
      "L": "$L",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "$ST"
    }
  ]
}
EOF
	cfssl gencert -initca ca-csr.json | cfssljson -bare ca

    popd >/dev/null || {
		error "Can't comme back"
	    exit 1
	}
}



create_cluster_conf () {
	if [ -d "${cluster_conf_path}" ]
	then
		info "Cluster conf exists in ${cluster_conf_path}"
	else
		mkdir "${cluster_conf_path}" || {
			error "Creating "${cluster_conf_path}" dir"
	    	exit 1
		}
		mkdir "${cluster_conf_path}"/certs || {
			error "Creating ${cluster_conf_path}/certs dir"
	    	exit 1
		}
		pki::ca::init \
			"${cluster_conf_path}"/certs \
			"$COUNTRY" \
			"$LOCATION" \
			"$STATE"

	fi
}

k8s_kubelet_generate_conf () {
	local _clustername
	local _clusteruri
	local _instance
	local _confname

	_clustername="$1"
	_clusteruri="$2"
	_instance="$3"

	_kubeconfname="${cluster_conf_path}"/"${_instance}".kubeconfig
	_kubeletconfname="${cluster_conf_path}"/"${_instance}"-kubelet-config.yaml

	action "Building kubeconfig $_instance ($_kubeconfname)"

	kubectl config set-cluster "${_clustername}" \
    --certificate-authority="${certpath}"/ca.pem \
    --embed-certs=true \
    --server="${_clusteruri}" \
    --kubeconfig="${_kubeconfname}"

	kubectl config set-credentials system:node:"${_instance}" \
    --client-certificate="$certpath"/"${_instance}".pem \
    --client-key="$certpath"/"${_instance}"-key.pem \
    --embed-certs=true \
    --kubeconfig="${_kubeconfname}"

    kubectl config set-context default \
      --cluster="${_clustername}" \
      --user=system:node:"${_instance}" \
      --kubeconfig="${_kubeconfname}"

    kubectl config use-context default --kubeconfig="${_kubeconfname}"


	action "Create kubelet config for $_instance ($_kubeletconfname)"
	cat > "${_kubeletconfname}" <<EOF_KUBELET_CONF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "${CLUSTER_DOMAIN}"
clusterDNS:
  - "${CLUSTER_DNS}"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${_instance}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${_instance}-key.pem"
EOF_KUBELET_CONF


cat <<EOF_KUBELET_TODO
# TODO

   scp ${_kubeconfname} ${_instance}:/root

   scp ${certpath}/ca.pem ${_instance}:/var/lib/kubernetes
   scp ${certpath}/${_instance}.pem ${_instance}:/var/lib/kubelet
   scp ${certpath}/${_instance}-key.pem ${_instance}:/var/lib/kubelet

   scp ${_kubeletconfname} ${_instance}:/var/lib/kubelet/kubelet-config.yaml

EOF_KUBELET_TODO

}


etcddir="$prefix"/src/etcd
cfssldir="$prefix"/src/cfssl
k8s="$prefix"/src/kubernetes
PATH="$k8s"/_output/bin:"$etcddir"/bin:"$cfssldir"/bin:$PATH

buildall="${_false}"
buildsources="${_false}"
showversions="${_false}"
showenv="${_false}"
createclusterconf="${_false}"

kubelet_instances=""

KUBERNETES_CLUSTER_NAME="${KUBERNETES_PUBLIC_ADDRESS:-"Démistyfions Kubernetes"}"
KUBERNETES_PUBLIC_ADDRESS="${KUBERNETES_PUBLIC_ADDRESS:-127.0.0.1}"
CLUSTER_DNS="${CLUSTER_DNS:-${KUBERNETES_PUBLIC_ADDRESS}}"
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-cluster.local}"
POD_CIDR="${POD_CIDR:-127.0.0.0/24}"


COUNTRY="${COUNTRY:-VU}"
STATE="${STATE:-Efate}"
LOCATION="${LOCATION:-Port-Vila}"
ORGANIZATION="${ORGANIZATION:-Cagou CORP}"

[ "$#" -gt "0" ] || {
    doc
    exit 0
}

while [ "$#" -gt "0" ]
do
	case "$1" in
		--help|-h) # Cette aide.
		    doc
			exit 0
		    ;;
		--build-sources) # Créé les binaires depuis les dépôts Git
			buildsources="${_true}"
			;;
		--show-versions) # Affiche les versions des binaires
			showversions="${_true}"
			;;
		--show-env) # Génère un fichier d'environnement
			showenv="${_true}"
			;;
		--create-cluster-conf) # Créé la configuration du cluster
			createclusterconf="${_true}"
			;;
		--create-kubelet-conf) # Créé la configuration d'un worker
			[ "$#" -ge "2" ] || {
				error "Parameter $1 needs a value"
			    exit 1
			}
			kubelet_instances="$2"
			shift
			;;
		--all) # Construit tout
			buildall="${_true}"
			;;
		--cluster-ip) # Ip du cluster
			[ "$#" -ge "2" ] || {
				error "Parameter $1 needs a value"
			    exit 1
			}
			KUBERNETES_PUBLIC_ADDRESS="$2"
			shift
			;;
		--cluster-dns) # Ip du snd utilisé par le cluster
			[ "$#" -ge "2" ] || {
				error "Parameter $1 needs a value"
			    exit 1
			}
			CLUSTER_DNS="$2"
			shift
			;;
		--cluster-domain) # Domaine du cluster
			[ "$#" -ge "2" ] || {
				error "Parameter $1 needs a value"
			    exit 1
			}
			CLUSTER_DOMAIN="$2"
			shift
			;;
		--pod-cidr) # CIDR des POD
			[ "$#" -ge "2" ] || {
				error "Parameter $1 needs a value"
			    exit 1
			}
			POD_CIDR="$2"
			shift
			;;
		*)
			error "Unknown parameter ($1)"
			exit 1
			;;
	esac
	shift
done

check_prereqist

[ "$buildall" == "${_true}" ] || [ "$buildsources" == "${_true}" ] && build_sources
[ "$buildall" == "${_true}" ] || [ "$showversions" == "${_true}" ] && show_versions
[ "$buildall" == "${_true}" ] || [ "$showenv" == "${_true}" ] && show_env
[ "$buildall" == "${_true}" ] || [ "$createclusterconf" == "${_true}" ] && create_cluster_conf


for i in ${kubelet_instances//,/ }
do
	k8s_kubelet_generate_conf \
		"${KUBERNETES_CLUSTER_NAME}" \
	    "https://${KUBERNETES_PUBLIC_ADDRESS}:6443" \
		"$i"
done


export KUBECONFIG="${cluster_conf_path}"/conf/admin.conf
#source <(kubectl completion bash)

