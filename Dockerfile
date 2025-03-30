FROM golang:alpine AS builder

WORKDIR /app

COPY . .

RUN GO111MODULE=off go build -o /app/hello /app/hello.go

# STAGE2
FROM alpine
COPY --from=builder /app/hello /usr/local/bin/hello
CMD ["hello"]