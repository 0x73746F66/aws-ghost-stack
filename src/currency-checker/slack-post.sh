#!/usr/bin/env bash
set -o errexit

# Usage: date | ./slack-post.sh
# Usage: echo "Hello Word" | ./slack-post.sh

if [ -f $HOME/.slack ]; then
    source $HOME/.slack
fi
if [ -f ./.slack ]; then
    source ./.slack
fi

if [ -z "$TOKEN" ]; then
    echo "No TOKEN specified"
    exit 1
fi
if [ -z "$BASE_URL" ]; then
    echo "No BASE_URL specified"
    exit 1
fi

while read LINE; do
        text="$text\n$LINE"
done

if [ -z "$text" ]; then
    echo "No text specified"
    exit 1
fi

escapedText=$(echo $text | sed 's/"/\"/g' | sed "s/'/\'/g" )
json="$(printf '{"text": "%s"' \
    "${escapedText}" \
)"
if [ "$username" != "" ]; then
    json+="$(printf ', "username": "%s", "as_user": "true", "link_names": "true"' \
        "${username}" \
    )"
fi
if [ "$icon_emoji" != "" ]; then
    json+="$(printf ', "icon_emoji": "%s"' \
        "${icon_emoji}" \
    )"
fi
json+='}'

status="$(curl -s -d -X POST --silent --data-urlencode "payload=$json" "$BASE_URL$TOKEN")"

if [ "$status" != "ok" ]; then
  echo "curl error [$status]"
  exit 1
fi

