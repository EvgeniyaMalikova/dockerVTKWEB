FROM  nvidia/opengl:1.2-glvnd-devel-ubuntu20.04

ARG DEBIAN_FRONTEND=noninteractive
MAINTAINER Evgeniya Malikova <evgeniya.malikova@port.ac.uk>

ENV NVIDIA_VISIBLE_DEVICES=all NVIDIA_DRIVER_CAPABILITIES=all

RUN ldconfig -v | grep nvidia || true

RUN apt-get update

RUN apt-get install -y build-essential
RUN apt-get install -qq cmake 
RUN apt-get install -y git

RUN apt install -y libssl-dev libffi-dev python3-dev
RUN python3 --version

RUN mkdir -p /opt/{src,bin}
WORKDIR /opt/src

RUN git clone https://github.com/Kitware/VTK.git  --branch v9.0.1
WORKDIR /opt/src/VTK
RUN mkdir build
WORKDIR /opt/src/VTK/build
RUN mkdir /data
RUN mkdir /data/pv
RUN mkdir /data/pv/pv-5.9
RUN apt-get install -y ninja-build

RUN cmake cmake -GNinja -DCMAKE_BUILD_TYPE=Release  -DVTK_PYTHON_VERSION=3  -DCMAKE_INSTALL_PREFIX=/data/pv/pv-5.9 -DVTK_GROUP_ENABLE_Web=YES  -DVTK_WRAP_PYTHON=ON -DPython3_EXECUTABLE=/usr/bin/python3.8 -DVTK_GROUP_ENABLE_Qt=NO  -DPython3_INCLUDE_DIR=/usr/include/python3.8  -DVTK_MODULE_ENABLE_VTK_WebCore=YES -DVTK_MODULE_ENABLE_VTK_WebGLExporter=YES DVTK_MODULE_ENABLE_VTK_WebPython  =YES -DVTK_MODULE_ENABLE_VTK_CommonPython=YES -DVTK_MODULE_ENABLE_VTK_FiltersPython=YES  -DVTK_OPENGL_HAS_EGL:BOOL=ON -DVTK_USE_X=NO -DVTK_MODULE_ENABLE_VTK_WebPython=YES -DVTK_DEFAULT_RENDER_WINDOW_HEADLESS:BOOL=ON -DVTK_BUILD_TESTING=OFF -DVTK_BUILD_DOCUMENTATION=OFF -DVTK_BUILD_EXAMPLES=OFF  ../
RUN ninja install 



ENV PATH=/data/pv/pv-5.9/bin:$PATH
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/pv/pv-5.9/lib

CMD echo "VTK egl was build"

ENV SYSTEM_PYTHON_3_PIP pip3
ENV SYSTEM_PYTHON_PIP "SYSTEM_PYTHON_${PYTHON_VERSION}_PIP"

RUN apt-get -y install python3.8
RUN apt-get -y install python3-pip
RUN apt-get install -y python3-venv

CMD echo "Start building ViaLactea"
USER root

WORKDIR /opt/src

CMD echo "Start building ViaLactea"
RUN git clone https://github.com/NEANIAS-Space/ViaLacteaWeb.git  #--branch dev_test
WORKDIR /opt/src/ViaLacteaWeb/INSTALL/CFITSIO
RUN mkdir build

RUN cd build \
 && cmake ..\
 && make install

CMD echo "CFITSIO was build"

RUN apt-get update && apt-get install -y libcurl4-openssl-dev --fix-missing
WORKDIR /opt/src/ViaLacteaWeb
RUN mkdir build


RUN cd build \
 && cmake -DBUILD_DOC=OFF -DBUILD_PYTHON_WRAPPERS=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/data/pv/pv-5.9 -DVTK_DIR=/data/pv/pv-5.9/lib/cmake/vtk-9.0 -Dcfitsio=/usr/local/lib/libcfitsio.so ../ \
 && make install

CMD echo "VLW  was build"
CMD echo "Setting up pvw-user and all directories"



ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/data/pv/pv-5.9/lib:/usr/local/lib"
ENV PATH="${PATH}:/data/pv/pv-5.9/bin"





# Apache


RUN apt-get update && apt-get install -y --no-install-recommends \
        apache2-dev \
        apache2 \
        libapr1-dev \
        apache2-utils \
        sudo && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd pvw-user && \
    useradd -g pvw-user -d /home/pvw-user pvw-user && \
    mkdir /home/pvw-user && chown -R pvw-user:pvw-user /home/pvw-user
 

RUN mkdir -p /data/pvw /data/logs /data/www
RUN cp -r /opt/src/ViaLacteaWeb/remote/ /data/pv/pv-5.9/share
RUN cp -r /opt/src/ViaLacteaWeb/client/ /data/www 

