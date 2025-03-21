#!/bin/sh
set -eu

warn() {
  printf '%s %s\n' "$(date '+%FT%T')" "$*" >&2
}

main() {
  warn "ENTRYPOINT starting; $(id) in $(pwd)"

  # normally this will only be one directory
  export R_LIBS="${R_LIBS:-}"
  for dir in /app/renv/library/R-*/*/ /usr/local/lib/R/site-library/; do
    if [ -n "$R_LIBS" ]; then
      R_LIBS="${R_LIBS}:${dir}"
    else
      R_LIBS="${dir}"
    fi
  done

  # ensure required envvars are set / report those vars
  : "R_LIBS=${R_LIBS}" # print this at startup to aid debugging

  set -x
  exec /app/ares.R "$@"
}

main "$@"; exit 1
