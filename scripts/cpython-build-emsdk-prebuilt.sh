#!/bin/bash

. ${CONFIG:-config}

CYTHON_REL=${CYTHON_REL:-3.0.11}
CYTHON_WHL=${CYTHON:-Cython-${CYTHON_REL}-py2.py3-none-any.whl}

if echo $CYTHON_REL|grep -q 3\\.0\\.11$
then
    CYTHON_REL=3.0.11-1
fi


PIP="${SDKROOT}/python3-wasm -m pip"

$HPIP install \
 trove-classifiers pluggy pathspec packaging hatchling \
 typing_extensions mypy_extensions pyproject_hooks pyproject-metadata \
 build pyparsing packaging hatchling setuptools_scm \
 docutils setuptools meson meson-python \
 idna urllib3 charset_normalizer certifi tomli requests flit pip


# all needed for PEP722/723, hpy, cffi modules and wheel building
# those may contain tiny fixes for wasm and/or current unreleased cpython.

pushd src
    git clone --no-tags --depth 1 --single-branch --branch main https://github.com/pygame-web/flit
popd

for module in src/flit/flit_core \
 git+https://github.com/pygame-web/wheel \
 git+https://github.com/pygame-web/setuptools \
 git+https://github.com/pygame-web/cffi \
 git+https://github.com/pypa/installer
do
    echo "

  pre-installing $module
_____________________________________________
"  1>&2

    # $PIP install --no-build-isolation $module
    if $HPIP install --no-deps --no-index --no-build-isolation --force "$module"
    then
        echo -n ok
    else
        echo "  TARGET FAILED on required module $module" 1>&2
        exit 39
    fi
done



if [ ${PYMINOR} -ge 13 ]
then

    echo "


        USING CYTHON GIT for $PYBUILD




"
    # $HPIP install setuptools
    # compiling cython is way too slow so just get it pure with NO_CYTHON_COMPILE=true
    NO_CYTHON_COMPILE=true $HPIP install --upgrade --no-build-isolation --force git+https://github.com/pygame-web/cython.git
else
    # cython get the latest release on gh install on both host python and build python
    pushd build
        wget -q -c https://github.com/cython/cython/releases/download/${CYTHON_REL}/${CYTHON_WHL}
        $HPIP install --upgrade $CYTHON_WHL
    popd
    $PIP install build/$CYTHON_WHL
fi


# cannot use wasi ninja yet
$HPIP install --force ninja

# patch ninja for jobs limit and wrapper detection
# https://github.com/ninja-build/ninja/issues/1482

cat > ${HOST_PREFIX}/lib/python${PYBUILD}/site-packages/ninja/__init__.py <<END
from __future__ import annotations

import os
import subprocess
import sys
import sysconfig
from collections.abc import Iterable
from typing import NoReturn

from ._version import version as __version__
from .ninja_syntax import Writer, escape, expand

__all__ = ["BIN_DIR", "DATA", "Writer", "__version__", "escape", "expand", "ninja"]


def __dir__() -> list[str]:
    return __all__


def _get_ninja_dir() -> str:
    ninja_exe = "ninja" + sysconfig.get_config_var("EXE")

    # Default path
    path = os.path.join(sysconfig.get_path("scripts"), ninja_exe)
    if os.path.isfile(path):
        return os.path.dirname(path)

    # User path
    if sys.version_info >= (3, 10):
        user_scheme = sysconfig.get_preferred_scheme("user")
    elif os.name == "nt":
        user_scheme = "nt_user"
    elif sys.platform.startswith("darwin") and getattr(sys, "_framework", None):
        user_scheme = "osx_framework_user"
    else:
        user_scheme = "posix_user"

    path = sysconfig.get_path("scripts", scheme=user_scheme)

    if os.path.isfile(os.path.join(path, ninja_exe)):
        return path

    # Fallback to python location
    path = os.path.dirname(sys.executable)
    if os.path.isfile(os.path.join(path, ninja_exe)):
        return path

    return ""


BIN_DIR = _get_ninja_dir()


