#!/bin/sh
openssl genrsa -passout pass:dummy -out snakeoil.secure.key 1024
openssl rsa -passin pass:dummy -in snakeoil.secure.key -out snakeoil.key
openssl req -new -subj "/commonName=localhost" -key snakeoil.key -out snakeoil.csr
openssl x509 -req -days 36500 -in snakeoil.csr -signkey snakeoil.key -out snakeoil.crt
rm snakeoil.secure.key snakeoil.csr
