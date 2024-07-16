.DEFAULT_GOAL := .aws-sam

.PHONY: invoke
invoke: .aws-sam
	sam local invoke HelloWorldFunction

build:
	docker compose build
	docker compose run --rm build-psycopg2

./psycopg2-layer/python: build
	mkdir -p ./psycopg2-layer/python
	cp -r ./build/psycopg2 ./psycopg2-layer/python

./psycopg2-layer/lib: build
	mkdir -p ./psycopg2-layer/lib
	cp -r ./build/postgresql/lib/libpq.* ./psycopg2-layer/lib

.aws-sam: ./psycopg2-layer/python ./psycopg2-layer/lib
	sam build --use-container

.PHONY: clean
clean:
	sudo rm -rf ./build
	sudo rm -rf ./psycopg2-layer/python
	sudo rm -rf ./psycopg2-layer/lib
	sudo rm -rf .aws-sam
