# 第一階段：建置
FROM golang:1.21.6-alpine3.19 as build-stage
WORKDIR /go-workdir

# 拷貝原始碼並編譯
COPY assets/earthly/part1/main.go .
RUN go build -o example main.go

# 第二階段：建置 Docker 镜像
FROM alpine:3.19

# 將編譯的產物，從第一階段拷貝至當前镜像
COPY --from=build-stage /go-workdir/example /go-workdir/example

# 設定容器入口點
WORKDIR /go-workdir
ENTRYPOINT ["/go-workdir/example"]
