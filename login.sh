#!/usr/bin/env bash

# 1. display a `dialog` to show who is currently logged in and the Login URL
# 2. run a server in the background that waits for a `PUBLISH login` event
#    from the Redis auth server
# 3. 

# get some useful functions and global variables (the jsfuncs sources inifuncs)
#source "/opt/retropie/supplementary/joystick-selection/jsfuncs.sh"

#start_joy2key

trap finish TERM
export TOP_PID=$$

# XXX: get real values from `retroarch.cfg` file
PROFILES_ROOT=$(pwd)
LOGIN_SERVER_URL="http://127.0.0.1:3030"

CURRENT_ENV="$PROFILES_ROOT/current.env"
CURRENT_SAVE_FILES="$PROFILES_ROOT/current-save-files"
CURRENT_SAVE_STATES="$PROFILES_ROOT/current-save-states"

CURL_COMMAND="curl --silent $LOGIN_SERVER_URL/login"

# display the current status info dialog and login URL
function show_status_dialog() {
  if [ -f "$CURRENT_ENV" ]; then
    #echo "evaling $CURRENT_ENV"
    eval $(cat "$CURRENT_ENV")
    CURRENT_NAME=$FB_NAME
    BOX_TYPE=yesno
  else
    CURRENT_NAME="** NOBODY ** 😢"
    BOX_TYPE=msgbox
  fi

  dialog \
   --colors \
   --yes-label "Cancel" \
   --no-label "Logout" \
   --ok-label "Cancel" \
   --title "RetroPie Profiles" \
   --$BOX_TYPE "Currently logged in as:\n\n    \Zb$CURRENT_NAME\ZB\n\nVisit the following URL on your mobile device to log in:\n\n    \Z4\Zu$LOGIN_SERVER_URL\Z0\ZU\n\n" \
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
    echo "$LOGIN" > "$CURRENT_ENV"
    eval $(echo "$LOGIN")
    USER_SAVE_FILES="$PROFILES_ROOT/$FB_ID/save-files"
    USER_SAVE_STATES="$PROFILES_ROOT/$FB_ID/save-states"
    mkdir -p "$USER_SAVE_FILES" "$USER_SAVE_STATES"
    rm -rf "$CURRENT_SAVE_FILES"
    ln -s "$USER_SAVE_FILES" "$CURRENT_SAVE_FILES"
    rm -rf "$CURRENT_SAVE_STATES"
    ln -s "$USER_SAVE_STATES" "$CURRENT_SAVE_STATES"

    dialog \
     --colors \
     --ok-label "Close" \
     --title "Login Success!" \
     --msgbox "Successfully logged in as:\n\n    \Zb$FB_NAME\ZB\n\n" \
     0 0
  fi
}

function logout_current() {
  rm -rf "$CURRENT_ENV" "$CURRENT_SAVE_FILES" "$CURRENT_SAVE_STATES"
  dialog \
   --colors \
   --ok-label "Close" \
   --title "Logged Out" \
   --msgbox "Logged out" \
   0 0
  kill -s TERM $TOP_PID
}

function finish() {
  kill $DIALOG_PID
  kill $CURL_PID
  pkill $CURL_COMMAND
  stty -raw echo
}

show_status_dialog &
DIALOG_PID=$!
curl_login &
CURL_PID=$!
wait
