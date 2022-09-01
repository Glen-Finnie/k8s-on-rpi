#!/usr/bin/env bash

set -e

sudo apt --yes update
sudo apt --yes upgrade
sudo apt --yes dist-upgrade
sudo apt --yes autoremove
sudo apt --yes clean
