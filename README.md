# python-wasm-sdk
Tooling for building CPython and various packages (either third parties support or Python modules)
for WebAssembly


See https://github.com/pygame-community/pygame-ce/blob/main/.github/workflows/build-emsdk.yml
for how to use it

or use as a cross compiler, after being unpacked in /opt/python-wasm-sdk, from within
a module source distribution :

eg `/opt/python-wasm-sdk/python3-wasm setup.py bdist_wheel`

or 

`/opt/python-wasm-sdk/python3-wasm -m build --no-isolation .`

or 

`/opt/python-wasm-sdk/python3-wasm -m pip install --no-build-isolation --force .`

