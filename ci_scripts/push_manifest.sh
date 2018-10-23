export IMAGE_TAG=$(cat VERSION)

docker manifest create --amend cachengo/tensorflow-cpu:$IMAGE_TAG cachengo/tensorflow-cpu-x86_64:$IMAGE_TAG cachengo/tensorflow-cpu-aarch64:$IMAGE_TAG
docker manifest push cachengo/tensorflow-cpu:$IMAGE_TAG
