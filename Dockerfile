# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/datascience-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Rahim Khoja <rahim.khoja@ubc.ca>"

# Install Plotly Packages on conda-forge
RUN conda install --quiet --yes -c conda-forge \
  plotly 

# Install jupyter extensions (nbgitpuller, git, jupytext)
USER root

RUN pip install nbgitpuller \
  && jupyter serverextension enable --sys-prefix nbgitpuller \
  && pip install jupyterlab-git \
  && pip install jupytext --upgrade \
  && jupyter labextension install @techrah/text-shortcuts \
  && jupyter lab build

COPY rm-merge-shortcut.py /tmp/user-settings/\@jupyterlab/shortcuts-extension/shortcuts.jupyterlab-settings

RUN jupyter serverextension enable nbgitpuller --sys-prefix

ENV HOME=/home/jovyan
ENV PIPELINE=github-actions
WORKDIR $HOME
