# some links

    curl -L -O https://github.com/d3/d3/releases/download/v5.12.0/d3.zip


# git-heatmap

Generates an github like svg heatmap for the last year of changes of the current
git repository. (see [heatmap.html](heatmal.html))

    curl -o some/dir/in/path/git-heatmap https://raw.githubusercontent.com/fccagou/tools/master/git/git-heatmap \
    && chmod +x some/dir/in/path/git-heatmap

    git heatmap help


GIT-HEATMAP(1)

NAME

        git-heatmap [--help|help] [--color-legend |
                 [--all-in-one-html]
                 [--output-dir=DIR_FOR_MULTI_FILES]
                 [--years=[ all | YYYY,[AAAA,BBBB] ] ]
                 [--aggregate]
                 [--svg-only]
                 [--svg-fill]
                 [--id=<string_id>]
                 [--title=<string>]
                 [branch1,[branch2,...]
             ]

    --help|help                           : this help

    --id                                  : An id used to identifiy the results.
                                            The id must be a string in [A-Za-z-_]* format.
                                            The id is used in html title dans put files name.

    --title                               : Set html page title. Default is "Git Heatmap"

    --color-legend                        : display only the color legend (for debug)

    --all-in-one-html                     : If many branches or provides, add all svg in one file
                                            and all is send on stdout

    --svg-only                            : Only generate svg. Default is "no"

    --svg-fill                            : Fill svg instead of using css coloration.
                                            Usefull with --svg-only to insert svg in other web page.
                                            Default is "no"

    --output-dir                          : Creates one file by year in DIR_FOR_MULTI_FILES dir.
                                            Default is "/dev/shm/git_heatmap"

    --years                               : All years in YYYY format separated by ','.
                                            If not set, the current year is used.
                                            If set to "all", all the repo years will checked since
                                            the first commit.

    --aggregate                           : In case of many branches, make a graphe with the sum
                                            off all branches. Dafault is "no"

    branch1,[branch2,...]]                : All the branches to check separated by ','.
                                            Default is current branch.
EXAMPLE

    # Current year activity for current branch.
    git heatmap > /dev/shm/somefile.html
    xdg-open /dev/shm/somefile.html

	# Activities sinc the firt commit
    git heatmap --years=all --all-in-one-html --title="my repo name" > /dev/shm/all.html
    xdg-open /dev/shm/all.html


