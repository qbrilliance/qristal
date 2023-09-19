ARG SDK_CI_IMAGE=0
ARG QBSDK_PRESET=public


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - stage 1: build - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# the image used to build the SDK for export to a clean image
# this stage builds and minimally tests the qbsdk.
FROM $SDK_CI_IMAGE AS build

USER root
SHELL ["/bin/bash", "-c"]

# select specific commits of our projects
ARG QBSDK_TAG=main
ARG CORE_TAG=main
ARG DECODER_TAG=main 
ARG INTEGRATIONS_TAG=main
# public or dev
ARG QBSDK_PRESET

# The token will be visible in the layers as ARG and RUN: therefore we use multi-stage build and just copy the artifacts into a fresh image
ARG GIT_TOKEN
RUN git config --global url.https://gitlab-ci-token:${GIT_TOKEN}@gitlab.com/.insteadOf https://gitlab.com/
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/nvidia/cuquantum/lib"

# Clone latest SDK
WORKDIR $QB_DIR
RUN git clone https://gitlab-ci-token:${GIT_TOKEN}@gitlab.com/qbau/software-and-apps/QBSDK.git qristal \
    && cd qristal \
    && git fetch origin \
    && git checkout ${QBSDK_TAG} \
    && cmake -S . -B build --preset $QBSDK_PRESET -DCORE_TAG=${CORE_TAG} -DDECODER_TAG=${DECODER_TAG} -DINTEGRATIONS_TAG=${INTEGRATIONS_TAG} -DINSTALL_MISSING=ON -DCMAKE_BUILD_TYPE=None -DWARNINGS=OFF -DWITH_TKET=ON -DTKET_DIR=${QB_DIR}/tket-local -DCMAKE_INSTALL_PREFIX=${QB_DIR}/qristal \
    && cmake --build build -- -j$(nproc) \
    && cmake --install build 

# Unset the token so the user doesn't need to do it themself.
RUN git config --global --unset url.https://gitlab-ci-token:${GIT_TOKEN}@gitlab.com/.insteadOf

# Set up the Jupyter Lab entrypoint
RUN python3 -m pip install jupyterlab \
    && echo '#!/bin/bash' > /qristal_entrypoint.sh\
    && echo 'jupyter lab --allow-root --no-browser --notebook-dir=$QB_DIR/qristal/examples/python --ip=0.0.0.0 --port=8889 --IdentityProvider.token="" --ServerApp.terminado_settings shell_command=/bin/bash --IPKernelApp.pylab="inline" &' >> /qristal_entrypoint.sh \
    && echo '/opt/nvidia/nvidia_entrypoint.sh $@' >> /qristal_entrypoint.sh \
    && chmod +rx /qristal_entrypoint.sh

# test CUDA Quantum example
RUN cd $QB_DIR/qristal/examples/cpp/benchmark1_cudaq \
    && cmake -S . -B build \
    && cmake --build build \
    && ./build/benchmark1_cudaq \
    && echo "C++ CUDA Quantum test successful!" \
    && rm -rf build

# test basic noise model functionality
RUN python3 $QB_DIR/qristal/examples/python/noise_model.py \
    && echo "Python test successful!"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - stage 2: deploy - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# This stage builds the deploy image: it only contains the install of the QBSDK and no git token.
FROM $SDK_CI_IMAGE AS deploy
USER root
SHELL ["/bin/bash", "-c"]

ENV LD_LIBRARY_PATH="/opt/nvidia/cuquantum/lib:$QB_DIR/qristal/lib:$LD_LIBRARY_PATH"

# copy artifacts from previous stage
COPY --from=build $QB_DIR/qristal $QB_DIR/qristal
COPY --from=build $QB_DIR/venv $QB_DIR/venv
COPY --from=build /qristal_entrypoint.sh /qristal_entrypoint.sh

RUN cd $QB_DIR/qristal \
    && cmake --install build

# re-test basic noise model functionality
RUN python3 $QB_DIR/qristal/examples/python/noise_model.py \
    && echo "Python test successful!"

WORKDIR $QB_DIR/qristal
ENTRYPOINT ["/qristal_entrypoint.sh"]
