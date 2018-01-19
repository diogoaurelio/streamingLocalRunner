FROM lambci/lambda:build-java8

MAINTAINER Diogo Aurelio "diogo.piresaurelio"

RUN mkdir -p /tmp
ADD entrypoint.sh /tmp/entrypoint.sh
RUN ls /var/task/
RUN chmod +x /tmp/entrypoint.sh



CMD ["/tmp/entrypoint.sh"]