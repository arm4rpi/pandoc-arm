all: build

build:
	drone exec --trusted --secret-file /tmp/pandoc-arm-secret.txt 
