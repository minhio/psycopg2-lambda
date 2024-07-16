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
	cp -r ./build/postgresql/lib/* ./psycopg2-layer/lib

.aws-sam: ./psycopg2-layer/python ./psycopg2-layer/lib
	sam build --use-container

.PHONY: clean
clean:
	rm -rf ./build
	rm -rf ./psycopg2-layer/python
	rm -rf ./psycopg2-layer/lib
	rm -rf .aws-sam