def _program(name: str, args: Iterable[str]) -> int:
    cmd = os.path.join('${HOST_PREFIX}/bin', name)
    return subprocess.call([cmd, *args], close_fds=False)

def ninja() -> NoReturn:
    import os
    os.environ['NINJA'] = "1"
    if not sys.argv[-1] != "--version":
        sys.argv.insert(1,'1')
        sys.argv.insert(1,'-j')
#        import time
#        while os.path.isfile('/tmp/ninja'):
#            time.sleep(.5)
#        open('/tmp/ninja','w').close()

    ret = _program('ninja.real', sys.argv[1:])
#    try:
#        os.unlink('/tmp/ninja')
#    except:
#        pass
    raise SystemExit(ret)

END



if [ -f $HOST_PREFIX/bin/ninja.real ]
then
    echo ninja already patched
else
    mv $HOST_PREFIX/bin/ninja $HOST_PREFIX/bin/ninja.real
    cat > $HOST_PREFIX/bin/ninja <<END
#!/opt/python-wasm-sdk/devices/x86_64/usr/bin/python3
# -*- coding: utf-8 -*-
import re
import sys
from ninja import ninja
if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    sys.exit(ninja())
END
    chmod +x $HOST_PREFIX/bin/ninja
fi



echo "
    *   cpython-build-emsdk-prebuilt pip==$PIP   *
" 1>&2



# some we want to be certain to have in all minimal rootfs
mkdir -p prebuilt/emsdk/common/site-packages/

# BUG 3.13 : installer

for pkg in pyparsing packaging pkg_resources
do
    if [ -d prebuilt/emsdk/${PYBUILD}/site-packages/$pkg ]
    then
        echo "
            $pkg already set to prebuilt
            "
    else
        if [ -d ${HOST_PREFIX}/lib/python${PYBUILD}/site-packages/${pkg} ]
        then
            cp -rf ${HOST_PREFIX}/lib/python${PYBUILD}/site-packages/${pkg} prebuilt/emsdk/common/site-packages/
            # skip the distinfo to save some space
            #cp -rf ${HOST_PREFIX}/lib/python${PYBUILD}/site-packages/${pkg}-* prebuilt/emsdk/common/site-packages/

        else
            cp -rf ${ROOT}/.local/lib/python${PYBUILD}/site-packages/{$pkg} prebuilt/emsdk/common/site-packages/
            # skip the distinfo to save some space
        fi
    fi
done


pushd src

# TODO
    if [ -d installer ]
    then
        echo "  * re-using installer git copy"
    else
        echo "  * getting installer git copy"
        git clone --no-tags --depth 1 --single-branch --branch main https://github.com/pypa/installer/
    fi
    cp -rf installer/src/installer ../prebuilt/emsdk/common/site-packages/

popd

rm ${SDKROOT}/prebuilt/emsdk/common/site-packages/installer/_scripts/*exe



# SDL2 is prebuilt in emsdk but lacks pkg config *.pc, wasi has them

if $WASI
then
    echo -n
else
    SYSROOT=${SDKROOT}/emsdk/upstream/emscripten/cache/sysroot

    cat > ${PREFIX}/lib/pkgconfig/sdl2.pc <<END
# sdl pkg-config source file

prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: sdl2
Description: Simple DirectMedia Layer is a cross-platform multimedia library designed to provide low level access to audio, keyboard, mouse, joystick, 3D hardware via OpenGL, and 2D v>
Version: 2.31.0
Requires.private:
Conflicts:
Libs: -L\${libdir} -lSDL2 -lm
Cflags: -I\${includedir} -I\${includedir}/SDL2 -I${SYSROOT}/include/SDL2 -I${SYSROOT}/include/freetype2"
END

    cat > ${PREFIX}/lib/pkgconfig/SDL2_mixer.pc <<END
prefix=${PREFIX}/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: SDL2_mixer
Description: mixer library for Simple DirectMedia Layer
Version: 2.8.0
Requires: sdl2 >= 2.0.9
Libs: -L\${libdir} -lSDL2_mixer
Cflags: -I\${includedir}/SDL2
Requires.private:
Libs.private:
END

fi


