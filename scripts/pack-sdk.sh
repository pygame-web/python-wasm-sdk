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
     > /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar

    if lz4 -c --favor-decSpeed --best /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar \
     > /tmp/sdk/dist/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar.lz4
    then
        rm /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar
    fi
echo "done"  1>&2
popd
