# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/datascience-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Rahim Khoja <rahim.khoja@ubc.ca>"

# Install Plotly conda packages
RUN conda install "jupyterlab>=3" "ipywidgets>=7.6"
RUN conda install -c conda-forge -c plotly jupyter-dash

# Install jupyter extensions (nbgitpuller, git, jupytext)
RUN pip install git+https://github.com/data-8/nbgitpuller \
  && pip install jupyterlab-git \
  && pip install jupytext --upgrade

RUN jupyter labextension install jupyterlab-plotly \
  && jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget \
  && jupyter labextension install @techrah/text-shortcuts \
  && jupyter serverextension enable --sys-prefix nbgitpuller \
  && jupyter lab build

# nbgitpuller looks in incorrect Jinja2 Directory for Template. Temporary Solution is to Copy the files to the correct location
# https://github.com/jupyterhub/nbgitpuller/issues/235#issuecomment-976170694
RUN cp /opt/conda/lib/python3.9/site-packages/nbgitpuller/templates/* /opt/conda/lib/python3.9/site-packages/notebook/templates/

COPY rm-merge-shortcut.py /tmp/user-settings/\@jupyterlab/shortcuts-extension/shortcuts.jupyterlab-settings

ENV HOME=/home/jovyan
ENV PIPELINE=github-actions
WORKDIR $HOME
