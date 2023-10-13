#!/bin/bash
# *** Copyright 2023 Quantum Brilliance ***
#
# This script does the most simple install possible of Qristal on an Ubuntu 22.04 system

set -e

sudo apt update -y
sudo apt install -y build-essential cmake gfortran libboost-all-dev libcurl4-openssl-dev libssl-dev libopenblas-dev libpython3-dev python3 python3-pip

if [ -d ~/qb ]; then
  echo
  echo "Your path for installing Qristal is: ~/qb"
  echo
else
  echo
  echo "Creating a path for installing Qristal: ~/qb"
  mkdir -p ~/qb
fi

cd ~
mkdir -p ~/qb/install/qristal
mkdir -p ~/qb/source
cd ~/qb/source

if [ -d ~/qb/source/qristal ]; then
  echo
  echo "Reusing existing Qristal"
else 
  echo
  echo "Cloning Qristal repository"
  git clone https://github.com/qbrilliance/qristal.git
fi

# Build and install Qristal
cd qristal && mkdir build && cd build
cmake .. -DINSTALL_MISSING=ON -DCMAKE_INSTALL_PREFIX=~/qb/install/qristal -DWITH_TKET=ON
make -j$(nproc) install

echo
echo "Qristal has been installed successfully!"
echo
echo "Example usage: start Python and run a random 3 qubit circuit of depth 4"
echo
echo "import qb.core"
echo "ses = qb.core.session()"
echo "ses.qb12()      # Set up defaults"
echo "ses.qn = 3      # Set up 3 qubits"
echo "ses.random = 4  # Set up depth 4 random circuit"
echo "ses.run()"
echo "ses.out_raw[0]  # View the measured outcomes "

