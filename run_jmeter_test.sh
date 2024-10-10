#!/bin/bash

SERVICE_CODE="${SERVICE_CODE:-mobius-utility-service}"
JMX_PATH="/mobius-performance-testing/blob/sanity-suite/bob-camunda-quarkus.jmx"
REPORT_DIR="sanity-reports"
JMX_RESULTS_FILE="$REPORT_DIR/statistics.json"

# Check if the JMX script exists
if [ -f "$JMX_PATH" ]; then
	echo "JMX script found: $JMX_PATH"
else
	echo "JMX script not found: $JMX_PATH"
	exit 1
fi

# Run JMeter test
echo "Running JMeter test for service: $SERVICE_CODE"
mkdir -p $REPORT_DIR
jmeter -n -t "$JMX_PATH" -l "$REPORT_DIR/results.jtl" -e -o "$REPORT_DIR/"

# Check if results are generated
if [ ! -f "$JMX_RESULTS_FILE" ]; then
	echo "JMeter results not found. Test failed."
	exit 1
fi

# Analyze the results for errors
ERROR_COUNT=$(jq '.Total.errorCount' $JMX_RESULTS_FILE)
SAMPLE_COUNT=$(jq '.Total.sampleCount' $JMX_RESULTS_FILE)
AVG_RESPONSE_TIME=$(jq '.Total.meanResTime' $JMX_RESULTS_FILE)

echo "JMeter Test Summary:"
echo "Total Samples: $SAMPLE_COUNT"
echo "Total Errors: $ERROR_COUNT"
echo "Average Response Time: $AVG_RESPONSE_TIME ms"

if [ "$ERROR_COUNT" -eq 0 ]; then
	echo "Sanity test passed."
else
	echo "Sanity test failed with $ERROR_COUNT errors."
	exit 1
fi
