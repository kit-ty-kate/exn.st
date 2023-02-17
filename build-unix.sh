#!/bin/sh

set -e

mirage configure -f src/config.ml
make pull
mirage build -f src/config.ml
