#!/bin/sh

git filter-branch --prune-empty -d /dev/shm/scratch \
  --index-filter "git rm -r --cached -f --ignore-unmatch modules" \
  --tag-name-filter cat -- --all


