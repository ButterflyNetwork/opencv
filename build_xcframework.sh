#!/usr/bin/env bash
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR" || exit 1
mkdir -p dist || exit 1

build_framework() {
  python platforms/ios/build_framework.py \
    --without calib3d \
    --without dnn \
    --without features2d \
    --without flann \
    --without gapi \
    --without highgui \
    --without imgcodecs \
    --without ml \
    --without objdetect \
    --without photo \
    --without stitching \
    --without video \
    --without videoio \
    --without world \
    "$@" || return $?
}

build_sim_framework() {
  sim_arch="$1"
  if [ -d "dist/ios-sim-$sim_arch" ]; then
    echo "Framework found for simulator arch $sim_arch, skipping..."
    return
  fi
  build_framework --iphonesimulator_archs "$sim_arch" "dist/ios-sim-$sim_arch"
}

build_device_framework() {
  device_arch="$1"
  if [ -d "dist/ios-device-$device_arch" ]; then
    echo "Framework found for device arch $device_arch, skipping..."
    return
  fi
  build_framework --iphoneos_archs "$device_arch" "dist/ios-device-$device_arch"

}

build_xcframework() {
  build_sim_framework "x86_64" || return 1
  build_sim_framework "arm64" || return 1
  build_device_framework "arm64" || return 1
  xcrun xcodebuild -create-xcframework \
    -framework "dist/ios-sim-x86_64/opencv2.framework" \
    -framework "dist/ios-sim-arm64/opencv2.framework" \
    -framework "dist/ios-device-arm64/opencv2.framework" \
    -output dist/opencv2.xcframework || return 2
}

build_xcframework || exit "$?"
