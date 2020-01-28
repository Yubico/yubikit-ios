#!/bin/sh

MOLY_STATIC_IP="moly01.local"
MOLY_SERVER_PORT="8080"
MOLY_COMMAND_PATH="moly"

MOLY_COMMAND_URL=$MOLY_STATIC_IP:$MOLY_SERVER_PORT/$MOLY_COMMAND_PATH

# Input params
INPUT_ACTION="$1"
echo "Executing action: $INPUT_ACTION"

ACTION_MESSAGE=""

# Execute action on MoLY
if [ "$INPUT_ACTION" = "plugin" ] ; then
    ACTION_MESSAGE="action=plugin"
elif [ "$INPUT_ACTION" = "plugout" ] ; then
    ACTION_MESSAGE="action=plugout"
elif [ "$INPUT_ACTION" = "touch" ] ; then
    ACTION_MESSAGE="action=touch"
fi

if [ ! "$ACTION_MESSAGE" = "" ] ; then
    curl -X POST -d $ACTION_MESSAGE $MOLY_COMMAND_URL
else
    echo "Unknown action: $ACTION_MESSAGE"
fi

echo "Done"
