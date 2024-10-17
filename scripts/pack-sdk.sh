if $emsdk
then
    TAG=wasm
else
    TAG=wasi
fi

echo "making $TAG tarball" 1>&2

pushd /
mkdir -p /tmp/sdk
tar -cpPR \
    ${SDKROOT}/config \
    ${SDKROOT}/emsdk-cc \
    ${SDKROOT}/python3-was? \
    ${SDKROOT}/wasm32-*-shell.sh \
    ${SDKROOT}/*sdk \
    ${SDKROOT}/scripts/*sdk-fetch.sh \
    ${SDKROOT}/devices/* \
    ${SDKROOT}/prebuilt/* \
    ${SDKROOT}/native \
    ${SDKROOT}/bun \
     > /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar
    lz4 -c --favor-decSpeed --best /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar \
     > /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar.lz4
    rm /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar
echo "done"  1>&2
popd
