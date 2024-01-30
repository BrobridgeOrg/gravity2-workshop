VERSION 0.7 # Earthly version to use
FROM golang:1.21.6-alpine3.19
WORKDIR /go-workdir

build:
    COPY assets/earthly/part1/main.go .
    RUN go build -o output/example main.go
    SAVE ARTIFACT output/example AS LOCAL tmp/local-output/go-example

docker:
    COPY +build/example .
    ENTRYPOINT ["/go-workdir/example"]
    SAVE IMAGE go-example:latest