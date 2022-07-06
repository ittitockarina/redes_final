FROM ubuntu:22.04

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt install -y nano
RUN apt install -y iproute2
RUN apt install -y ifupdown
RUN apt install -y net-tools
RUN apt install -y curl
RUN apt install -y openssh-client