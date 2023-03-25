#!/bin/sh
set -eu

warn() {
  printf '%s %s\n' "$(date '+%FT%T')" "$*" >&2
}

die() {
  warn "FATAL:" "$@"
  exit 1
}

main() {
  warn "ENTRYPOINT starting; $(id)"

  # normally this will only be one directory
  export R_LIBS="${R_LIBS:-}"
  for dir in /app/renv/library/R-*/*/; do
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
