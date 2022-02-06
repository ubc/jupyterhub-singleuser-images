# Copyright (c) UBC-DSCI Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/r-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Tiffany Timbers <tiffany.timbers@gmail.com>"

# Install R packages on conda-forge
RUN conda install --quiet --yes -c conda-forge \
  r-cowplot=1.1.* \
  r-ggally=2.1.* \
  r-gridextra=2.3 \
  r-infer=0.5.* \
  r-kknn=1.3.* \
  r-rpostgres=1.3.*

# Install testthat version 2.3
RUN Rscript -e "devtools::install_version('testthat', version = '2.3.2', repos = 'http://cran.us.r-project.org')"

# Install the palmerpenguins dataset
RUN Rscript -e "devtools::install_github('allisonhorst/palmerpenguins@v0.1.0')"

# Install ISLR package for the Credit data set
RUN Rscript -e "install.packages('ISLR', repos='http://cran.us.r-project.org')"

# Install jupyter extensions (nbgitpuller, git, jupytext)
USER root

RUN pip install git+https://github.com/data-8/nbgitpuller \
  && jupyter serverextension enable --sys-prefix nbgitpuller \
  && pip install jupyterlab-git \
  && pip install jupytext --upgrade \
  && jupyter labextension install @techrah/text-shortcuts \
  && jupyter lab build

#RUN useradd -m -s /bin/bash -N -u 9999 jupyter

#USER jupyter

COPY rm-merge-shortcut.py /tmp/user-settings/\@jupyterlab/shortcuts-extension/shortcuts.jupyterlab-settings
# Configure jupyter user
#ENV NB_USER=jupyter \
#ENV NB_USER=root \
#NB_UID=9999
#ENV HOME=/home/$NB_USER
#ENV HOME=/stat-100a-home/$JUPYTERHUB_USER
ENV HOME=/home/jovyan
ENV PIPELINE=github-actions
WORKDIR $HOME
