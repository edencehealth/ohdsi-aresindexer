#!/bin/sh
# https://duckdb.org/docs/dev/building/troubleshooting#building-the-r-package-on-linux-aarch64
set -eux

mkdir -p ~/.R/

# shellcheck disable=SC2016
printf '%s\n' \
  'ALL_CXXFLAGS = $(PKG_CXXFLAGS) -fPIC $(SHLIB_CXXFLAGS) $(CXXFLAGS)' \
  > ~/.R/Makevars
