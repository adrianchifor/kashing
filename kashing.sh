#!/bin/bash

if [ -z ${FOREX+x} ]; then echo "FOREX env var is not set, exiting."; exit 0; fi
if [ -z ${ONEFORGE_API_KEY+x} ]; then echo "ONEFORGE_API_KEY env var is not set, exiting."; exit 0; fi

sendAlert() {
  alertText="$1"

  # Only send SMS when the following env vars are set
  if [[ ! -z ${NEXMO_API_KEY+x} && ! -z ${NEXMO_API_SECRET+x} && ! -z ${PHONE_NO+x} ]]; then
    # We only send an SMS if:
    #   - smsSent.text and smsSent.hour don't exist OR
    #   - the current alertText is different from the one in smsSent.text AND
    #   - the current hour is different from the one in smsSent.hour
    lastSmsText=$(cat smsSent.text 2> /dev/null)
    lastSmsHour=$(cat smsSent.hour 2> /dev/null)
    if [[ $lastSmsText != "$alertText" && $lastSmsHour != $(date +"%H") ]]; then
      # Send alert SMS
      curl -X POST -s -S --retry 3 --retry-delay 3 https://rest.nexmo.com/sms/json \
        -d api_key=$NEXMO_API_KEY \
        -d api_secret=$NEXMO_API_SECRET \
        -d to=$PHONE_NO \
        -d from="Kashing" \
        -d text="$alertText"

      echo "`date` -- Sent SMS alert: $alertText"

      # Set SMS text into file
      echo "$alertText" > smsSent.text
      # Set SMS hour into file
      date +"%H" > smsSent.hour
    fi
  fi

  # Only send email when the following env vars are set
  if [[ ! -z ${SENDGRID_KEY+x} && ! -z ${EMAIL+x} ]]; then
    # We only send an email if:
    #   - emailSent.text and emailSent.hour don't exist OR
    #   - the current alertText is different from the one in emailSent.text AND
    #   - the current hour is different from the one in emailSent.hour
    lastEmailText=$(cat emailSent.text 2> /dev/null)
    lastEmailHour=$(cat emailSent.hour 2> /dev/null)
    if [[ $lastEmailText != "$alertText" && $lastEmailHour != $(date +"%H") ]]; then
      # Send alert email
      curl -X POST -s -S --retry 3 --retry-delay 3 https://api.sendgrid.com/v3/mail/send \
        --header "Authorization: Bearer $SENDGRID_KEY" \
        --header 'Content-Type: application/json' \
        --data '{"personalizations": [{"to": [{"email": "'$EMAIL'"}]}],"from": {"email": "kashing@kashing.com"},"subject": "Money Money!","content": [{"type": "text/plain", "value": "'"$alertText"'"}]}'

      echo "`date` -- Sent email alert: $alertText"

      # Set email text into file
      echo "$alertText" > emailSent.text
      # Set email hour into file
      date +"%H" > emailSent.hour
    fi
  fi

  return 0
}

# Trim whitespace from FOREX env var
forexNoWs=$(echo "$FOREX" | tr -d "[:space:]")
# Read the forex groups ( [<currencyPair>|<minVal>|<maxVal>, ..] ) into array
IFS=';' read -ra forexArr <<< "$forexNoWs"

currencyPairs=""

# Loop through forex groups array and populate currencyPairs string to batch request forex rates
for forex in "${forexArr[@]}"; do
  IFS='|' read currencyPair minVal maxVal <<< "$forex"

  currencyPairs+="$currencyPair,"
done

# Make GET request to 1Forge for quotes on currencyPairs from desired forex groups
forexJson=$(curl -X GET -s -S --retry 3 --retry-delay 3 \
  "https://forex.1forge.com/1.0.2/quotes?pairs=$currencyPairs&api_key=$ONEFORGE_API_KEY")

if [[ $forexJson != "" ]]; then
  alertText=""

  # Check each forex group for min/max values against current price and construct SMS message.
  for forex in "${forexArr[@]}"; do
    IFS='|' read currencyPair minVal maxVal <<< "$forex"

    # Can be either "BUY" (price >= max), "SELL" (price <= min) or "" (price between min and max)
    action=$(echo $forexJson | jq ".[] | select(.symbol == \"$currencyPair\") | \
      if .price >= $maxVal then \"BUY\" elif .price <= $minVal then \"SELL\" else \"\" end")

    if [[ $action != "\"\"" ]]; then
      price=$(echo $forexJson | jq ".[] | select(.symbol == \"$currencyPair\") | .price")

      if [[ $action == "\"BUY\"" ]]; then
        alertText+="$currencyPair is at $price (>= $maxVal). "
      elif [[ $action == "\"SELL\"" ]]; then
        alertText+="$currencyPair is at $price (<= $minVal). "
      fi
    else
      echo "`date` -- No alerts for $currencyPair."
    fi
  done

  if [[ $alertText != "" ]]; then
    sendAlert "$alertText"
  fi
else
  echo "`date` -- 1Forge did not return any results for GET request."
fi
