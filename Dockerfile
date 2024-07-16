FROM public.ecr.aws/sam/build-python3.12:1

ARG POSTGRES_VER
ARG PSYCOPG_VER

RUN dnf install -y \
    libicu-devel \
    openssl-devel \
    libpq-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# setuptools isn't installed by default in the 3.12 image for some reason ¯\_(ツ)_/¯
# https://github.com/aws/aws-sam-cli/issues/7176
RUN pip install --upgrade pip \
    && pip install setuptools

ENV PYTHON_VER=3.12
ENV TMP_DIR=/tmp
ENV OUTPUT_DIR=/var/output

ENV POSTGRES_BUILD_DIR=$OUTPUT_DIR/postgresql
ENV PSYCOPG_BUILD_DIR=$OUTPUT_DIR/psycopg2

RUN mkdir -p "$TMP_DIR"

WORKDIR $TMP_DIR

# download postgres
RUN curl -fsSL -o postgresql-${POSTGRES_VER}.tar.gz https://ftp.postgresql.org/pub/source/v${POSTGRES_VER}/postgresql-${POSTGRES_VER}.tar.gz \
    && tar -zxf postgresql-${POSTGRES_VER}.tar.gz

# download psycopg2
RUN curl -fsSL -o psycopg2-${PSYCOPG_VER}.tar.gz https://github.com/psycopg/psycopg2/archive/refs/tags/${PSYCOPG_VER}.tar.gz \
    && tar -zxf psycopg2-${PSYCOPG_VER}.tar.gz

# build postgres
RUN cd postgresql-${POSTGRES_VER} \
    && mkdir -p "$POSTGRES_BUILD_DIR" \
    && ./configure --prefix "$POSTGRES_BUILD_DIR" --without-readline --with-ssl=openssl \
    && make \
    && make install

# build psycopg2
RUN cd psycopg2-${PSYCOPG_VER} \
    && python setup.py build_ext \
    --pg-config=${POSTGRES_BUILD_DIR}/bin/pg_config \
    --static-libpq \
    --libraries=ssl,crypto \
    build

# move psycopg2 build to output dir
RUN mkdir -p "$PSYCOPG_BUILD_DIR" \
    && cp -r psycopg2-${PSYCOPG_VER}/build/lib.linux-x86_64-cpython-$(echo "$PYTHON_VER" | tr -d '.')/psycopg2/* "$PSYCOPG_BUILD_DIR"

WORKDIR "$OUTPUT_DIR"
