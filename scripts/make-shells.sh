
CPU=${CPU:-wasm32}
TARGET=${TARGET:-emsdk}

cat > $ROOT/${PYDK_PYTHON_HOST_PLATFORM}-shell.sh <<END
#!/bin/bash
export ROOT=${SDKROOT}
export SDKROOT=${SDKROOT}

export PYBUILD=\${PYBUILD:-$PYBUILD}
export PYMAJOR=\$(echo -n \$PYBUILD|cut -d. -f1)
export PYMINOR=\$(echo -n \$PYBUILD|cut -d. -f2)

export CARGO_HOME=\${CARGO_HOME:-${SDKROOT}}/rust
export RUSTUP_HOME=\${RUSTUP_HOME:-${SDKROOT}}/rust
mkdir -p \${CARGO_HOME}/bin
export PATH=\${CARGO_HOME}/bin:\$PATH

export PANDA_PRC_DIR=${SDKROOT}/support


export PATH=${HOST_PREFIX}/bin:\$PATH:${SDKROOT}/devices/${TARGET}/usr/bin:${SDKROOT}/emsdk/node/16.20.0_64bit/bin
export LD_LIBRARY_PATH=${HOST_PREFIX}/lib:${LD_LIBRARY_PATH}

export PLATFORM_TRIPLET=${PYDK_PYTHON_HOST_PLATFORM}
export PREFIX=$PREFIX
export PYTHONPYCACHEPREFIX=${PYTHONPYCACHEPREFIX:-${SDKROOT}/build/pycache}
mkdir -p \$PYTHONPYCACHEPREFIX

# so pip does not think everything in ~/.local is useable
export HOME=${SDKROOT}

export PYTHONDONTWRITEBYTECODE=1

END


