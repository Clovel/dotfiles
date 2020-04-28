#!/usr/bin/env bash

OUTPUT_FILE="$1"
OUTPUT_FILE_CASK="$2"

brew list > $OUTPUT_FILE
brew cask list > $OUTPUT_FILE_CASK
