#!/usr/bin/env bash

OUTPUT_FILE="$1"

apt list --installed > $OUTPUT_FILE
