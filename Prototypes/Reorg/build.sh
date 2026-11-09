#!/bin/zsh
# Usage: ./build.sh 01-Dock Dock  -> builds for iOS Simulator and installs on the Reorg simulators
set -e
folder=$1; target=$2
here=${0:A:h}
derived=/private/tmp/claude-501/reorg-derived/$target
cd "$here/$folder"
xcodebuild -project $target.xcodeproj -scheme $target -sdk iphonesimulator -configuration Debug \
  -derivedDataPath $derived -destination 'generic/platform=iOS Simulator' build -quiet 2>&1 | grep -E "error|warning: unre" || true
app=$derived/Build/Products/Debug-iphonesimulator/$target.app
test -d $app
for sim in "Reorg iPhone" "Reorg iPhone Duo" "Reorg iPad"; do
  xcrun simctl install "$sim" $app
done
echo "installed $app"
