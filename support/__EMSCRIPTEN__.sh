#!/bin/bash

. ${CONFIG:-config}

echo "
    *__EMSCRIPTEN__*
"


if grep -q PYDK src/cpython${PYBUILD}/Programs/python.c
then
    echo "
        * __EMSCRIPTEN__ support already added
    " 1>&2
else
    pushd src/cpython${PYBUILD}
    if echo $PYBUILD |grep -q 3.11$
    then
        [ -f "Parser/pegen_errors.c" ] && patch -p1 <<END
--- Python-3.11.2/Parser/pegen_errors.c	2023-02-07 14:37:51.000000000 +0100
+++ Python-3.11.2-wasm/Parser/pegen_errors.c	2023-03-03 16:18:08.672666445 +0100
@@ -249,7 +249,7 @@
      * (multi-line) statement are stored in p->tok->interactive_src_start.
      * If not, we're parsing from a string, which means that the whole source
      * is stored in p->tok->str. */
-    assert((p->tok->fp == NULL && p->tok->str != NULL) || p->tok->fp == stdin);
+    assert((p->tok->fp == NULL && p->tok->str != NULL) || p->tok->fp != NULL);

     char *cur_line = p->tok->fp_interactive ? p->tok->interactive_src_start : p->tok->str;
     if (cur_line == NULL) {
END
    else
        echo 3.12+ does not need patching for interactive FD
    fi

    # fix the main so it gets along with minimal wasm startup

    cat > Programs/python.c <<END
/* Minimal main program -- everything is loaded from the library */

#include "Python.h"

#if __PYDK__
#include "pycore_call.h"          // _PyObject_CallNoArgs()
#include "pycore_initconfig.h"    // _PyArgv
#include "pycore_interp.h"        // _PyInterpreterState.sysdict
#include "pycore_pathconfig.h"    // _PyPathConfig_ComputeSysPath0()
#include "pycore_pylifecycle.h"   // _Py_PreInitializeFromPyArgv()
#include "pycore_pystate.h"       // _PyInterpreterState_GET()

static PyStatus
pymain_init(const _PyArgv *args)
{
    PyStatus status;

    status = _PyRuntime_Initialize();
    if (_PyStatus_EXCEPTION(status)) {
        return status;
    }

    PyPreConfig preconfig;
    PyPreConfig_InitPythonConfig(&preconfig);

    status = _Py_PreInitializeFromPyArgv(&preconfig, args);
    if (_PyStatus_EXCEPTION(status)) {
        return status;
    }

    PyConfig config;
    PyConfig_InitPythonConfig(&config);

    if (args->use_bytes_argv) {
        status = PyConfig_SetBytesArgv(&config, args->argc, args->bytes_argv);
    }
    else {
        status = PyConfig_SetArgv(&config, args->argc, args->wchar_argv);
    }
    if (_PyStatus_EXCEPTION(status)) {
        goto done;
    }

    status = Py_InitializeFromConfig(&config);
    if (_PyStatus_EXCEPTION(status)) {
        goto done;
    }
    status = _PyStatus_OK();

done:
    PyConfig_Clear(&config);
    return status;
}

static void
pymain_free(void)
{
    _PyImport_Fini2();
    _PyPathConfig_ClearGlobal();
    _Py_ClearStandardStreamEncoding();
    _Py_ClearArgcArgv();
    _PyRuntime_Finalize();
}

#include "${ROOT}/support/__EMSCRIPTEN__.c"
#else
int
main(int argc, char **argv)
{

    return Py_BytesMain(argc, argv);
}
#endif //#if __PYDK__
END

    popd
fi
