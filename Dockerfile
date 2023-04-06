###############################################################################
# $ID: Dockerfile, 05 Feb 2021 11:41, Leonid 'n3o' Knyazev $
###############################################################################
FROM alpine:latest

RUN apk update && apk add --no-cache --virtual .builddeps tar bison gcc g++ linux-headers make mariadb-dev tzdata cvs \
	&& mkdir -p /src/sql 2>/dev/null && cd /src \
	&& echo -ne "\n" | cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project login \
	&& cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project get -r release_3_4_6 parser3 \
	&& cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project get sql \
	&& cd /src/parser3 && ./buildall --strip --disable-safe-mode \
	&& cd /src/sql/mysql && ./configure --prefix=/root/parser3install/bin && make && make install \
	&& mv /root/parser3install/bin /usr/local/parser3 \
	&& apk del .builddeps && cd / && rm -rf /src/ && rm -f /tmp/* \
	&& mkdir -p /app/{cgi,www} 2>/dev/null

RUN apk add --no-cache mariadb-connector-c-dev libcurl fcgiwrap libstdc++ libgcc \
	&& rm -rf /tmp/* && ln -s "$(ls -1 /usr/lib/libcurl.so.* | head -1 | xargs basename)" /usr/lib/libcurl.so

RUN apk add --no-cache tzdata && cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime && echo "Europe/Moscow" >  /etc/timezone

ENV CGI_PARSER_LOG=/dev/stdout
ENV SCRIPT_FILENAME=/usr/local/parser3/parser3

USER nobody
EXPOSE 9000
STOPSIGNAL SIGQUIT

CMD ["fcgiwrap", "-f", "-c", "3", "-s", "tcp:0.0.0.0:9000"]
