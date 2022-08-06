FROM ubuntu:jammy

COPY setup setup

RUN apt-get update && apt-get install -y sudo

RUN sudo -E /bin/bash setup
