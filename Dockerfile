FROM debian:stable
RUN apt-get -y update
RUN apt-get -y install wget bzip2 gcc g++ gettext make pkg-config ksh unzip

RUN mkdir /cache

# build mono
WORKDIR /cache
ADD mono-3.10.0.tar.bz2.sha1 /cache/mono-3.10.0.tar.bz2.sha1
RUN wget http://download.mono-project.com/sources/mono/mono-3.10.0.tar.bz2
RUN sha1sum -c mono-3.10.0.tar.bz2.sha1
RUN tar xvf mono-3.10.0.tar.bz2 -C /cache
WORKDIR /cache/mono-3.10.0
RUN ./configure
RUN make && make install
ADD etc-mono-config /usr/local/etc/mono/config

# build fastcgi server
WORKDIR /cache
ADD xsp-2.10.2.tar.bz2.sha1 /cache/xsp-2.10.2.tar.bz2.sha1
RUN wget http://download.mono-project.com/sources/xsp/xsp-2.10.2.tar.bz2
RUN sha1sum -c xsp-2.10.2.tar.bz2.sha1
RUN tar xvf xsp-2.10.2.tar.bz2 -C /cache
WORKDIR /cache/xsp-2.10.2
RUN ./configure && make && make install

# set up data server client
WORKDIR /cache
ADD ibm_data_server_driver_package_linuxx64_v10.5.tar.gz /opt/ibm
RUN /opt/ibm/dsdriver/installDSDriver
ADD db2dsdriver.cfg /opt/ibm/dsdriver/cfg/db2dsdriver.cfg

# download application
WORKDIR /cache
RUN wget https://github.com/jeffbonhag/myapp/archive/master.zip
RUN unzip master.zip
WORKDIR /cache/myapp-master
ADD app.config /cache/myapp-master/MyApp/app.config

# restore nuget packages
RUN wget -P /usr/local/bin http://nuget.org/nuget.exe
RUN mozroots --import --machine --sync
RUN /usr/local/bin/mono /usr/local/bin/nuget.exe restore MyApp.sln

# build and install
RUN xbuild
RUN mkdir /app
RUN mv /cache/myapp-master/MyApp/bin/Debug/* /app

# clean cache
RUN rm -fr /cache

CMD ["/usr/local/bin/mono", "/app/MyApp.exe"]

