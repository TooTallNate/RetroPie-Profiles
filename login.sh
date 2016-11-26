#!/usr/bin/env bash

# 1a. read in the retroarch.cfg INI file
# 1b. prompt for the Login Server URL if it's not already set
#     in the INI file
# 2. display a dialog showing the current login status
# 3. run a `curl` command in the background that waits
#    for a response from the Login Server instance
# 4a. set up a new user profile if the FB_ID is new
# 4b. set up symlinks for the savefile and statestate directories
#     pointing to the logged in user's dirs

user="$SUDO_USER"
[[ -z "$user" ]] && user=$(id -un)

source "$HOME/RetroPie-Setup/scriptmodules/inifuncs.sh"

CONFIG_FILE="/opt/retropie/configs/all/retroarch.cfg"
iniConfig " = " '"' "$CONFIG_FILE"

trap finish TERM
export TOP_PID=$$

# "save_profiles_directory" is the directory where user profiles will be
# stored, and symlinks to the current active profile will be kept as well
iniGet "save_profiles_directory"
if [[ -z "$ini_value" ]]; then
  PROFILES_ROOT="$HOME/RetroPie/save-profiles"
  iniSet "save_profiles_directory" "$PROFILES_ROOT"
else
  PROFILES_ROOT="$ini_value"
fi

# "save_profiles_login_server" is the Login Server to wait for a login
# event to come from.
# Set up a new Login Server instance for each RetroPie setup!
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
   --ok-label "Cancel" \
   --no-label "Logout" \
   --title "RetroPie Profiles" \
   --$BOX_TYPE "Currently logged in as:\n\n    \Zb$CURRENT_NAME\ZB\n\nVisit the following URL on your mobile device to log in:\n\n    \Z4\Zu$LOGIN_SERVER_URL\Z0\ZU\n\nProfiles dir: $PROFILES_ROOT\nConfig file: $CONFIG_FILE" \
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

    # not a huge deal if this fails, but we'll try anyways
    # (i.e. the root is on a NFS drive that doesn't allow permission changes)
    chown -R $user:$user "$PROFILES_ROOT" 2>/dev/null

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
  iniUnset "savefile_directory"
  iniUnset "savestate_directory"
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
  pkill "$CURL_COMMAND"
  stty -raw echo
}

show_status_dialog &
DIALOG_PID=$!
curl_login &
CURL_PID=$!
wait
