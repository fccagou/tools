
## git-heatmap

![heatmap sample](git-heatmap.png)

Generates an Gitlab/github like svg heatmap for the last year of changes of the current
git repository. (see [heatmap.html](heatmap.html))




```bash
    curl -o some/dir/in/path/git-heatmap https://raw.githubusercontent.com/fccagou/tools/master/git/git-heatmap \
    && chmod +x some/dir/in/path/git-heatmap

    git heatmap help

GIT-HEATMAP(1)

NAME

        git-heatmap [--help|help]
                 [--all-in-one[=<filename>]]
                 [--aggregate]
                 [--color-legend]
                 [--id=<string_id>]
                 [--no-inline-html]
                 [--output-dir=DIR_FOR_MULTI_FILES]
                 [--svg-fill]
                 [--title=<string>]
                 [--update-css]
                 [--update-graph]
                 [--update-js]
                 [--years=[ all | YYYY,[AAAA,BBBB] ]
                 [branch1,[branch2,...]
             ]

    --help|help                           : this help

    --all-in-one                          : If many branches are provided, add all svg in one file
                                            and all is send on stdout.
                                            If a value is set, the value will be used for destinaton
                                            file. Default is "/dev/shm/git_heatmap/heatmap.html"
                                            Default is "no"

    --aggregate                           : In case of many branches, make a graphe with the sum
                                            off all branches. Dafault is "no"

    --color-legend                        : display only the color legend (for debug)

    --id                                  : An id used to identifiy the results.
                                            The id must be a string in [A-Za-z-_]* format.
                                            The id is used in html title dans put files name.

    --no-inline-html                      : Css and js will be created in external files;
                                            Default is "yes"

    --output-dir                          : Creates one file by year in DIR_FOR_MULTI_FILES dir.
                                            Default is "/dev/shm/git_heatmap"

    --svg-fill                            : Fill svg instead of using css coloration.
                                            Usefull with --update-graph to insert svg in other web page.
                                            Default is "no"

    --title                               : Set html page title. Default is "Git Heatmap"

    --update-css                          : Update css file (see --inline-html doc)

    --update-graph                        : Only generate svg. Default is "no".
                                            File will be created in "/dev/shm/git_heatmap/heatmap.svg"
                                            unless "--all-in-one" or "--outut-dir" params
                                            are used.

    --update-js                           : Update js  file (see --inline-html doc)


    --years                               : All years in YYYY format separated by ','.
                                            If not set, the current year is used.
                                            If set to "all", all the repo years will checked since
                                            the first commit.

    branch1,[branch2,...]]                : All the branches to check separated by ','.
                                            Default is current branch.
```

EXAMPLE

```bash
    # -- Current year activity for current branch in default dir.
    $ git heatmap
     |-> /dev/shm/git_heatmap/2021.html

    xdg-open /dev/shm/somefile.html

    # -- Create graphs for years 2021 and 2020
    $ git heatmap  --years=2021,2020
     |-> /dev/shm/git_heatmap/2021.html
     |-> /dev/shm/git_heatmap/2020.html

    # -- Years 2021 and 2020 in one file
    $ git heatmap  --years=2021,2020 --all-in-one
     |-> all in /dev/shm/git_heatmap/heatmap.html

    # -- Years 2021 and 2020 in one file
    $ git heatmap  --years=2021,2020 --all-in-one=/tmp/all.html
     |-> all in /tmp/all.html

    # -- Activities sinc the firt commit
    git heatmap --years=all --all-in-one --title="my repo name"
    |-> all in /dev/shm/git_heatmap/all.html
    xdg-open /dev/shm/git_heatmap/all.html

    # Create svg only in local dir
    $ git heatmap  --update-graph  --all-in-one=heatmap.html --years=2021,2020
    [+] Export svg
     |-> all in one file : heatmap.html
     |-> 2021
     |-> 2020

   # Creates all in /dev/shm/git-heatmap-all.html
   $ git heatmap  --all-in-one=/dev/shm/git-heatmap-all.html
   [+] Generate css and js
    |-> inline html
   [+] Generate html pages
    |-> all in /dev/shm/git-heatmap-all.html

   $ xdg-open /dev/shm/git-heatmap-all.html

```

## git-localmirror

