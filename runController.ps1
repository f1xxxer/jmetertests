docker stop jc
docker rm jc
docker run -e "TEST_DIR=trivial" -e "TEST_FILE=test-plan.jmx" -e "SERVERS=172.17.0.2" --name jc jc:1