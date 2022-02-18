ARG BASE_CONTAINER=jupyter/r-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Tiffany Timbers <tiffany.timbers@gmail.com>"

# Install Plotly conda packages
RUN conda install --quiet --yes "jupyterlab>=3" "ipywidgets>=7.6"
RUN conda install --quiet --yes -c conda-forge -c plotly jupyter-dash

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
