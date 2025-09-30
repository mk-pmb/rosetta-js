#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
set -o errexit -o pipefail

function compile () {
  ( cat -- node_modules/dlv/index.js
    <node_modules/templite/src/index.js sed -re 's~ion ~&templite~'
    echo '@@'
    <src/index.js sed -zre '
      s!ion !&rosetta!
      s!ypeof val!!g
      s!if!const t = typeof val; if!
      s! tmpl\(! templite(!
      '
  ) | sed -re '/^import /d;s~^export default ~~' |
    sed -zre 's~\s+~\t~g; s~(\w)\t(\w)~\1 \2~g; s~\t~~g'
}

CORE="$(compile)"

function bundle () {
  local "$@"
  local DEST="dist/index.$FMT"
  local CODE="$PRE(function(){$CORE}$SUF);"
  CODE="${CODE/@@/$MID}"
  echo "$CODE" >"$DEST"
  stat -c $'%n = %s bytes' -- "$DEST"
}

bundle FMT='amd.js' PRE='define' MID=$'\nreturn ' SUF=''
bundle FMT='js'     PRE='' MID=$'\nmodule.exports=\n' SUF='()'
bundle FMT='mjs'    PRE='export default ' MID=$'\nreturn ' SUF='()'
bundle FMT='win.js' PRE='' MID=$'window\n.libRosetta=\n' SUF='()'
