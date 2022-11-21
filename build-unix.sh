#!/bin/sh

set -e

mirage configure -f src/config.ml
mirage build -f src/config.ml
