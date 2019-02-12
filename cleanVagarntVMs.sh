#!/bin/bash
set -eu
vagrant global-status
for i in `vagrant global-status | grep virtualbox | grep -v default | awk '{ print $1 }'` ; do vagrant destroy $i ; done