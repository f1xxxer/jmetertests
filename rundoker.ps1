docker stop jm
docker rm jm
docker run -e "TEST_DIR=trivial" --name jm jm:1