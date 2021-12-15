#ARG FROM_IMAGE_NAME=nvcr.io/nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
ARG FROM_IMAGE_NAME=nvcr.io/nvidia/cuda:11.4.2-cudnn8-devel-ubuntu20.04
#ARG FROM_IMAGE_NAME=nvcr.io/nvidia/pytorch:21.09-py3
FROM ${FROM_IMAGE_NAME}

# Install dependencies for system configuration logger
RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
        infiniband-diags \
	git \
	vim \
    pciutils && \
    rm -rf /var/lib/apt/lists/*

# Clone MILA benchmarks
WORKDIR /workspace/milabench
COPY . .

# Install dependencies
RUN DEBIAN_FRONTEND="noninteractive" ./scripts/install-apt-packages.sh
RUN ./scripts/install_conda.sh --no-init

ENV PATH=/root/anaconda3/bin:$PATH

RUN conda create -n mlperf --clone base -y

SHELL ["conda", "run", "-n", "mlperf", "/bin/bash", "-c"]
RUN conda install poetry -y
RUN poetry update && poetry install && poe force-cuda11

RUN chmod 755 -R /root
RUN sed -i '11s/.*/if TORCH_MAJOR == 1:/' /root/anaconda3/envs/mlperf/lib/python3.9/site-packages/apex/amp/_amp_state.py

# Configure environment variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
