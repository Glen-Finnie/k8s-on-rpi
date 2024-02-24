#!/usr/bin/env bash

set -e

sudo apt --yes full-upgrade
sudo apt --yes autoremove
sudo apt --yes clean
