#!/bin/bash
set -euo pipefail

# Generate the certificates directory
echo 'Generate the certificates directory...'
mkdir certificates

# Generate certificate authority (CA) private and public key
echo 'Generate certificate authority (CA) private and public key...'
# https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html
openssl req \
  -new \
  -x509 \
  -nodes \
  -days 365 \
  -subj '/CN=CA/OU=Team/O=Company/L=Seattle/C=US' \
  -keyout certificates/ca.key \
  -out certificates/ca.crt

# Look-up the certificate authority (CA) public certificate content
# https://www.openssl.org/docs/man1.0.2/man1/x509.html
# openssl x509 --in certificates/ca.crt -text --noout

# Generate server (WireMock) keystore
echo 'Generate server (WireMock) keystore...'
keytool -genkeypair \
  -alias server \
  -keyalg RSA \
  -keysize 2048 \
  -keypass changeit \
  -storepass changeit \
  -dname "CN=localhost, OU=Team, O=Company, L=Seattle, C=US" \
  -validity 365 \
  -keystore certificates/server_keystore.jks

# Look-up the server (WireMock) keystore content
# keytool -list -keystore certificates/server_keystore.jks -storepass changeit -v

# Generate client (App) keystore
echo 'Generate client (App) keystore...'
keytool -genkeypair \
  -alias client \
  -keyalg RSA \
  -keysize 2048 \
  -keypass changeit \
  -storepass changeit \
  -dname "CN=Client, OU=C-Team, O=Company, L=Seattle, C=US" \
  -validity 365 \
  -keystore certificates/client_keystore.jks

# Look-up the client (App) keystore content
# keytool -list -keystore certificates/client_keystore.jks -storepass changeit -v


# Generate the server (WireMock) Certificate Signing Request
echo 'Generate the server (WireMock) Certificate Signing Request...'
keytool -certreq \
  -alias server \
  -keypass changeit \
  -storepass changeit \
  -keyalg RSA \
  -file certificates/server.csr \
  -keystore certificates/server_keystore.jks

# Signing the server (WireMock) Certificate Signing Request with the certificate authority (CA) key and certificate
echo 'Signing the server (WireMock) Certificate Signing Request with the certificate authority (CA) key and certificate...'
openssl x509 \
  -req \
  -in certificates/server.csr \
  -CA certificates/ca.crt \
  -CAkey certificates/ca.key \
  -CAcreateserial \
  -days 365 \
  -out certificates/server.crt

# Look-up the server (WireMock) signed certificate content
# https://www.openssl.org/docs/man1.0.2/man1/x509.html
# openssl x509 --in certificates/server.crt -text --noout

# Import the certificate authority (CA) certificate into the server keystore
echo 'Import the certificate authority (CA) certificate into the server keystore...'
keytool -importcert \
  -storepass changeit \
  -file certificates/ca.crt \
  -alias ca \
  -noprompt \
  -keystore certificates/server_keystore.jks

# Import the certificate authority (CA) signed server certificate into the server keystore
echo 'Import the certificate authority (CA) signed server certificate into the server keystore...'
keytool -importcert \
  -storepass changeit \
  -file certificates/server.crt \
  -alias server \
  -noprompt \
  -keystore certificates/server_keystore.jks


# Generate the client (App) Certificate Signing Request
echo 'Generate the client (App) Certificate Signing Request...'
keytool -certreq \
  -alias client \
  -keypass changeit \
  -storepass changeit \
  -keyalg RSA \
  -file certificates/client.csr \
  -keystore certificates/client_keystore.jks

# Signing the client (App) Certificate Signing Request with the certificate authority (CA) key and certificate
echo 'Signing the client (App) Certificate Signing Request with the certificate authority (CA) key and certificate...'
openssl x509 \
  -req \
  -in certificates/client.csr \
  -CA certificates/ca.crt \
  -CAkey certificates/ca.key \
  -CAcreateserial \
  -days 365 \
  -out certificates/client.crt

# Look-up the client (App) signed certificate content
# https://www.openssl.org/docs/man1.0.2/man1/x509.html
# openssl x509 --in client.crt -text --noout

# Import the certificate authority (CA) certificate into the client keystore
echo 'Import the certificate authority (CA) certificate into the client keystore...'
keytool -importcert \
  -storepass changeit \
  -file certificates/ca.crt \
  -alias ca \
  -noprompt \
  -keystore certificates/client_keystore.jks

# Import the certificate authority (CA) signed client certificate into the client keystore
echo 'Import the certificate authority (CA) signed client certificate into the client keystore...'
keytool -importcert \
  -storepass changeit \
  -file certificates/client.crt \
  -alias client \
  -noprompt \
  -keystore certificates/client_keystore.jks


# Export server public certificate from server keystore and import it into the client truststore.
# Client need it to validate server certificate in mTLS.
echo 'Export server public certificate...'
keytool -export \
  -alias server \
  -storepass changeit \
  -file certificates/server.cer \
  -keystore certificates/server_keystore.jks

echo 'Import server public certificate into client truststore...'
keytool -importcert \
  -file certificates/server.cer \
  -alias server \
  -storepass changeit \
  -noprompt \
  -keystore certificates/client_truststore.jks

rm certificates/server.cer

# Export client public certificate from client keystore and import it into the server truststore.
# Server need it to validate client certificate in mTLS.
echo 'Export client public certificate...'
keytool -export \
  -alias client \
  -storepass changeit \
  -file certificates/client.cer \
  -keystore certificates/client_keystore.jks

echo 'Import client public certificate into server truststore...'
keytool -importcert \
  -file certificates/client.cer \
  -alias client \
  -storepass changeit \
  -noprompt \
  -keystore certificates/server_truststore.jks

rm certificates/client.cer

# Copy the server_keystore and server_truststore file into the wiremock-root-dir directory
echo 'Copy the server_keystore and server_truststore file into the wiremock-root-dir directory...'
cp certificates/server_keystore.jks wiremock-root-dir/server_keystore.jks
cp certificates/server_truststore.jks wiremock-root-dir/server_truststore.jks

# Convert client KeyStore to the intermediate pkcs12 format, so that we can convert it into the key format to use it with curl
echo 'Convert client KeyStore to the intermediate pkcs12 format, so that we can convert it into the key format to use it with curl...'
keytool -importkeystore \
  -srckeystore certificates/client_keystore.jks \
  -srcstorepass changeit \
  -destkeystore certificates/client.p12 \
  -deststorepass changeit \
  -srcalias client \
  -srcstoretype jks \
  -deststoretype pkcs12

openssl pkcs12 \
  -in certificates/client.p12 \
  -passin pass:changeit \
  -nocerts \
  -nodes \
  -out certificates/client.key

rm certificates/client.p12