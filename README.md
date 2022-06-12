# python-wasm-sdk
Tooling for building CPython+Pygame on WebAssembly


example building from within own pygame git clone tree on ubuntu 20.04 or linux mint :
```bash
#!/bin/bash
# update system
sudo apt-get update
sudo apt-get install -y git bash python3-pip curl lz4 pv
sudo mkdir -p /opt/python-wasm-sdk && sudo chown $(whoami) /opt/python-wasm-sdk


# in github CI, current working dir would be /home/runner/pygame/pygame.
[ -d ../pygame ] || git clone https://github.com/pygame/pygame
if [ -f setup.py ]
then

    # update cython
    if [ -f ../dev ]
    then
        echo "  * not upgrading cython"
    else
        pip3 install git+https://github.com/cython/cython.git --user --upgrade
    fi

    # update source tree
    git clean -f
    git pull

    mkdir -p /opt/python-wasm-sdk

    # sdk
    if [ -f /opt/python-wasm-sdk/python3-wasm ]
    then
        echo "  * not upgrading python-wasm-sdk"
    else
        echo "  * using cached python-wasm-sdk archive"

        if [ -f ../python-wasm-sdk-stable.tar.lz4 ]
        then
#            time tar xfvjP ../python-wasm-sdk-stable.tar.bz2 \
#             | pv -f -c -p -l -s 20626 >/dev/null
            time tar xfvP ../python-wasm-sdk-stable.tar.lz4 --use-compress-program=lz4 \
             | pv -f -c -p -l -s 20626 >/dev/null
        else
            curl -sL --retry 5 https://github.com/pygame-web/python-wasm-sdk/releases/download/0.2.0/python-wasm-sdk-stable.tar.bz2 \
             | tar xvPj \
             | pv -f -c -p -l -s 20626 >/dev/null
        fi
    fi

    # build pygame
    touch $(find |grep pxd$)
    python3 setup.py config cython >/dev/null

    /opt/python-wasm-sdk/python3-wasm setup.py -config -auto -sdl2 >/dev/null

    # /opt/python-wasm-sdk/python3-wasm setup.py build
    EMCC_CFLAGS="-fPIC -I/opt/python-wasm-sdk/devices/emsdk/usr/include/SDL2 -s USE_SDL=2" /opt/python-wasm-sdk/python3-wasm setup.py build -j1


    mkdir -p dist
    # get static lib
    SYS_PYTHON=python3 /opt/python-wasm-sdk/emsdk/upstream/emscripten/emar rcs dist/libpygame.a $(find build/temp.wasm32-*/|grep o$)

fi
```
