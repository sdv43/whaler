#!/bin/bash

cd "$(dirname "$0")"

sass \
    ./variants/elementary-dark.scss:./dist/elementary-dark.css \
    ./variants/elementary-light.scss:./dist/elementary-light.css \
    --no-source-map \
    -w