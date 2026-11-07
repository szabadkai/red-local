#!/bin/bash
cd -- "$(dirname -- "$0")" || exit 1
if command -v node >/dev/null 2>&1; then
  exec node tools/serve.mjs --open
elif command -v python3 >/dev/null 2>&1; then
  exec python3 tools/serve.py
else
  echo 'Install Node.js or Python 3 to run this local web game.'
  read -r -p 'Press Enter to close.'
fi
