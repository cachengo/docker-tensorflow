export IMAGE_TAG=$(cat VERSION)
export AARCH=`uname -m`

docker build -t cachengo/tensorflow-cpu-$AARCH:$IMAGE_TAG .
docker push cachengo/tensorflow-cpu-$AARCH:$IMAGE_TAG
