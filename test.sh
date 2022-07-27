#!/usr/bin/env bash

set -e # Fail script on any errors

dir=build
if [[ ! -e $dir ]]; then
    mkdir -p $dir
fi
$(vessel bin)/moc $(vessel sources) -wasi-system-api test/test.mo -o $dir/test.wasm

wasmtime $dir/test.wasm