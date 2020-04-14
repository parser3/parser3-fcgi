###############################################################################
# $ID: Dockerfile, 15 Feb 2019 18:09, Leonid 'n3o' Knyazev $
###############################################################################
FROM alpine:latest

MAINTAINER Leonid Knyazev <leonid@knyazev.me>

RUN apk add --no-cache --virtual .builddeps tar bison gcc g++ linux-headers make mariadb-dev cvs \
    && mkdir -p /src/sql 2>/dev/null && cd /src \
    && echo -ne "\n" | cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project login \
    && cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project get -r release_3_4_5 parser3 \
    && cvs -d :pserver:anonymous@cvs.parser.ru:/parser3project get sql \
    && cd /src/parser3 \
    && sed -i 's/download="wget -c --passive-ftp"/download="wget -c"/' buildall \
    && sed -i 's/CPPFLAGS="-DUSE_LIBC_PRIVATES -DUSE_MMAP -DDONT_ADD_BYTE_AT_END"/CPPFLAGS="-DUSE_LIBC_PRIVATES -DUSE_MMAP -DDONT_ADD_BYTE_AT_END -DNO_GETCONTEXT"/' buildall \
    && sed -Ei 's/(typedef struct _fpstate|struct sigcontext)/\1_/' /usr/include/bits/signal.h \
    && ./buildall --strip --disable-safe-mode \
    && cd /src/sql/mysql && ./configure --prefix=/root/parser3install/bin && make && make install \
    && mv /root/parser3install/bin /usr/local/parser3 \
    && mv /usr/local/parser3/auto.p.dist /usr/local/parser3/auto.p \
    && mv /root/parser3install/share/charsets /usr/local/parser3 \
    && cd / && rm -rf /src/* \
    && apk del .builddeps && rm -f /tmp/*

RUN apk add --no-cache mariadb-connector-c-dev libcurl fcgiwrap libstdc++ libgcc \
    && rm -rf /tmp/* && ln -s "$(ls -1 /usr/lib/libcurl.so.* | head -1 | xargs basename)" /usr/lib/libcurl.so

ENV SCRIPT_FILENAME=/usr/local/parser3/parser3
ENV CGI_PARSER_LOG=/dev/stdout

EXPOSE 9000

USER nobody

CMD ["fcgiwrap", "-f", "-c", "3", "-s", "tcp:0.0.0.0:9000"]
