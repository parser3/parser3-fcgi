###############################################################################
# $ID: Dockerfile, 05 Feb 2021 11:41, Leonid 'n3o' Knyazev $
###############################################################################
FROM alpine:latest

RUN apk add --no-cache --virtual .builddeps tar bison gcc g++ linux-headers make mariadb-dev cvs \
	&& mkdir -p /src/sql 2>/dev/null && cd /src \
	&& echo -ne "\n" | cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project login \
	&& cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project get -r release_3_4_6 parser3 \
	&& cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project get sql \
	&& cd /src/parser3 \
	&& ./buildall --strip --disable-safe-mode \
	&& cd /src/sql/mysql && ./configure --prefix=/root/parser3install/bin && make && make install \
	&& mv /root/parser3install/bin /usr/local/parser3 \
	&& cd / && rm -rf /src/* \
	&& apk del .builddeps && rm -f /tmp/*

RUN apk add --no-cache mariadb-connector-c-dev libcurl fcgiwrap libstdc++ libgcc \
	&& rm -rf /tmp/* && ln -s "$(ls -1 /usr/lib/libcurl.so.* | head -1 | xargs basename)" /usr/lib/libcurl.so

ENV SCRIPT_FILENAME=/usr/local/parser3/parser3
ENV CGI_PARSER_LOG=/dev/stdout

EXPOSE 9000

USER nobody

CMD ["fcgiwrap", "-f", "-c", "3", "-s", "tcp:0.0.0.0:9000"]
