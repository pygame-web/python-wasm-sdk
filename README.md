# python-wasm-sdk
Tooling for building CPython+Pygame on WebAssembly


example building from within own pygame git clone tree on ubuntu 20.04 or linux mint :
```bash
#!/bin/bash

# in github CI, current working dir would be /home/runner/pygame/pygame.

# update system
sudo apt-get update
sudo apt-get install -y bash python3-pip curl pv

# update cython
pip3 install git+https://github.com/cython/cython.git --upgrade

# update source tree
git clean -f
git pull

# sdk
sudo mkdir -p /opt/python-wasm-sdk && sudo chown $(whoami) /opt/python-wasm-sdk
curl -sL --retry 5 https://github.com/pygame-web/python-wasm-sdk/releases/download/0.1.0/python-wasm-sdk-stable.tar.bz2 \
 | tar xvPj \
 | pv -f -c -p -l -s 20626 >/dev/null

# build pygame
touch $(find |grep pxd$)
python3 setup.py config cython

/opt/python-wasm-sdk/python3-wasm setup.py -config -auto -sdl2

/opt/python-wasm-sdk/python3-wasm setup.py build

# get static lib
SYS_PYTHON=python3 /opt/python-wasm-sdk/emsdk/upstream/emscripten/emar rcs libpygame.a $(find build/temp.wasm32-*/|grep o$)
```
