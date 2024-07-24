#!/bin/sh
set -eux

for file in /patches/patch_*.sh; do
  sh -c "$file";
done