Script used to manage local mirror. I Use it to sync git repository for
cgit with [mygitserver](https://gitlab.com/fccagou/mygitserver). Usefull for
airgap network or to dev unconnected.


```bash
Usage: git localmirror [COMMAND|URL]

    If no parameter used   : list
    URL                    : git mirror url to $HOME/repositories/Public

ENV VARIABLES:

    LOCALMIRRORDIR : local directory where repos are cloned
                     default: $HOME/repositories/Public
                     Current value: $HOME/repositories/Public

COMMANDS:

    help          : this help
    info          : display mirror infos
    list          : all local repos with remote url
                    --quiet list only local repo
                    --remotes list only remotes
    rm|del|delete : remove local repo defined in next parameter
                    parameter can be remote url or local repo name.
    update        : update all local mirror found in /home/fccagou/repositories/Public
```

EXAMPLE:

```bash

# -- Set local mirror
export LOCALMIRRORDIR=/tmp/mirror 

# mirror repos
$ git localmirror https://gitlab.com/fccagou/tools.git 
Clonage dans le dépôt nu '/tmp/mirror/gitlab.com/fccagou/tools.git'
remote: Enumerating objects: 1115, done.
remote: Counting objects: 100% (1115/1115), done.
remote: Compressing objects: 100% (768/768), done.
remote: Total 1115 (delta 620), reused 621 (delta 296), pack-reused 0 (from 0)
Réception d'objets: 100% (1115/1115), 534.08 Kio | 3.71 Mio/s, fait.
Résolution des deltas: 100% (620/620), fait.

$ git localmirror  https://gitlab.com/fccagou/mygitserver.git
Clonage dans le dépôt nu '/tmp/mirror/gitlab.com/fccagou/mygitserver.git'
remote: Enumerating objects: 90, done.
remote: Counting objects: 100% (90/90), done.
remote: Compressing objects: 100% (63/63), done.
remote: Total 90 (delta 40), reused 61 (delta 26), pack-reused 0 (from 0)
Réception d'objets: 100% (90/90), 37.37 Kio | 4.67 Mio/s, fait.
Résolution des deltas: 100% (40/40), fait.

# -- Show repo info
$ git localmirror  info
local mirror dir: /tmp/mirror
nb repos: 2
last   update: 2025-01-05 00:31:17 (https://gitlab.com/fccagou/mygitserver.git)
oldest update: 2025-01-05 00:24:14 (https://gitlab.com/fccagou/tools.git)
remotes:
  gitlab.com: 2


# -- Update all repos (how about using it in a crontab !?)
$ git localmirror update 
[*] updating ./gitlab.com/fccagou/tools.git : https://gitlab.com/fccagou/tools.git
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
Dépaquetage des objets: 100% (4/4), 373 octets | 33.00 Kio/s, fait.
Depuis https://gitlab.com/fccagou/tools
   4c07240..d90e9a8  main       -> main
[*] updating ./gitlab.com/fccagou/mygitserver.git : https://gitlab.com/fccagou/mygitserver.git

# -- Remove a repo
$ git localmirror delete fccagou/tools
----------------------------------------------------------
 DELETE REPO
----------------------------------------------------------

fullpath: /tmp/mirror/gitlab.com/fccagou/tools.git
name: ./gitlab.com/fccagou/tools.git
remotes:
  origin: https://gitlab.com/fccagou/tools.git
refs:
  refs/heads/main: refact(git-localmirror): some display changes
  refs/heads/pki: test(pki): fix hosts list
  refs/heads/rhel: feat(git/mr): add date of the first commit in list command
last commits:
  - (il y a 8 minutes) <fccagou> refact(git-localmirror): some display changes
  - (il y a 46 minutes) <fccagou> refact(git-localmirror): add LOCALMIRRORDIR env var
  - (il y a 65 minutes) <fccagou> refact(git-localmirror): add forgotten message in repo_info
  - (il y a 76 minutes) <fccagou> feat(git-mirror): add delete parameter
  - (il y a 77 minutes) <fccagou> refact: enhanced path using readlink
  - (il y a 2 heures) <fccagou> fix(git-localmirror): manage list parameter
  - (il y a 2 heures) <fccagou> fix(git-localmirror): display none when repo has no remote
  - (il y a 3 heures) <fccagou> feat(git-localmirror): add repo_info function
  - (il y a 3 heures) <fccagou> feat(git-localmirror): change remotes display in info command
  - (il y a 3 heures) <fccagou> refact(git-localmirror): move list code to function to add paremeters (see help)
Are you sure  (y/N) ?:y
[+] Delete repo ./gitlab.com/fccagou/tools.git...ok
```

When deleting a repo, the command takes care to local repositories without
remotes to avoid loosing data as shown in next example.

```bash

# -- Got a local repos created with git init --bare /tmp/mirror/local/....
$ git localmirror info
local mirror dir: /tmp/mirror
nb repos: 3
last   update: 2025-01-05 00:47:45 (https://gitlab.com/fccagou/tools.git)
oldest update: 2025-01-05 00:33:10 (https://gitlab.com/fccagou/mygitserver.git)
remotes:
  gitlab.com: 2
  local: 1

# -- Get repo list
$ git localmirror
./gitlab.com/fccagou/tools.git        https://gitlab.com/fccagou/tools.git
./gitlab.com/fccagou/mygitserver.git  https://gitlab.com/fccagou/mygitserver.git
./local/local-mirror-test.git         noremote

# -- Just delete the local one
$ git localmirror delete local-mirror-test
----------------------------------------------------------
 DELETE REPO
----------------------------------------------------------

fullpath: /tmp/mirror/local/local-mirror-test.git
name: ./local/local-mirror-test.git
remotes: none
refs:
  refs/heads/main: INITIALE version
last commits:
  - (il y a 2 heures) <fccagou> INITIALE version
Are you sure  (y/N) ?:y

 ===== WARNING ==================

  The repo has no remote, you will lost ALL the code.

Are you REALY sure (y/N) ?:

```


