#!/bin/sh

#  ci_post_clone.sh
#  CiRCLES
#
#  Created by シン・ジャスティン on 2024/07/09.
#  

OPENID_PLIST_PATH="$CI_PRIMARY_REPOSITORY_PATH/CiRCLES/OpenID.plist"

/usr/libexec/PlistBuddy -c "Clear dict" $OPENID_PLIST_PATH || /usr/libexec/PlistBuddy -c "Add : dict" $OPENID_PLIST_PATH

/usr/libexec/PlistBuddy -c "Add :client_id string $OPENID_CLIENT_ID" $OPENID_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :client_secret string $OPENID_CLIENT_SECRET" $OPENID_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :redirect_url string $OPENID_CLIENT_REDIRECT_URL" $OPENID_PLIST_PATH

echo "OpenID.plist created at $OPENID_PLIST_PATH"
