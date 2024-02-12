if $emsdk
then
    TAG=wasm
else
    TAG=wasi
fi

echo "making $TAG tarball" 1>&2

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
     > /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar
    lz4 -c --favor-decSpeed --best /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar \
     > /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar.lz4

echo "done"  1>&2

