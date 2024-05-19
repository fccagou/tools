
# Description

Simple scripts to manage setup `docker-rootless` in own dir using `rootlesskit`
built from sources.

- `myrootless.sh` : build and configure docker-rootless in own env
- `useradd.sh`: as root, it's used to create dedicated docker rootless user

# Pre-requisite

`myrootless.sh` clones and builds `rootlesskit` 
- git is needed for clone
- golang is needed to build rootlesskit

# Quick start

Build and Install

```bash
ROOTLESSDIR="$HOME"/.local ./myrootless.sh install
```

Check

```bash
$ docker context ls
NAME         DESCRIPTION                               DOCKER ENDPOINT                     ERROR
default      Current DOCKER_HOST based configuration   unix:///var/run/docker.sock         
rootless *   Rootless mode                             unix:///run/user/1000/docker.sock   
```
Then 

```bash
$ docker images
REPOSITORY                        TAG                  IMAGE ID       CREATED         SIZE

```

