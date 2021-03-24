#!/bin/bash
set -e
freeMem=`awk '/MemFree/ { print int($2/1024) }' /proc/meminfo`
s=$(($freeMem/10*8))
x=$(($freeMem/10*8))
n=$(($freeMem/10*2))
export JVM_ARGS="-Xmn${n}m -Xms${s}m -Xmx${x}m"

echo "START Running Jmeter on `date`"
echo "JVM_ARGS=${JVM_ARGS}"
echo "Running jmeter -n -t /${TEST_DIR}/${TEST_FILE} -l /${TEST_DIR}/test-results.jtl -R ${SERVERS} -e -o /${TEST_DIR}/report -j /${TEST_DIR}/controller-run.log"

# We use environment variables to set test folder and test plan file
jmeter -n -t "/${TEST_DIR}/${TEST_FILE}" -l "/${TEST_DIR}/test-results.jtl" -R ${SERVERS} -e -o /${TEST_DIR}/report -j "/${TEST_DIR}/controller-run.log"
echo "END Running Jmeter on `date`"
