#!/bin/bash

#SERVICE_CODE="${SERVICE_CODE:-mobius-utility-service}"  # Provided service code
#WORKFLOW_STATUS="$2"  # Status of the workflow (e.g., success, failure, no_data, service_down, etc.)
#WEBHOOK_URL="${WEBHOOK_URL:-https://chat.googleapis.com/v1/spaces/AAAAbkkpaIU/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=yYYoov7obNuUq86dW5E7RkHreUpcoROju45s_q7EIpM}"  # Webhook URL for Google Chat
#ACTION_URL="${ACTION_URL:-https://github.com/my-repo/actions/runs/12345}"  # Link to the GitHub action or job run details

SERVICE_CODE=$service_code
WORKFLOW_STATUS=$workflow_status
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/AAAAbkkpaIU/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=yYYoov7obNuUq86dW5E7RkHreUpcoROju45s_q7EIpM"  # Webhook URL for Google Chat
ACTION_URL=$action_url  # Customize this URL with the actual GitHub action or pipeline link

# Define the message based on the workflow status
case "$WORKFLOW_STATUS" in
  "success")
    MESSAGE=":white_check_mark: Workflow completed successfully for service: $SERVICE_CODE. [View Details]($ACTION_URL)"
    ;;
  "failure")
    MESSAGE=":x: Workflow failed for service: $SERVICE_CODE. [View Details]($ACTION_URL)"
    ;;
  "no_data")
    MESSAGE=":warning: No data received from the previous step for service: $SERVICE_CODE. [View Details]($ACTION_URL)"
    ;;
  "service_down")
    MESSAGE=":warning: The service $SERVICE_CODE appears to be down or unreachable. [View Details]($ACTION_URL)"
    ;;
  *)
    MESSAGE=":question: Unknown status for service: $SERVICE_CODE. [View Details]($ACTION_URL)"
    ;;
esac

# Send the notification to Google Chat
curl -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"$MESSAGE\"}"

echo "Notification sent to Google Chat with status: $WORKFLOW_STATUS."
