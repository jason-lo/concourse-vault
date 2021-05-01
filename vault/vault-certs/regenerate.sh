#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cp /etc/ssl/openssl.cnf vault.cnf
cat >> vault.cnf <<ENDLINE
[ vault_ca ]
keyUsage = critical, cRLSign, keyCertSign
basicConstraints = critical, CA:true, pathlen:0
subjectKeyIdentifier = hash
ENDLINE

openssl genrsa -out vault-ca.key 4096

openssl req -new -x509 -key vault-ca.key -days 365 -sha256 -set_serial 1 -config vault.cnf -extensions vault_ca -out vault-ca.crt -subj '/CN=vault-ca/'
openssl x509 -noout -text -in vault-ca.crt
rm vault.cnf

openssl genrsa -out vault.key 4096
openssl req -sha256 -new -key vault.key -out vault.csr -subj '/CN=vault/'
cat > vault.ext <<ENDLINE
[ vault ]
keyUsage = critical, Digital Signature, Key Encipherment, Data Encipherment, Key Agreement
extendedKeyUsage = TLS Web Server Authentication, TLS Web Client Authentication
subjectKeyIdentifier = hash
authorityKeyIdentifier=keyid:always,issuer
subjectAltName = DNS:vault, IP:127.0.0.1
ENDLINE
openssl x509 -req -in vault.csr \
    -CA vault-ca.crt -CAkey vault-ca.key \
    -CAcreateserial \
    -days 730 \
    -extensions vault -extfile vault.ext \
    -out vault.crt
openssl x509 -noout -text -in vault.crt
rm vault.ext

openssl genrsa -out concourse.key 4096
openssl req -sha256 -new -key concourse.key -out concourse.csr -subj '/CN=concourse/'
cat > concourse.ext <<ENDLINE
[ concourse ]
keyUsage = critical, Digital Signature, Key Encipherment, Data Encipherment, Key Agreement
extendedKeyUsage = TLS Web Server Authentication, TLS Web Client Authentication
subjectKeyIdentifier = hash
authorityKeyIdentifier=keyid:always,issuer
ENDLINE
openssl x509 -req -in concourse.csr \
    -CA vault-ca.crt -CAkey vault-ca.key \
    -CAcreateserial \
    -days 365 \
    -extensions concourse -extfile concourse.ext \
    -out concourse.crt
openssl x509 -noout -text -in concourse.crt
rm concourse.ext
