#!/bin/sh

set -e

cd src
mirage configure
mirage build
