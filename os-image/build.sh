#!/bin/sh

set -e

cd unipi

mirage configure -t hvt
make depends
make build
