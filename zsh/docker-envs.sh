# npm config set prefix "/home/node/.npm-global"
# export PATH="/home/node/.npm-global/bin:${PATH}"
# npm i -g npm-check-updates

docker-node () {
  docker run \
    -it \
    --rm \
    --name "$(basename $PWD)-node" \
    -v "$(pwd):$(pwd)" \
    -v /home/srghma/Downloads:/home/srghma/Downloads \
    -v /home/srghma/projects/srghma-chinese:/home/srghma/projects/srghma-chinese \
    -v /home/srghma/projects/anki-cards-from-pdf:/home/srghma/projects/anki-cards-from-pdf \
    -w "$(pwd)" \
    node:latest \
    "$@"
}

docker-ruby () {
  docker run \
    -it \
    --rm \
    --name "$(basename $PWD)-ruby" \
    -v "$(pwd):/usr/src/app" \
    -w /usr/src/app \
    ruby:latest \
    "$@"
}

docker-python () {
  docker run \
    -it \
    --rm \
    --name "$(basename $PWD)-python3" \
    -v "$(pwd):/usr/src/app" \
    -w /usr/src/app \
    python:3 \
    "$@"
}
