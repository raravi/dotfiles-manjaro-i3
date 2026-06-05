#!/bin/bash

# Read notification from STDIN
noti=""
while read line
do
    noti=${noti}${line}
done < "${1:-/dev/stdin}"

# Use jq to parse JSON and get the body field of the notification
body=$(echo $noti | jq '.body')
if [[ "$body" == "\"<a href=\\\"https://web.whatsapp.com/\\\">web.whatsapp.com</a>"* ]]; then
      # It's Whatsapp web, lets modify the notification
      isWhatsapp=1
      body=$(echo $body | cut -c 64-)
      img=$(echo $noti | jq '.image')
      if [[ "$img" == "\"NamedIcon \\\""* ]]; then
          filepath=$(echo $img | cut -c 14- | head -c -4)
          cp $filepath /tmp/whatsappimg.png
      fi
fi

if [[ "$isWhatsapp" == "1" ]]; then
    # Returning the modifications to dnc as JSON
    echo "{\"modify\": {\"app-icon\": \"whatsapp-desktop\", \"app-name\": \"WhatsApp\", \"image\": \"file:///tmp/whatsappimg.png\", \"remove-actions\": true, \"class-name\": \"WhatsApp\", \"body\":\"${body}}, \"match\": {}}"
else
    echo '{"modify": {}, "match": {}}'
fi
