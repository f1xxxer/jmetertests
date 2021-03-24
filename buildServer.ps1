docker stop jm
docker rm jm
docker rmi jm:1
docker build -t jm:1 -f .\server\Dockerfile .