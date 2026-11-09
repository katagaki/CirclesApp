#!/bin/zsh
# Usage: ./make-project.sh 01-Dock Dock "01 Dock"
set -e
folder=$1; target=$2; display=$3
cat > "$folder/project.yml" <<YML
name: $target
options:
  bundleIdPrefix: com.tsubuzaki.prototype.reorg
  deploymentTarget:
    iOS: "26.0"
  createIntermediateGroups: true
targets:
  $target:
    type: application
    platform: iOS
    sources:
      - $target
      - path: ../Kit
        name: Kit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.tsubuzaki.prototype.reorg.$target
        INFOPLIST_KEY_CFBundleDisplayName: "$display"
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        SWIFT_VERSION: "6.0"
        SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor
        TARGETED_DEVICE_FAMILY: "1,2"
        CODE_SIGNING_ALLOWED: NO
YML
cd "$folder" && xcodegen generate --quiet
