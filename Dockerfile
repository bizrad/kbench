FROM golang:1.17-alpine as build

RUN apk -U add bash git gcc musl-dev docker vim less file curl wget ca-certificates

WORKDIR /build
RUN mkdir -p bin dist
COPY . /build/
#RUN ./scripts/build && ./scripts/validate
RUN source scripts/version &&\
    cd ./metric-exporter &&\
    [ "$(uname)" != "Darwin" ] && LINKFLAGS="-extldflags -static -s" &&\
    CGO_ENABLED=0 go build -ldflags "-X main.VERSION=$VERSION $LINKFLAGS" -o ../bin/metric-exporter &&\
    PACKAGES="$(go list ./...)" &&\
    echo Running: go vet &&\
    go vet ${PACKAGES} &&\
    echo Running: go fmt &&\
    test -z "$(go fmt ${PACKAGES} | tee /dev/stderr)"

FROM ubuntu:20.04

RUN apt update && apt install -y fio bash jq

COPY ./fio/ /fio/
COPY --from=build /build/bin/metric-exporter /usr/local/sbin/
WORKDIR "/fio/"
ENTRYPOINT ["bash", "/fio/run.sh"]
