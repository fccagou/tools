#!/bin/sh

git filter-branch -f --prune-empty -d /dev/shm/scratch \
  --index-filter "git rm -r --cached -f --ignore-unmatch modules files" \
  --tag-name-filter cat -- --all


