# syntax = docker/dockerfile:1
FROM registry.nearbycomputing.com/nbycomp/base/golang:1.24.6-alpine as builder

# install CA certificates to copy into our final image
# these are required to validate TLS connections e.g. to HTTPS servers
RUN apk add -U --no-cache ca-certificates

WORKDIR /workspace

COPY go.mod go.sum ./

# mount the .netrc file which should contain credentials required to access our private repos
# assumes that the docker build command includes --secret id=netrc,src=/path/to/.netrc
RUN	--mount=type=secret,id=netrc,dst=/root/.netrc \
    go mod download

COPY . ./

# RUN --mount=type=cache,sharing=locked,id=gomod,target=/go/pkg/mod/cache \
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o ./app ./cmd/app/

FROM registry.nearbycomputing.com/external/gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/app ./

# copy CA certs
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

USER 65532:65532

ENTRYPOINT ["./app"]
