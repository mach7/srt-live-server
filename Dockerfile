# build stage
FROM alpine:latest as build
RUN apk update &&\
    apk upgrade &&\
    apk add --no-cache linux-headers alpine-sdk cmake tcl openssl-dev zlib-dev
WORKDIR /tmp
RUN git clone https://github.com/Edward-Wu/srt-live-server.git
RUN git clone https://github.com/Haivision/srt.git
WORKDIR /tmp/srt
RUN ./configure && make && make install
WORKDIR /tmp/srt-live-server
RUN make

# final stage
FROM alpine:latest
ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64
RUN apk update &&\
    apk upgrade &&\
    apk add --no-cache openssl libstdc++ &&\
    mkdir /etc/sls /logs &&\
    cd /etc/sls &&\
    wget https://raw.githubusercontent.com/mach7/srt-live-server/master/sls.conf &&\
    apk add nano
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib64/libsrt* /usr/local/lib64/
COPY --from=build /tmp/srt-live-server/bin/* /usr/local/bin/
#COPY sls.conf /etc/sls/
VOLUME /logs
EXPOSE 1935/udp
USER root
#WORKDIR /home/srt
ENTRYPOINT [ "sls", "-c", "/etc/sls/sls.conf"]
