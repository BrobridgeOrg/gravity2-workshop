VERSION 0.7 # Earthly version to use
FROM golang:1.21.3-alpine3.18
WORKDIR /go-workdir

part1-build:
    COPY assets/earthly/part1/main.go .
    RUN go build -o output/example main.go
    SAVE ARTIFACT output/example AS LOCAL tmp/local-output/go-example

part1-docker:
    COPY +build/example .
    ENTRYPOINT ["/go-workdir/example"]
    SAVE IMAGE go-example:latest

integration-tests-k8s:
    ARG EARTHLY_CI
    # 下面這兩個參數 DOCKER_HUB_USERNAME, DOCKER_HUB_ACCESS_TOKEN
    # 在非 github action runner，例如: 本機, 筆電執行這個 target 時，需要從命令列傳入這兩個參數
    # 可避免 docker hub 匿名 pull image 時，遇到 rate limit 的問題
    # 可用個人的帳號與 access token 來 pull image
    ARG DOCKER_HUB_USERNAME
    ARG DOCKER_HUB_ACCESS_TOKEN
    FROM earthly/dind:alpine-3.18-docker-23.0.6-r4
    # install go 1.21.3 for go test in earthly/dind container
    RUN apk update && apk upgrade --available \
        && apk add --no-cache ca-certificates tzdata curl bash net-tools \
        && wget https://golang.org/dl/go1.21.3.linux-amd64.tar.gz \
        && tar -C /usr/local -xzf go1.21.3.linux-amd64.tar.gz \
        && rm go1.21.3.linux-amd64.tar.gz
    ENV PATH=/usr/local/go/bin:$PATH
    WORKDIR /go-workdir
    RUN mkdir -p /go-workdir
    COPY go.mod go.sum /go-workdir/
    RUN go mod download
    COPY .golangci.yml /go-workdir/
    COPY --dir assets /go-workdir/assets
    COPY --dir scripts /go-workdir/scripts
    COPY --dir tests /go-workdir/tests
    WITH DOCKER
        RUN /go-workdir/xxxx "eth0" "case1" "renew_all" 
    END
