#!/bin/sh
# CI gate: Bloc-only presentation layer (no Cubit).
if rg "extends Cubit" lib/ 2>/dev/null; then
  echo "ERROR: Cubit found in lib/. Use Bloc<Event, State> only."
  exit 1
fi
echo "OK: no Cubit in lib/"
