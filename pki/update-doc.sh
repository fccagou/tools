#!/usr/bin/bash

./pki doc fr > README.md
./pki doc en > README-en.md

comment="${1:-update}"

git commit -m "doc(pki): $comment" pki-doc-*.sh README*.md

