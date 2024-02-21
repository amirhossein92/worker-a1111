# ---------------------------------------------------------------------------- #
#                         Stage 1: Download the models                         #
# ---------------------------------------------------------------------------- #
FROM alpine/git:2.36.2 as download

COPY builder/clone.sh /clone.sh

# Clone the repos and clean unnecessary files
RUN . /clone.sh taming-transformers https://github.com/CompVis/taming-transformers.git 24268930bf1dce879235a7fddd0b2355b84d7ea6 && \
    rm -rf data assets **/*.ipynb

RUN . /clone.sh stable-diffusion-stability-ai https://github.com/Stability-AI/stablediffusion.git 47b6b607fdd31875c9279cd2f4f16b92e4ea958e && \
    rm -rf assets data/**/*.png data/**/*.jpg data/**/*.gif

RUN . /clone.sh CodeFormer https://github.com/sczhou/CodeFormer.git c5b4593074ba6214284d6acd5f1719b6c5d739af && \
    rm -rf assets inputs

RUN . /clone.sh BLIP https://github.com/salesforce/BLIP.git 48211a1594f1321b00f14c9f7a5b4813144b2fb9 && \
    . /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git 5b3af030dd83e0297272d861c19477735d0317ec && \
    . /clone.sh clip-interrogator https://github.com/pharmapsychotic/clip-interrogator 2486589f24165c8e3b303f84e9dbbea318df83e8 && \
    . /clone.sh generative-models https://github.com/Stability-AI/generative-models 45c443b316737a4ab6e40413d7794a7f5657c19f

# Download Dreamshaper v8 model
RUN apk add --no-cache wget && \
    wget -q -O /model.safetensors https://civitai.com/api/download/models/128713

RUN mkdir /lora && mkdir /Embeddings

# Download Detail Tweaker LoRA (https://civitai.com/models/58390)
RUN apk add --no-cache wget && \
    wget -q -O /lora/add_detail.safetensors https://civitai.com/api/download/models/62833

# Download 3D rendering style LoRA (https://civitai.com/models/73756)
RUN apk add --no-cache wget && \
    wget -q -O /lora/3d_render_style.safetensors https://civitai.com/api/download/models/107366

# Download Anime Line Art LoRA (https://civitai.com/models/16014)
RUN apk add --no-cache wget && \
    wget -q -O /lora/anime_outline.safetensors https://civitai.com/api/download/models/28907

# Download Vector Illustration LoRA (https://civitai.com/models/60132)
RUN apk add --no-cache wget && \
    wget -q -O /lora/vector_illustration.safetensors https://civitai.com/api/download/models/198960

# Download Ink LoRA (https://civitai.com/models/78605)
RUN apk add --no-cache wget && \
    wget -q -O /lora/ink_scenery.safetensors https://civitai.com/api/download/models/83390

# Download Sticker LoRA (https://civitai.com/models/76413)
RUN apk add --no-cache wget && \
    wget -q -O /lora/stickers.safetensors https://civitai.com/api/download/models/81187

# Download Food Photography LoRA (https://civitai.com/models/45322)
RUN apk add --no-cache wget && \
    wget -q -O /lora/food_photography.safetensors https://civitai.com/api/download/models/49946

# Download Oil Brush LoRA (https://civitai.com/models/84542)
RUN apk add --no-cache wget && \
    wget -q -O /lora/oil_brush.safetensors https://civitai.com/api/download/models/94277

# Download Pixel LoRA (https://civitai.com/models/44960)
RUN apk add --no-cache wget && \
    wget -q -O /lora/pixel.safetensors https://civitai.com/api/download/models/52870

# Download Product Design LoRA (https://civitai.com/models/58247)
RUN apk add --no-cache wget && \
    wget -q -O /lora/product_design.safetensors https://civitai.com/api/download/models/62704

# Download Epi Noise Offset LoRA (https://civitai.com/models/13941)
RUN apk add --no-cache wget && \
    wget -q -O /lora/epi_noise_offset.safetensors https://civitai.com/api/download/models/16576?type=Model&format=SafeTensor&size=full&fp=fp16

# Download Better eyes, face and skin LoRA (https://civitai.com/models/51430)
RUN apk add --no-cache wget && \
    wget -q -O /lora/better_eyes_face.safetensors https://civitai.com/api/download/models/55905

# Download Kids Illustration LoRA (https://civitai.com/models/60724)
RUN apk add --no-cache wget && \
    wget -q -O /lora/kids_illustration.safetensors https://civitai.com/api/download/models/67980?type=Model&format=SafeTensor

# Download Dissolve Style LoRA (https://civitai.com/models/245889)
RUN apk add --no-cache wget && \
    wget -q -O /lora/dissolve_style.safetensors https://civitai.com/api/download/models/314246?type=Model&format=SafeTensor
    
# Download Fractal Geometry LoRA (https://civitai.com/models/269592)
RUN apk add --no-cache wget && \
    wget -q -O /lora/fractal_geometry.safetensors https://civitai.com/api/download/models/314363?type=Model&format=SafeTensor

# Download Glitch LoRA (https://civitai.com/models/278650)
RUN apk add --no-cache wget && \
    wget -q -O /lora/glitch.safetensors https://civitai.com/api/download/models/322748?type=Model&format=SafeTensor

# Download Cyberpunk LoRA (https://civitai.com/models/77121)
RUN apk add --no-cache wget && \
    wget -q -O /lora/cyberpunk.safetensors https://civitai.com/api/download/models/81907?type=Model&format=SafeTensor


# Download Easy Negative Embeddings (https://civitai.com/models/7808)
RUN apk add --no-cache wget && \
    wget -q -O /Embeddings/easynegative.safetensors https://civitai.com/api/download/models/9208?type=Model&format=SafeTensor&size=full&fp=fp16

# Download Fast Negative Embeddings (https://civitai.com/models/71961)
RUN apk add --no-cache wget && \
    wget -q -O /Embeddings/FastNegativeV2.pt https://civitai.com/api/download/models/94057?type=Model&format=PickleTensor

# Download Beyond Negative Embeddings (https://civitai.com/models/108821)
RUN apk add --no-cache wget && \
    wget -q -O /Embeddings/Beyondv4-neg.pt https://civitai.com/api/download/models/301684

# Download Civitai Safe Helper Embeddings (https://civitai.com/models/99890)
RUN apk add --no-cache wget && \
    wget -q -O /Embeddings/civit_nsfw.pt https://civitai.com/api/download/models/106916


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
