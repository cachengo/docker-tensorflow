FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:openjdk-r/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        cmake \
        curl \
        ffmpeg \
        git \
        libcurl4-openssl-dev \
        libtool \
        libssl-dev \
        mlocate \
        openjdk-8-jdk \
        openjdk-8-jre-headless \
        pkg-config \
        python-dev \
        python-setuptools \
        python-virtualenv \
        python3-dev \
        python3-setuptools \
        python3-pip \
        rsync \
        sudo \
        subversion \
        swig \
        unzip \
        wget \
        zip \
        zlib1g-dev \
        liblapack-dev \
        libopenblas-dev \
        gfortran \
        libhdf5-serial-dev \
    && updatedb \
    && apt-get install -y ca-certificates-java \
    && update-ca-certificates -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt /requirements.txt

RUN pip3 install -r requirements.txt \
    && pip3 install keras_applications==1.0.6 --no-deps \
    && pip3 install keras_preprocessing==1.0.5 --no-deps \
    && pip3 install tensorflow_estimator --no-deps

ENV BAZEL_VERSION=0.15.0

RUN mkdir -p /bazel \
    && cd /bazel \
    && curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-dist.zip \
    && unzip bazel-$BAZEL_VERSION-dist.zip \
    && ./compile.sh \
    && cp output/bazel /usr/local/bin \
    && rm -rf /bazel

ENV PROTOBUF_VERSION="3.6.0"

RUN AARCH=`echo $(uname -m) | sed 's/aarch/aarch_/g'` \
    && PROTOBUF_URL="https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-$AARCH.zip" \
    && PROTOBUF_ZIP=$(basename "${PROTOBUF_URL}") \
    && UNZIP_DEST="google-protobuf" \
    && wget "${PROTOBUF_URL}" \
    && unzip "${PROTOBUF_ZIP}" -d "${UNZIP_DEST}" \
    && cp "${UNZIP_DEST}/bin/protoc" /usr/local/bin/ \
    && rm -f "${PROTOBUF_ZIP}" \
    && rm -rf "${UNZIP_DEST}"

ENV PATH="/usr/local/go/bin:${PATH}"

RUN ARCH=`dpkg --print-architecture` \
    && GOLANG_URL="https://storage.googleapis.com/golang/go1.10.linux-$ARCH.tar.gz" \
    && mkdir -p /usr/local \
    && wget -q -O - "${GOLANG_URL}" | sudo tar -C /usr/local -xz \
    && go get github.com/bazelbuild/buildtools/buildifier

RUN wget https://nixos.org/releases/patchelf/patchelf-0.9/patchelf-0.9.tar.bz2 \
    && tar xfa patchelf-0.9.tar.bz2 \
    && cd patchelf-0.9 \
    && ./configure --prefix=/usr/local \
    && make \
    && make install

# Set up the master bazelrc configuration file.
COPY .bazelrc /etc/bazel.bazelrc

ENV TF_ROOT=/tensorflow
ENV PYTHON_BIN_PATH=/usr/bin/python3
ENV PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
ENV PYTHONPATH=${TF_ROOT}/lib
ENV PYTHON_ARG=${TF_ROOT}/lib
ENV TF_NEED_GCP=0
ENV TF_NEED_CUDA=0
ENV TF_NEED_HDFS=0
ENV TF_NEED_OPENCL=0
ENV TF_NEED_JEMALLOC=0
ENV TF_ENABLE_XLA=0
ENV TF_NEED_VERBS=0
ENV TF_NEED_MKL=0
ENV TF_DOWNLOAD_MKL=0
ENV TF_NEED_AWS=0
ENV TF_NEED_MPI=0
ENV TF_NEED_GDR=0
ENV TF_NEED_S3=0
ENV TF_NEED_OPENCL_SYCL=0
ENV TF_SET_ANDROID_WORKSPACE=0
ENV TF_NEED_COMPUTECPP=0
ENV CC_OPT_FLAGS="-march=native"
ENV TF_SET_ANDROID_WORKSPACE=0
ENV TF_NEED_KAFKA=0
ENV TF_NEED_TENSORRT=0
ENV TF_NEED_AWS=0

RUN git clone https://github.com/tensorflow/tensorflow.git \
    && cd /tensorflow \
    && git checkout v1.12.0-rc1 \
    && sed -i 's/        "-mfpu=neon",//' /tensorflow/tensorflow/contrib/lite/kernels/internal/BUILD \
    && ./configure \
    && bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package \
    && /tensorflow/bazel-bin/tensorflow/tools/pip_package/build_pip_package / \
    && for file in /*.whl; do pip3 install "$file"; done \
    && rm -rf /tensorflow \
    && rm -r /*.whl
