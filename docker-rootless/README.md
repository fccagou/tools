
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
$ docker info 2>/dev/null | grep -E 'Context|Docker Root Dir' 
 Context:    rootless
 Docker Root Dir: /home/fccagou/.local/share/docker
```
Then 

```bash
$ docker images
REPOSITORY                        TAG                  IMAGE ID       CREATED         SIZE

```

