docker image build --no-cache -t build-context -f - . <<EOF
FROM busybox
WORKDIR /build-context
COPY . .
CMD find .
EOF

docker run --rm build-context

docker image rm build-context

