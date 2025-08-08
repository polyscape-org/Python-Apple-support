#!/bin/bash

FRAMEWORK_BASEDIR=$1
echo "Making $1 relocatable"
PYTHON_VER=${FRAMEWORK_BASEDIR##*/}
echo "Python version ${PYTHON_VER}"

pushd ${FRAMEWORK_BASEDIR}

echo "Rewrite ID of Python library"
install_name_tool -id @rpath/Python.framework/Versions/${PYTHON_VER}/Python Python > /dev/null
for dylib in `ls lib/*.*.dylib`; do
    # lib
    if [ "${dylib}" != "lib/libpython${PYTHON_VER}.dylib" ] ; then
        echo Rewrite ID of ${dylib}
        install_name_tool -id @rpath/Python.framework/Versions/${PYTHON_VER}/${dylib} ${FRAMEWORK_BASEDIR}/${dylib}
    fi
done
for module in `find . -name "*.dylib" -type f -o -name "*.so" -type f`; do
    if [ "$(otool -L ${module} | grep -c /Library/Frameworks/Python.framework)" != "0" ]; then
        for dylib in `ls lib/*.*.dylib`; do
            echo Rewrite references to ${dylib} in ${module}
            install_name_tool -change /Library/Frameworks/Python.framework/Versions/${PYTHON_VER}/${dylib} @rpath/Python.framework/Versions/${PYTHON_VER}/${dylib} ${module}
       done
    fi
done

for exe in ./bin/*; do
    if [ -f "$exe" ] && [ -x "$exe" ] && [ ! -L "$exe" ]; then
        echo "Rewrite references to Python library in ${exe}"
        install_name_tool -change /Library/Frameworks/Python.framework/Versions/${PYTHON_VER}/Python @rpath/Python.framework/Versions/${PYTHON_VER}/Python ${exe}
        echo "Add rpath to ${exe}"
        install_name_tool -add_rpath @executable_path/../../../.. ${exe}
    fi
done

echo "Rewrite references to Python library in Python executable"
install_name_tool -change /Library/Frameworks/Python.framework/Versions/${PYTHON_VER}/Python @rpath/Python.framework/Versions/${PYTHON_VER}/Python ./Resources/Python.app/Contents/MacOS/Python
echo "Add rpath to Python executable"
install_name_tool -add_rpath @executable_path/../../../../../../.. ./Resources/Python.app/Contents/MacOS/Python
