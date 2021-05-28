FROM amazoncorretto:11

USER 0

RUN yum install -y wget
RUN wget -O wiremock.jar https://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-jre8-standalone/2.28.0/wiremock-jre8-standalone-2.28.0.jar

ENTRYPOINT ["java"]
CMD ["-jar", "wiremock.jar"]