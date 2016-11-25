#!/usr/bin/env bash

# 1. display a `dialog` to show who is currently logged in and the Login URL
# 2. run a server in the background that waits for a `PUBLISH login` event
#    from the Redis auth server
# 3. 

source "$HOME/RetroPie-Setup/scriptmodules/helpers.sh"
source "$HOME/RetroPie-Setup/scriptmodules/inifuncs.sh"

joy2keyStart
iniConfig " = " '"' "$configdir/all/retroarch.cfg"

trap finish TERM
export TOP_PID=$$

# XXX: get real values from `retroarch.cfg` file
iniGet "save_profiles_directory"
if [[ -z "$ini_value" ]]; then
  PROFILES_ROOT="$HOME/RetroPie"
else
  PROFILES_ROOT="$ini_value"
fi

iniGet "save_profiles_login_server"
if [[ -z "$ini_value" ]]; then
  TMP_OUTPUT=$(mktemp)
  dialog --inputbox "Enter the Login Server URL:" 0 0 2>"$TMP_OUTPUT"
  LOGIN_SERVER_URL=$(cat "$TMP_OUTPUT")
  iniSet "save_profiles_login_server" "$LOGIN_SERVER_URL"
  rm "$TMP_OUTPUT"
else
  LOGIN_SERVER_URL="$ini_value"
fi

CURRENT_SAVE_FILES="$PROFILES_ROOT/current-save-files"
CURRENT_SAVE_STATES="$PROFILES_ROOT/current-save-states"

iniSet "savefile_directory" "$CURRENT_SAVE_FILES"
iniSet "savestate_directory" "$CURRENT_SAVE_STATES"

CURL_COMMAND="curl --silent $LOGIN_SERVER_URL/login"

# display the current status info dialog and login URL
function show_status_dialog() {
  iniGet "save_profiles_current_name"
  if [[ -z "$ini_value" ]]; then
    CURRENT_NAME="** NOBODY ** 😢"
    BOX_TYPE=msgbox
  else
    CURRENT_NAME="$ini_value"
    BOX_TYPE=yesno
  fi

  dialog \
   --colors \
   --yes-label "Cancel" \
   --no-label "Logout" \
   --ok-label "Cancel" \
   --title "RetroPie Profiles" \
   --$BOX_TYPE "Currently logged in as:\n\n    \Zb$CURRENT_NAME\ZB\n\nVisit the following URL on your mobile device to log in:\n\n    \Z4\Zu$LOGIN_SERVER_URL\Z0\ZU\n\nProfiles Dir: $PROFILES_ROOT" \
   0 0
  rc=$?
  if [[ $rc != 0 ]]; then
    logout_current
  else
    # the user cancelled the dialog before we got a login event so close `curl`
    kill -s TERM $TOP_PID
  fi
}

function curl_login() {
  LOGIN=$(curl --silent "$LOGIN_SERVER_URL/login")
  rc=$?

  if [[ $rc != 0 ]]; then
    dialog \
     --colors \
     --ok-label "Close" \
     --title "Login Error" \
     --msgbox "curl exit code $rc: $LOGIN" \
     0 0
  else
    eval $(echo "$LOGIN")
    USER_SAVE_FILES="$PROFILES_ROOT/$FB_ID/save-files"
    USER_SAVE_STATES="$PROFILES_ROOT/$FB_ID/save-states"

    mkdir -p "$USER_SAVE_FILES" "$USER_SAVE_STATES"
    rm -rf "$CURRENT_SAVE_FILES"
    ln -s "$USER_SAVE_FILES" "$CURRENT_SAVE_FILES"
    rm -rf "$CURRENT_SAVE_STATES"
    ln -s "$USER_SAVE_STATES" "$CURRENT_SAVE_STATES"

    iniSet "save_profiles_current_id" "$FB_ID"
    iniSet "save_profiles_current_name" "$FB_NAME"

    dialog \
     --colors \
     --ok-label "Close" \
     --title "Login Success!" \
     --msgbox "Successfully logged in as:\n\n    \Zb$FB_NAME\ZB\n\n" \
     0 0
  fi
}

function logout_current() {
  rm -rf "$CURRENT_SAVE_FILES" "$CURRENT_SAVE_STATES"
  iniUnset "save_profiles_current_id"
  iniUnset "save_profiles_current_name"
  dialog \
   --colors \
   --ok-label "Close" \
   --title "Logged Out" \
   --msgbox "Logged out" \
   0 0
  kill -s TERM $TOP_PID
}

function finish() {
  joy2keyStop
  kill $DIALOG_PID
  kill $CURL_PID
  pkill "$CURL_COMMAND"
  stty -raw echo
}

show_status_dialog &
DIALOG_PID=$!
curl_login &
CURL_PID=$!
wait
