echo "making tarball" 1>&2

cd /
mkdir -p /tmp/sdk
tar -cpPR \
    ${SDKROOT}/config \
    ${SDKROOT}/python3-was? \
    ${SDKROOT}/wasm32-*-shell.sh \
    ${SDKROOT}/*sdk \
    ${SDKROOT}/scripts/*sdk-fetch.sh \
    ${SDKROOT}/devices/* \
    ${SDKROOT}/prebuilt/* \
     > /tmp/sdk/python${PYBUILD}-wasm-sdk-${CIVER}.tar
    lz4 -c --favor-decSpeed --best /tmp/sdk/python${PYBUILD}-wasm-sdk-${CIVER}.tar \
     > /tmp/sdk/python${PYBUILD}-wasm-sdk-${CIVER}.tar.lz4


echo "done"  1>&2

