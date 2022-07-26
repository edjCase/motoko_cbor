#!/usr/bin/env bash

dir=build
if [[ ! -e $dir ]]; then
    mkdir -p $dir
fi
$(vessel bin)/moc $(vessel sources) -wasi-system-api src/main.mo -o $dir/cbor.wasm