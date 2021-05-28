# How to I build the WireMock docker image?

Clone this repository by running:  
```
https://github.com/muellerc/wiremock-docker.git
```

and navivate to the root directory of this project:  
```
cd wiremock-docker
```

Make sure you have Docker installed and run:  
```
docker build -t wiremock .
```

# How to I use the WireMock docker image?

After you have built the image, you can run it by executing:  
``
docker run --rm -it -p 8080:8080 wiremock
``

By default, WireMock will listen on port 8080 for HTTP requests. You can test it, by browsing to the admin page, located at [http://localhost:8080/__admin/](http://localhost:8080/__admin/).  

You can than configure WireMock with posting REST requests as described [here](http://wiremock.org/docs/running-standalone/) or by recording your requests as described [here](http://wiremock.org/docs/record-playback/).  

If you already have a set of WireMock mappings and files, you can add them to the `wiremock-root-directory` (or any other directory), and mount this directory to your docker container as following (make sure the mount target matches the option you provide to `--root-dir`):  

``
docker run --rm -it -p 8080:8080 --mount src="$(pwd)/wiremock-root-dir",target=/wiremock-root-dir,type=bind wiremock -jar wiremock.jar --root-dir /wiremock-root-dir --verbose
``

# Interested in an advanced example with mTLS?

First, run:  

```
./create_keystore_and_truststore.sh
```

to create the necessary certificate authority (CA) certificates and keys, a server (WireMock) key- and truststore, a client (App or curl) key- and truststore as well the client key and certificate. These files will be created in the `certificates` subdirectory.  

Afterwards, run the following command in the root folder of this project to start your WireMock docker container with the necessary parameters to enforce HTTPS and mTLS:  

```
docker run --rm -it -p 8443:8443 --mount src="$(pwd)/wiremock-root-dir",target=/wiremock-root-dir,type=bind wiremock -jar wiremock.jar --disable-http --https-port 8443 --https-keystore /wiremock-root-dir/server_keystore.jks --keystore-type PKCS12 --keystore-password changeit --key-manager-password changeit --https-truststore /wiremock-root-dir/server_truststore.jks --truststore-type PKCS12 --truststore-password changeit --https-require-client-cert --root-dir /wiremock-root-dir --verbose
```

Now you can access WireMock for example through curl:  

```
curl -i --cacert certificates/ca.crt --cert certificates/client.crt --key certificates/client.key https://localhost:8443/status
```

You should now see a similar result like this:  

```
curl -i --cacert certificates/ca.crt --cert certificates/client.crt --key certificates/client.key https://localhost:8443/status
HTTP/1.1 200 OK
Content-Type: application/json
Matched-Stub-Id: 76da8616-8aa0-41d1-bdb8-17c32310fc55
Vary: Accept-Encoding, User-Agent
Transfer-Encoding: chunked

{"status":"ok"}
```

Congrats, you did it!

To clean up the generated files, just run:  

```
./cleanup_keystore_and_truststore.sh
```