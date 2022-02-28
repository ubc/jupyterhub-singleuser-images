# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/datascience-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Rahim Khoja <rahim.khoja@ubc.ca>"

# Update System Packages for SageMath
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dvipng \
    ffmpeg \
    imagemagick \
    texlive \
    tk tk-dev \
    jq && \
    rm -rf /var/lib/apt/lists/*

# Install Conda Packages (Plotly, SageMath)
RUN conda install --quiet --yes -n base -c conda-forge widgetsnbextension && \
    conda create --quiet --yes -n sage -c conda-forge && \
    npm cache clean --force && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/jovyan
RUN conda install "jupyterlab>=3" "ipywidgets>=7.6"
RUN conda install -c conda-forge -c plotly jupyter-dash

# Install jupyter extensions (nbgitpuller, git, jupytext)
RUN pip install git+https://github.com/data-8/nbgitpuller \
  && pip install jupyterlab-git \
  && pip install jupytext --upgrade

# Install sagemath kernel and extensions using conda run:
#   Create jupyter directories if they are missing
#   Add environmental variables to sage kernal using jq
RUN echo ' \
        from sage.repl.ipython_kernel.install import SageKernelSpec; \
        SageKernelSpec.update(prefix=os.environ["CONDA_DIR"]); \
    ' | conda run -n sage sage && \
    echo ' \
        cat $SAGE_ROOT/etc/conda/activate.d/sage-activate.sh | \
            grep -Po '"'"'(?<=^export )[A-Z_]+(?=)'"'"' | \
            jq --raw-input '"'"'.'"'"' | jq -s '"'"'.'"'"' | \
            jq --argfile kernel $SAGE_LOCAL/share/jupyter/kernels/sagemath/kernel.json \
            '"'"'. | map(. as $k | env | .[$k] as $v | {($k):$v}) | add as $vars | $kernel | .env= $vars'"'"' > \
            $CONDA_DIR/share/jupyter/kernels/sagemath/kernel.json \
    ' | conda run -n sage sh && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/jovyan

# Install sage's python kernel
RUN echo ' \
        ls /opt/conda/envs/sage/share/jupyter/kernels/ | \
            grep -Po '"'"'python\d'"'"' | \
            xargs -I % sh -c '"'"' \
                cd $SAGE_LOCAL/share/jupyter/kernels/% && \
                cat kernel.json | \
                    jq '"'"'"'"'"'"'"'"' . | .display_name = .display_name + " (sage)" '"'"'"'"'"'"'"'"' > \
                    kernel.json.modified && \
                mv -f kernel.json.modified kernel.json && \
                ln  -s $SAGE_LOCAL/share/jupyter/kernels/% $CONDA_DIR/share/jupyter/kernels/%_sage \
            '"'"' \
    ' | conda run -n sage sh && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/jovyan

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
