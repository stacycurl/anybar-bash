#!/bin/bash

# Change the colour of an AnyBar
# Usage:
#   anybar <colour> <n>
#     Change the colour of the n'th AnyBar
#   anybar <colour>
#     Change the colour of this tab's AnyBar
#   anybar
#     Change the colour of this tab's AnyBar to white (resetting it)
function anybar() {
  local COLOUR=${1-white}
  local OFFSET=${2:-$(_anybar_iterm_offset)}
  local ANYBAR_PORT=$((1738 + $OFFSET))

  echo -n $COLOUR | nc -4u -w0 localhost $ANYBAR_PORT
}

# Monitor a long running command using AnyBar
# This sets AnyBar to orange whilst the command is running,
# then to green or red depending on whether the command succeeded or not
#
# Usage:
#   alias m=anybar_monitor
#   s <some command>
function anybar_monitor() {
  if [ $# -eq 0 ]; then
    anybar white
  else
    anybar orange
    $@

    local EXIT_STATUS=$?
    if [ $EXIT_STATUS -ne 0 ]; then
      anybar red
    else
      anybar green
    fi

    return $EXIT_STATUS
  fi
}

# Start monitoring all commands automatically
function anybar_monitor_enable() {
  case $ANYBAR_MONITOR_STATUS in
    "uninitialised") _anybar_monitor_initialise;;
    *)              ANYBAR_MONITOR_STATUS="enabled";;
  esac
}

# Stop monitoring all commands automatically
function anybar_monitor_disable() {
  ANYBAR_MONITOR_STATUS="disabled"
}

function _anybar_iterm_offset() {
  local ITERM_SESSION_OFFSET=0
  if [ $ITERM_SESSION_ID ]; then
      ITERM_SESSION_OFFSET=$((1 + ${ITERM_SESSION_ID:3:1}))
  fi
  echo $ITERM_SESSION_OFFSET

}

# Given
#   AnyBar instances are launched right-to-left
#   iTerm tabs are launched left-to-right
#   There's no way of counting the number of iTerm tabs
# When
#   A new iTerm tab is launched
# Then
#   Relaunch the AnyBars, in inverse order
#
# TODO: Figure out how to reorder AnyBar menu items >> No need to relaunch
function _anybar_relaunch() {
  {
    $(killall AnyBar)
  } &> /dev/null

  local ITERM_SESSION_OFFSET=$(_anybar_iterm_offset)

  until [ $ITERM_SESSION_OFFSET -lt 1 ]; do
    local TAB_INDEX=$(($ITERM_SESSION_OFFSET - 1))
    $(_anybar_launch $TAB_INDEX)
    let ITERM_SESSION_OFFSET-=1
  done
}

function _anybar_launch() {
  local TAB_INDEX=$1
  ANYBAR_PORT=$((1738 + $TAB_INDEX + 1)) open -na AnyBar
}

ANYBAR_MONITOR_STATUS="uninitialised"
function _anybar_monitor_initialise() {
  shopt -s extdebug

  ANYBAR_LAST_COMMAND=""

  _anybar_monitor_all_the_things () {
      [ "$ANYBAR_MONITOR_STATUS" != "enabled" ] && return

      [ -n "$COMP_LINE" ] && return  # do nothing if completing

      [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ] && return # don't cause a preexec for $PROMPT_COMMAND

      local ANYBAR_COMMAND=`HISTTIMEFORMAT= history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//"`;
      local ANYBAR_COMMAND_0=${this_full_command%% *}

      # Don't want to re-run this as the first command when initialising!
      # Don't intercept low-level disabling
      # Don't intercept these anybar functions
      # Intercepting builtin's seems to break them
      # Workaround for this trap mysteriously running twice
      if [[ "$ANYBAR_COMMAND" == "exit"              ]] ||
         [[ "$ANYBAR_COMMAND" == "shopt -u extdebug" ]] || \
         [[ "$ANYBAR_COMMAND" =~ ^anybar             ]] || \
         [[ "$ANYBAR_COMMAND" =~ ^_anybar            ]] || \
         [[ "$(type -t $ANYBAR_COMMAND_0)" == "builtin" ]] || \
         [[ "$ANYBAR_COMMAND" == "$ANYBAR_LAST_COMMAND" ]]
      then
          return 0
      fi

      ANYBAR_LAST_COMMAND=$ANYBAR_COMMAND

      anybar orange
      eval "$ANYBAR_COMMAND"
      local EXIT_STATUS=$?
      if [ $EXIT_STATUS -ne 0 ]; then
        anybar red
      else
        anybar green
      fi

      return 1 # This prevent executing of original command
  }

  trap '_anybar_monitor_all_the_things' DEBUG

  ANYBAR_MONITOR_STATUS="enabled"
}
