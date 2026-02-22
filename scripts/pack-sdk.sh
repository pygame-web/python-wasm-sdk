if $emsdk
then
    TAG=wasm
    PLAT="\
    ${SDKROOT}/versions \
    "
else
    TAG=wasi
    PLAT=""
fi

echo "  * Making $TAG tarball" 1>&2

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
    $PLAT > /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar

    # --favor-decSpeed

    if lz4 -c --best /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar \
     > /tmp/sdk/dist/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar.lz4
    then
        rm /tmp/sdk/python${PYBUILD}-${TAG}-sdk-${CIVER}.tar
    fi
echo "done"  1>&2
popd
