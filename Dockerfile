FROM ubuntu:latest as package_install
MAINTAINER alienbrett648@gmail.com



RUN mkdir /quantlib
WORKDIR /quantlib
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install wget libboost-all-dev gcc build-essential make python3 python3-dev python-is-python3 -y

RUN wget "https://github.com/lballabio/QuantLib/releases/download/QuantLib-v1.24/QuantLib-1.24.tar.gz"
RUN wget "https://github.com/lballabio/QuantLib-SWIG/releases/download/QuantLib-SWIG-v1.24/QuantLib-SWIG-1.24.tar.gz"
RUN tar xvf QuantLib-1.24.tar.gz
RUN tar xvf QuantLib-SWIG-1.24.tar.gz



FROM package_install as build_quantlib

WORKDIR /quantlib/QuantLib-1.24
RUN ./configure --enable-intraday
RUN make -j$(nproc)
RUN make install
RUN ldconfig



FROM build_quantlib as build_quantlib_swig

WORKDIR /quantlib/QuantLib-SWIG-1.24
RUN apt install -y swig
RUN ./configure
# Re-generate bindings
RUN cd Python;python setup.py wrap
# Now build the actual python wrapper
RUN make -j$(nproc) -C Python
RUN make install



FROM build_quantlib_swig as cleanup

WORKDIR /
RUN rm -rf /quantlib
RUN apt uninstall wget gcc build-essential make swig -y; apt autoremove -y
