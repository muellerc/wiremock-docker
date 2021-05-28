#!/bin/bash

# Delete the certificates folder
echo 'Delete the certificates folder...'
rm -rf certificates

# Delete the server_keystore and server_truststore file from the wiremock-root-dir directory...
echo 'Delete the server_keystore and server_truststore file from the wiremock-root-dir directory...'
rm wiremock-root-dir/server_keystore.jks
rm wiremock-root-dir/server_truststore.jks
