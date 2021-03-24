docker stop jc
docker rm jc
docker rmi jc:1
docker build -t jc:1 -f .\Controller\Dockerfile .