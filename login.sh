#!/usr/bin/env bash

# 1a. read in the retroarch.cfg INI file
# 1b. prompt for the Login Server URL if it's not already set
#     in the INI file
# 2. display a dialog showing the current login status
# 3. run a `curl` command in the background that waits
#    for a response from the Login Server instance
# 4a. set up a new user profile if the ID is new
# 4b. update the savefile and statestate directory entries
#     pointing to the logged in user's dirs

user="$SUDO_USER"
[[ -z "$user" ]] && user=$(id -un)
home=$(eval echo "~$user")

source "$home/RetroPie-Setup/scriptmodules/inifuncs.sh"

CONFIG_FILE="/opt/retropie/configs/all/retroarch.cfg"
iniConfig " = " '"' "$CONFIG_FILE"

trap finish TERM
export TOP_PID=$$

# "save_profiles_directory" is the directory where user profiles will be
# stored, and symlinks to the current active profile will be kept as well
iniGet "save_profiles_directory"
if [[ -z "$ini_value" ]]; then
  PROFILES_ROOT="$home/RetroPie/save-profiles"
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
  rc=$?
  if [ $rc -ne 0 ]; then
    # user hit Cancel
    exit 1
  fi
  LOGIN_SERVER_URL=$(cat "$TMP_OUTPUT")
  rm "$TMP_OUTPUT"
  iniSet "save_profiles_login_server" "$LOGIN_SERVER_URL"
else
  LOGIN_SERVER_URL="$ini_value"
fi

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
  if [ $rc -ne 0 ]; then
    logout_current
  else
    # the user cancelled the dialog before we got a login event so close `curl`
    kill -s TERM $TOP_PID
  fi
}

function curl_login() {
  LOGIN=$(curl --silent --location "$LOGIN_SERVER_URL/login")
  rc=$?

  if [ $rc -ne 0 ]; then
    dialog \
      --colors \
      --ok-label "Close" \
      --title "Login Error" \
      --msgbox "\ncurl exit code $rc: $LOGIN\n" \
      0 0
    exit 1
  fi

  # load the curl response as env variables. ID and NAME must be exported.
  eval $(echo "$LOGIN")

  if [[ -z "$ID" ]] || [[ -z "$NAME" ]]; then
    dialog \
      --colors \
      --ok-label "Close" \
      --title "Login Error" \
      --msgbox "\nLogin Server did not specify the ID or NAME variables!"
      0 0
    exit 1
  fi

  PROFILE_ROOT="$PROFILES_ROOT/$ID"
  USER_SAVE_FILES="$PROFILE_ROOT/save-files"
  USER_SAVE_STATES="$PROFILE_ROOT/save-states"

  mkdir -p "$USER_SAVE_FILES" "$USER_SAVE_STATES"

  # save down the name just for fun/debugging
  echo "$NAME" > "$PROFILE_ROOT/.name"

  # not a huge deal if this fails, but we'll try anyways
  # (i.e. the root is on a NFS drive that doesn't allow permission changes)
  chown -R $user:$user "$PROFILES_ROOT" 2>/dev/null

  iniSet "savefile_directory" "$USER_SAVE_FILES"
  iniSet "savestate_directory" "$USER_SAVE_STATES"
  iniSet "save_profiles_current_id" "$ID"
  iniSet "save_profiles_current_name" "$NAME"

  dialog \
    --colors \
    --ok-label "Close" \
    --title "Login Success!" \
    --msgbox "\nSuccessfully logged in as:\n\n    \Zb$NAME\ZB\n\n" \
    0 0
}

function logout_current() {
  iniGet "save_profiles_current_name"
  CURRENT_NAME="$ini_value"

  iniUnset "savefile_directory"
  iniUnset "savestate_directory"
  iniUnset "save_profiles_current_id"
  iniUnset "save_profiles_current_name"

  dialog \
    --colors \
    --ok-label "OK" \
    --title "Logged Out" \
    --msgbox "\n\Zb$CURRENT_NAME\ZB has been logged out.\n" \
    0 0

  show_status_dialog
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
