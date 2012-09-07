#!/bin/bash
#
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Rebuild all prebuilts. This requires that you have a toolchain source tree
#

. `dirname $0`/prebuilt-common.sh
PROGDIR=`dirname $0`

NDK_DIR=$ANDROID_NDK_ROOT
register_var_option "--ndk-dir=<path>" NDK_DIR "Put binaries into NDK install directory"

BUILD_OUT=/tmp/ndk-$USER/build
OPTION_BUILD_OUT=
register_var_option "--build-out=<path>" OPTION_BUILD_OUT "Specify temporary build directory"

ARCHS=$DEFAULT_ARCHS
register_var_option "--arch=<arch>" ARCHS "Specify target architectures"

GCC_VERSION_LIST=$DEFAULT_GCC_VERSION_LIST
register_var_option "--gcc-ver-list=<list>" GCC_VERSION_LIST "Specify GCC versions to build"

SYSTEMS=$HOST_TAG32
if [ "$HOST_TAG32" = "linux-x86" ]; then
    SYSTEMS=$SYSTEMS",windows"
fi
CUSTOM_SYSTEMS=
register_option "--systems=<list>" do_SYSTEMS "Specify host systems"
do_SYSTEMS () { CUSTOM_SYSTEMS=true; SYSTEMS=$1; }

RELEASE=`date +%Y%m%d`
PACKAGE_DIR=/tmp/ndk-$USER/prebuilt-$RELEASE
register_var_option "--package-dir=<path>" PACKAGE_DIR "Put prebuilt tarballs into <path>."

DARWIN_SSH=
if [ "$HOST_OS" = "linux" ] ; then
register_var_option "--darwin-ssh=<hostname>" DARWIN_SSH "Specify Darwin hostname for remote build."
fi

register_try64_option

SKIP_HOST_PREBUILTS=no
register_option "--skip-host-prebuilts" do_skip_host_prebuilts "Skip build of host prebuilts"
do_skip_host_prebuilts ()
{
    SKIP_HOST_PREBUILTS=yes
}

SKIP_TARGET_PREBUILTS=no
register_option "--skip-target-prebuilts" do_skip_target_prebuilts "Skip build of target prebuilts"
do_skip_target_prebuilts ()
{
    SKIP_TARGET_PREBUILTS=yes
}

PROGRAM_PARAMETERS="<toolchain-src-dir>"
PROGRAM_DESCRIPTION=\
"This script is used to rebuild all host and target prebuilts from scratch.
You will need to give the path of a toolchain source directory, one which
is typically created with the download-toolchain-sources.sh script.

Unless you use the --ndk-dir option, all binaries will be installed to the
current NDK directory.

All prebuilts will then be archived into tarball that will be stored into a
specific 'package directory'. Unless you use the --package-dir option, this
will be: $PACKAGE_DIR

Please read docs/DEV-SCRIPTS-USAGE.TXT for more usage information about this
script.
"

extract_parameters "$@"

fix_option BUILD_OUT "$OPTION_BUILD_OUT" "build directory"
setup_default_log_file $BUILD_OUT/build.log

SRC_DIR="$PARAMETERS"
check_toolchain_src_dir "$SRC_DIR"

if [ "$DARWIN_SSH" -a -z "$CUSTOM_SYSTEMS" ]; then
    SYSTEMS=$SYSTEMS",darwin-x86"
fi

FLAGS=
if [ "$VERBOSE" = "yes" ]; then
    FLAGS=$FLAGS" --verbose"
fi
if [ "$VERBOSE2" = "yes" ]; then
    FLAGS=$FLAGS" --verbose"
fi
if [ "$DRY_RUN" = "yes" ]; then
    FLAGS=$FLAGS" --dry-run"
fi
FLAGS=$FLAGS" --ndk-dir=$NDK_DIR"
FLAGS=$FLAGS" --package-dir=$PACKAGE_DIR"
FLAGS=$FLAGS" --arch=$(spaces_to_commas $ARCHS)"
FLAGS=$FLAGS" --gcc-ver-list=$(spaces_to_commas $GCC_VERSION_LIST)"

if [ -n "$XCODE_PATH" ]; then
    FLAGS=$FLAGS" --xcode=$XCODE_PATH"
fi

if [ -n "$OPTION_BUILD_OUT" ]; then
    FLAGS=$FLAGS" --build-out=$BUILD_OUT"
fi

HOST_FLAGS=$FLAGS" --systems=$(spaces_to_commas $SYSTEMS)"
if [ "$TRY64" = "yes" ]; then
    HOST_FLAG=$HOST_FLAGS" --try-64"
fi
if [ "$DARWIN_SSH" ]; then
    HOST_FLAGS=$HOST_FLAGS" --darwin-ssh=$DARWIN_SSH"
fi

if [ "$SKIP_HOST_PREBUILTS" != "yes" ]; then
    $PROGDIR/build-host-prebuilts.sh $HOST_FLAGS "$SRC_DIR"
    fail_panic "Could not build host prebuilts!"
fi

TARGET_FLAGS=$FLAGS

if [ "$SKIP_TARGET_PREBUILTS" != "yes" ]; then
    $PROGDIR/build-target-prebuilts.sh $TARGET_FLAGS "$SRC_DIR"
    fail_panic "Could not build target prebuilts!"
fi

echo "Done, see $PACKAGE_DIR:"
ls -l $PACKAGE_DIR

exit 0
