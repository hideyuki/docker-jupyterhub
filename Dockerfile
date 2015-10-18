FROM ubuntu:14.04
MAINTAINER Hideyuki Takei <takehide22@gmail.com>


########################################
# Jupyter
# https://github.com/jupyter/notebook
########################################

# Not essential, but wise to set the lang
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONIOENCODING UTF-8

# Remove preinstalled copy of python that blocks our ability to install development python.
RUN DEBIAN_FRONTEND=noninteractive apt-get remove -yq \
        python3-minimal \
        python3.4 \
        python3.4-minimal \
        libpython3-stdlib \
        libpython3.4-stdlib \
        libpython3.4-minimal

# Python binary and source dependencies
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        language-pack-en \
        libcurl4-openssl-dev \
        libffi-dev \
        libsqlite3-dev \
        libzmq3-dev \
        pandoc \
        python \
        python3 \
        python-dev \
        python3-dev \
        sqlite3 \
        texlive-fonts-recommended \
        texlive-latex-base \
        texlive-latex-extra \
        zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Tini
RUN curl -L https://github.com/krallin/tini/releases/download/v0.6.0/tini > tini && \
    echo "d5ed732199c36a1189320e6c4859f0169e950692f451c03e7854243b95f4234b *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Install the recent pip release
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python2 get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py && \
    pip2 --no-cache-dir install requests[security] && \
    pip3 --no-cache-dir install requests[security]

# Install some dependencies.
RUN pip2 --no-cache-dir install ipykernel && \
    pip3 --no-cache-dir install ipykernel && \
    \
    python2 -m ipykernel.kernelspec && \
    python3 -m ipykernel.kernelspec


# Install libs for PlugAir analytics
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        libmysqlclient-dev \
        python-matplotlib \
        libjpeg8-dev libfreetype6-dev libpng12-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN pip2 --no-cache-dir install mysqlclient PyMySQL ipython-sql pandas matplotlib elasticsearch six qtconsole spyder
RUN pip3 --no-cache-dir install mysqlclient PyMySQL ipython-sql pandas matplotlib elasticsearch six qtconsole spyder

# Install libs for scipy numpy
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        libblas-dev liblapack-dev libatlas-base-dev gfortran && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN pip2 --no-cache-dir install scipy numpy seaborn
RUN pip3 --no-cache-dir install scipy numpy seaborn

# Move notebook contents into place.
RUN git clone https://github.com/jupyter/notebook.git /usr/src/jupyter-notebook

# Install dependencies and run tests.
RUN BUILD_DEPS="nodejs-legacy npm" && \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq $BUILD_DEPS && \
    \
    pip3 install --no-cache-dir --pre -e /usr/src/jupyter-notebook && \
    \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Run tests.
#RUN pip2 install --no-cache-dir mock nose requests testpath && \
#    pip3 install --no-cache-dir nose requests testpath && \
#    \
#    iptest2 && iptest3 && \
#    \
#    pip2 uninstall -y funcsigs mock nose pbr requests six testpath && \
#    pip3 uninstall -y nose requests testpath

# Add a notebook profile.
RUN mkdir /root/.jupyter/
#ADD config/jupyter_notebook_config.py /root/.jupyter/
RUN mkdir /root/.config/matplotlib
ADD config/matplotlibrc /root/.config/matplotlib/

# Add font
ADD fonts/ipaexg.ttf /usr/local/share/fonts/


#########################################
# Jupyterhub
# https://github.com/jupyter/jupyterhub
#########################################

# install js dependencies
RUN npm install -g configurable-http-proxy
RUN mkdir -p /srv/

# install jupyterhub
ADD requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

RUN git clone https://github.com/jupyter/jupyterhub.git /srv/jupyterhub
WORKDIR /srv/jupyterhub/
RUN pip3 install .

ONBUILD ADD config/jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py

EXPOSE 8000

ENTRYPOINT ["tini", "--"]
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]

