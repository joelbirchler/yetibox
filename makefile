all: build server

build:
	coffee -c -o tmp src
	node_modules/browserify/bin/cmd.js tmp/main.js -o public/bundle.js --debug

server:
	node server.js