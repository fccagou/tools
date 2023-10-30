# Description

Simple tool using imagemagick to add watermark in file.

Useful to give personal documents for a unique usage.

# Prerequisite

This shell use ImageMagick. It must be installed on your system.


# Quick start

Using the sample file in the current directory, just run:

    ./watermark-add.sh --force --to test-watermark-output.pdf test-watermark.pdf 'My cat is a h@k3r!'

# Mode help


    Usage: ./watermark-add.sh [OPTIONS] <filename> <"watermark to add">
    
    OPTIONS:
    
       --help|-h            : display this help
    
       --color color        : text color in #rgb format or color name (Default: gray)
       --dest-dir dirname   : output prefix (Default: .)
       --to filename        : output filename (Default: ./<filename>)
       --force              : force output overide (default: no)

