VERSION 0.7 # Earthly version to use
FROM golang:1.21.3-alpine3.18
WORKDIR /go-workdir

RUN apk update && apk upgrade --available \
    && apk add --no-cache ca-certificates tzdata curl bash \
    bash-completion tree wget

deps:
    FROM +base
    RUN curl -sfL https://github.com/golangci/golangci-lint/releases/download/v1.55.1/golangci-lint-1.55.1-linux-amd64.tar.gz | \
            tar zx -C /usr/local/bin/ --strip-components=1 golangci-lint-1.55.1-linux-amd64/golangci-lint && \
        curl -sfL https://github.com/goreleaser/goreleaser/releases/download/v1.22.1/goreleaser_Linux_x86_64.tar.gz | tar -xz -C /usr/local/bin/ && \
        chmod +x /usr/local/bin/goreleaser
    COPY go.mod go.sum ./
    RUN go mod download
    SAVE ARTIFACT go.mod AS LOCAL go.mod
    SAVE ARTIFACT go.sum AS LOCAL go.sum

lint:
    FROM +deps
    COPY .golangci.yml ./
    COPY --dir tests /go-workdir/tests
    RUN golangci-lint --version && \
        golangci-lint run --timeout 5m0s ./...

part1-build:
    FROM +deps
    COPY assets/earthly/part1/main.go .
    RUN go build -o output/example main.go
    SAVE ARTIFACT output/example AS LOCAL tmp/local-output/go-example

part1-docker:
    FROM golang:1.21.3-alpine3.18
    ARG IMAGE_VERSION=dev
    LABEL org.opencontainers.image.source=https://github.com/BrobridgeOrg/gravity2-workshop
    COPY +part1-build/example .
    ENTRYPOINT ["/go-workdir/example"]
    SAVE IMAGE --push ghcr.io/brobridgeorg/gravity2-workshop/go-example:$IMAGE_VERSION

ci-pull-request:
    BUILD +lint
    BUILD +part1-build
    BUILD +part1-docker
    # BUILD +integration-tests-k8s

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
        RUN /go-workdir/tests/integration_test_steps.sh "eth0" "case1" "renew_all" 
    END
### foo comment