RUN ln -s /data/pv/pv-5.9 /data/pv/pv-current
RUN chown -R pvw-user:pvw-user /data/pv
RUN chgrp -R pvw-user /data/pv

RUN mkdir -p /data/pvw/bin /data/pvw/conf /data/pvw/data /data/pvw/logs


RUN touch /data/proxy.txt
RUN chown pvw-user /data/proxy.txt
RUN chgrp www-data /data/proxy.txt

RUN chmod 660 /data/proxy.txt




RUN cd /data/pv/pv-5.9 && \
python3.8 -m venv /data/pv/pv-5.9 && \
. /data/pv/pv-5.9/bin/activate

ENV PYTHONPATH="/data/pv/pv-5.9/lib/python3.8/site-packages/"



RUN pip3 install twisted
RUN pip3 install wslink


RUN pip3 install autobahn

# RUN cd /data/pv/pv-5.9/lib/python3.8/site-packages && ls

# Tested
# RUN vtkpython /data/pv/pv-5.9/share/remote/vtkjsserver/vtkjsserver/vtkw-server.py --port 1234

#contents of /data/pvw will be mounted as external volume between apache and vlw containers
#RUN echo "#!/bin/bash" >> /data/pvw/bin/start.sh
#RUN echo "export DISPLAY=:0.0" >> /data/pvw/bin/start.sh
#RUN echo "export PYTHONPATH="/data/pv/pv-5.9/lib64/python3.8/site-packages/"" >> /data/pvw/bin/start.sh
#RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/data/pv/pv-5.9/lib64" >> /data/pvw/bin/start.sh
#RUN echo "export PATH=$PATH:/data/pv/pv-5.9/bin" >> /data/pvw/bin/start.sh
#RUN echo "vtkpython /data/pv/pv-5.9/lib64/python3.8/site-packages/wslink/launcher.py /data/pvw/conf/launcher.json &" >> /data/pvw/bin/start.sh

# Copy the apache configuration file into place
CMD echo "Copying launcher files "

CMD echo "Launcher copied"
COPY config/launcher/launcher.json /data/pvw/conf/launcher.json

COPY config/apache/001-vlw.conf /etc/apache2/sites-available/001-vlw.conf

# Copy the script into place
CMD echo "Copy scripts "
COPY scripts/start.sh /data/pvw/bin/
COPY scripts/addEndpoints.sh /data/pvw/bin/
COPY scripts/server.sh /data/pvw/bin

# Configure the apache web server
RUN a2enmod vhost_alias && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    a2enmod proxy_wstunnel && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2dissite 000-default.conf && \
    a2ensite 001-vlw && \
    a2dismod autoindex -f


# Open port 80 to the world outside the container
EXPOSE 80

RUN cp -a /opt/src/ViaLacteaWeb/client/. /data/www/

RUN cp -a /opt/src/ViaLacteaWeb/remote/vtkjsserver/vtkjsserver/. /data/pv/pv-5.9/share/vtkjsserver/

RUN mkdir /data/www/logs

RUN chown -R $USER:$USER /data/www
RUN chmod -R 755 /data/www

# Start the container.  If we're not running this container, but rather are
# building other containers based on it, this entry point can/should be
# overridden in the child container.  In that case, use the "start.sh"
# script instead, or you can provide a custom one.
#ENTRYPOINT ["/data/pvw/bin/server.sh"]

#USER pvw-user


CMD echo "Run tests"

WORKDIR /opt/src/ViaLacteaWeb/build/bin
RUN ls


#CMD /bin/sh
#ENTRYPOINT ["/data/pvw/bin/start.sh"]

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2



ENV APACHE_RUN_DIR /var/lib/apache/runtime
RUN mkdir -p ${APACHE_RUN_DIR}


COPY scripts/init.sh /data/pvw/bin
#COPY scripts/start.sh /data/pvw/bin
CMD echo "Copy client"
ADD client /data/www/

EXPOSE 9020
EXPOSE 9019
EXPOSE 9000 9001 9002 9003 9004 9005 9006 9007 9008
EXPOSE 1234

#USER pvw-user

RUN mkdir /home/pvw-user/files

ENTRYPOINT sh /data/pvw/bin/init.sh
#ENTRYPOINT /data/pvw/bin/init.sh
#ENTRYPOINT ["/usr/sbin/apache2"]
#CMD ["-D", "FOREGROUND"]
#COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#EXPOSE 8000 
#CMD ["/usr/bin/supervisord"]
#CMD sh /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND
