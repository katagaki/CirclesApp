#!/bin/zsh
# Captures raw App Store screenshots into Raw/<device>/.
# Usage: ./capture.sh               (both iPhone and iPad)
#        DEVICES=iPad ./capture.sh
#        ONLY=04-detail,05-translate ./capture.sh   (retakes some shots)
#
# Each run copies the catalog, favorites and login from SOURCE_SIMULATOR into a
# dedicated screenshot simulator, so no catalog data lives in the repository.
# The AppStoreScreenshots UI test then walks the app with Privacy Mode on and
# writes the captures. Run compose.swift afterwards to lay them into the
# Keynote designs.
set -e

SCRIPT_DIR=${0:A:h}
PROJECT=${SCRIPT_DIR:h:h:h}/Apple/CiRCLES.xcodeproj
SCHEME="CiRCLES (Production API)"
BUNDLE_ID=com.tsubuzaki.CiRCLES
APP_GROUP=group.com.tsubuzaki.CiRCLES
SOURCE_SIMULATOR=${SOURCE_SIMULATOR:-"CiRCLES Route Lines 2"}
DERIVED_DATA=/tmp/circles-screenshots-dd
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-27-0
SIMULATORS=~/Library/Developer/CoreSimulator/Devices
# The Keynote frames are an iPhone 17 Pro and an iPad mini, so the captures
# come from devices with the same screen shapes.
typeset -A DEVICE_TYPES=(
  iPhone com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro
  iPad com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro
)

udid_of() {
  xcrun simctl list devices | grep -F "$1 (" | head -1 | grep -oE '[0-9A-F-]{36}' || true
}

simulator() {
  local name="CiRCLES Screenshots $1" udid
  udid=$(udid_of $name)
  if [[ -z $udid ]]; then
    udid=$(xcrun simctl create "$name" $DEVICE_TYPES[$1] $RUNTIME)
  fi
  echo $udid
}

# A specific group identifier is refused, so it is picked out of the list.
group_container() {
  xcrun simctl get_app_container $1 $BUNDLE_ID groups | awk -v group=$APP_GROUP '$1 == group { print $2 }'
}

boot() {
  xcrun simctl boot $1 2>/dev/null || true
  xcrun simctl bootstatus $1 -b >/dev/null
}

# MARK: - Build

xcodebuild build-for-testing -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination "generic/platform=iOS Simulator" -derivedDataPath $DERIVED_DATA \
  -allowProvisioningUpdates -quiet
APP=$DERIVED_DATA/Build/Products/Release-iphonesimulator/CiRCLES.app
XCTESTRUN=$(ls $DERIVED_DATA/Build/Products/*.xctestrun | head -1)

# MARK: - Seeding

SOURCE=$(udid_of $SOURCE_SIMULATOR)
[[ -n $SOURCE ]] || { echo "no simulator named $SOURCE_SIMULATOR"; exit 1 }
boot $SOURCE
SOURCE_DATA=$(xcrun simctl get_app_container $SOURCE $BUNDLE_ID data)
SOURCE_GROUP=$(group_container $SOURCE)

# A fresh install with the source's app data, app group and keychain, which
# holds the circle.ms login. The keychain is only swapped while shut down.
seed() {
  local udid=$1 data group
  boot $udid
  xcrun simctl terminate $udid $BUNDLE_ID 2>/dev/null || true
  xcrun simctl uninstall $udid $BUNDLE_ID 2>/dev/null || true
  xcrun simctl install $udid $APP
  data=$(xcrun simctl get_app_container $udid $BUNDLE_ID data)
  group=$(group_container $udid)
  xcrun simctl shutdown $udid
  for dir in Documents Library; do
    rm -rf "$data/$dir"
    cp -Rc "$SOURCE_DATA/$dir" "$data/$dir"
  done
  rm -rf "$data/Library/Saved Application State" "$data/Library/SplashBoard"
  rm -rf "$group"/*
  cp -Rc "$SOURCE_GROUP"/* "$group/"
  rm -rf $SIMULATORS/$udid/data/Library/Keychains
  cp -Rc $SIMULATORS/$SOURCE/data/Library/Keychains $SIMULATORS/$udid/data/Library/Keychains
  boot $udid
  xcrun simctl status_bar $udid override --time 9:41 \
    --batteryState discharging --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 --operatorName ""
}

# MARK: - Capture

# UI tests on a freshly booted simulator now and then miss a tap, so a failed
# run is given one more go.
run_test() {
  run_test_once "$@" || run_test_once "$@"
}

# Prints only the assertion that failed, if any; -quiet would hide it.
run_test_once() {
  local log=$(mktemp) test_status=0
  TEST_RUNNER_SCREENSHOT_DIR=$2 TEST_RUNNER_SCREENSHOT_ONLY=$ONLY \
    xcodebuild test-without-building -xctestrun $XCTESTRUN -destination "id=$1" \
    -only-testing:AppStoreScreenshots/AppStoreScreenshots/testScreens \
    -test-timeouts-enabled YES -maximum-test-execution-time-allowance 900 >$log 2>&1 || test_status=$?
  grep -E "error: -\[|Test Case .* failed" $log || true
  rm -f $log
  return $test_status
}

capture() {
  local device=$1 udid=$(simulator $1)
  local raw_dir="$SCRIPT_DIR/Raw/$device"
  mkdir -p "$raw_dir"
  seed $udid
  run_test $udid "$raw_dir" || { echo "capture failed on $device"; exit 1 }
  echo "captured $device"
}

# One device at a time: two UI test runs side by side miss taps and time out.
for device in ${=DEVICES:-iPhone iPad}; do
  capture $device
done
