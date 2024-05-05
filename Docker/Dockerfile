FROM ubuntu:24.04

#docker run -v /home/fixer/git/GPS-Tracking-Device:/repo -t zigdev:v1
#zig build-exe -target thumb-freestanding -mcpu cortex_m3 --name application.elf --script STM32F103C8Tx_FLASH.ld startup_stm32f103xb.s main.zig

RUN apt update
RUN apt -y install xz-utils 

ARG workdir=work

WORKDIR /${workdir}

#The version of zig to install.  Needs to match the filename from https://ziglang.org/download/
ARG zig=zig-linux-x86_64-0.12.0

#Download and install zig directly from the website
ADD https://ziglang.org/download/0.12.0/${zig}.tar.xz .
RUN tar -xJf zig-linux-x86_64-0.12.0.tar.xz
ENV PATH="${PATH}:/${workdir}/${zig}"
RUN zig version

#Get zig's svd converter and build it
#RUN git clone -depth 1 --recursive git@github.com:ZigEmbeddedGroup/regz.git
#RUN cd regz
#RUN zig build

#Can't ever get away from make
RUN apt -y install make
RUN make -v

#Openocd
RUN apt -y install openocd
RUN openocd --version

#GDB
RUN apt -y install gdb-multiarch
RUN gdb --version

