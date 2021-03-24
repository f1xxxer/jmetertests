#!/bin/bash
set -e
freeMem=`awk '/MemFree/ { print int($2/1024) }' /proc/meminfo`
s=$(($freeMem/10*8))
x=$(($freeMem/10*8))
n=$(($freeMem/10*2))
echo "START Running Jmeter server on `date`"

echo "TEST_DIR=${TEST_DIR}"

# Keep entrypoint simple: we must pass the standard JMeter arguments
jmeter -n -s -j ${TEST_DIR}/server.log
echo "END Running Jmeter on `date`"