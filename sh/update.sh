#!/usr/bin/env bash

set -e

sudo apt --yes update
sudo apt --yes autoremove
sudo apt --yes clean
