# ---------------------------------------------------------------------------- #
#                         Stage 1: Download the models                         #
# ---------------------------------------------------------------------------- #
FROM alpine/git:2.36.2 as download

COPY builder/clone.sh /clone.sh

# Clone the repos and clean unnecessary files
RUN . /clone.sh taming-transformers https://github.com/CompVis/taming-transformers.git 3ba01b241669f5ade541ce990f7650a3b8f65318 && \
    rm -rf data assets **/*.ipynb

RUN . /clone.sh stable-diffusion-stability-ai https://github.com/Stability-AI/stablediffusion.git cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf && \
    rm -rf assets data/**/*.png data/**/*.jpg data/**/*.gif

RUN . /clone.sh CodeFormer https://github.com/sczhou/CodeFormer.git 4724c90b6b9d5183da383f2bdae6ddf9b0bf045d && \
    rm -rf assets inputs

RUN . /clone.sh BLIP https://github.com/salesforce/BLIP.git 48211a1594f1321b00f14c9f7a5b4813144b2fb9 && \
    . /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git 6ab5146d4a5ef63901326489f31f1d8e7dd36b48 && \
    . /clone.sh clip-interrogator https://github.com/pharmapsychotic/clip-interrogator 2cf03aaf6e704197fd0dae7c7f96aa59cf1b11c9 && \
    . /clone.sh generative-models https://github.com/Stability-AI/generative-models 9d759324e914de6c96dbd1468b3a4a50243c6528

# Download DreamShaper XL (v2 turbo) model
RUN apk add --no-cache wget && \
    wget -q -O /model.safetensors https://civitai.com/api/download/models/333449

RUN mkdir /lora && mkdir /Embeddings

# Download Pixel LoRA (https://civitai.com/models/120096)
RUN apk add --no-cache wget && \
    wget -q -O /lora/pixel_xl.safetensors https://civitai.com/api/download/models/135931

# Download Redmond Logo LoRA (https://civitai.com/models/124609)
RUN apk add --no-cache wget && \
    wget -q -O /lora/redmond_logo_xl.safetensors https://civitai.com/api/download/models/177492

# Download Glass Sculptures LoRA (https://civitai.com/models/11203)
RUN apk add --no-cache wget && \
    wget -q -O /lora/glass_xl.safetensors https://civitai.com/api/download/models/177888

# Download Dissolve Style LoRA (https://civitai.com/models/245889)
RUN apk add --no-cache wget && \
    wget -q -O /lora/dissolve_xl.safetensors https://civitai.com/api/download/models/277389

# Download Paper Cut Style LoRA (https://civitai.com/models/122567)
RUN apk add --no-cache wget && \
    wget -q -O /lora/paper_cut_xl.safetensors https://civitai.com/api/download/models/133503

# Download Tshirt design LoRA (https://civitai.com/models/122567)
RUN apk add --no-cache wget && \
    wget -q -O /lora/tshirt_xl.safetensors https://civitai.com/api/download/models/178022

# Download Easy Negative Embeddings (https://civitai.com/models/7808)
RUN apk add --no-cache wget && \
    wget -q -O /Embeddings/easynegative.safetensors https://civitai.com/api/download/models/9208?type=Model&format=SafeTensor&size=full&fp=fp16

# Download Fast Negative Embeddings (https://civitai.com/models/71961)
RUN apk add --no-cache wget && \
    wget -q -O /Embeddings/FastNegativeV2.pt https://civitai.com/api/download/models/94057?type=Model&format=PickleTensor

# Download Beyond Negative Embeddings (https://civitai.com/models/108821)
RUN apk add --no-cache wget && \
    wget -q -O /Embeddings/Beyondv4-neg.pt https://civitai.com/api/download/models/301684


# ---------------------------------------------------------------------------- #
#                        Stage 3: Build the final image                        #
# ---------------------------------------------------------------------------- #
FROM python:3.10.9-slim as build_final_image

ARG SHA=cf2772fab0af5573da775e7437e6acdca424f26e

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    LD_PRELOAD=libtcmalloc.so \
    ROOT=/stable-diffusion-webui \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN export COMMANDLINE_ARGS="--skip-torch-cuda-test --precision full --no-half"
RUN export TORCH_COMMAND='pip install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/rocm5.6'

RUN apt-get update && \
    apt install -y \
    fonts-dejavu-core rsync git jq moreutils aria2 wget libgoogle-perftools-dev procps libgl1 libglib2.0-0 && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && apt-get clean -y

RUN --mount=type=cache,target=/cache --mount=type=cache,target=/root/.cache/pip \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

RUN --mount=type=cache,target=/root/.cache/pip \
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd stable-diffusion-webui && \
    git reset --hard ${SHA}
#&& \ pip install -r requirements_versions.txt

COPY --from=download /repositories/ ${ROOT}/repositories/
COPY --from=download /model.safetensors /model.safetensors
COPY --from=download /lora ${ROOT}/models/Lora
COPY --from=download /Embeddings ${ROOT}/embeddings
RUN mkdir ${ROOT}/interrogate && cp ${ROOT}/repositories/clip-interrogator/data/* ${ROOT}/interrogate
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r ${ROOT}/repositories/CodeFormer/requirements.txt

# Install Python dependencies (Worker Template)
COPY builder/requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install --upgrade -r /requirements.txt --no-cache-dir && \
    rm /requirements.txt

ADD src .

COPY builder/cache.py /stable-diffusion-webui/cache.py
RUN cd /stable-diffusion-webui && python cache.py --use-cpu=all --ckpt /model.safetensors

# Cleanup section (Worker Template)
RUN apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Set permissions and specify the command to run
RUN chmod +x /start.sh
CMD /start.sh
