FROM public.ecr.aws/sam/build-python3.12:1

ARG POSTGRES_VER
ARG PSYCOPG_VER

RUN dnf install -y \
    postgresql-devel \
    libicu-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# setuptools isn't installed by default in the 3.12 image for some reason ¯\_(ツ)_/¯
# https://github.com/aws/aws-sam-cli/issues/7176
RUN pip install --upgrade pip \
    && pip install setuptools

ENV PYTHON_VER=3.12
ENV TMP_DIR=/tmp/psycopg2
ENV OUTPUT_DIR=/var/output

RUN mkdir -p "$TMP_DIR"
RUN mkdir -p "$OUTPUT_DIR"

WORKDIR $TMP_DIR

RUN curl -fsSL -o postgresql-${POSTGRES_VER}.tar.gz https://ftp.postgresql.org/pub/source/v${POSTGRES_VER}/postgresql-${POSTGRES_VER}.tar.gz \
    && tar -zxf postgresql-${POSTGRES_VER}.tar.gz

RUN cd postgresql-${POSTGRES_VER} \
    && ./configure --prefix ${TMP_DIR}/postgresql-${POSTGRES_VER} --without-readline \
    && make \
    && make install

RUN curl -fsSL -o psycopg2-${PSYCOPG_VER}.tar.gz https://github.com/psycopg/psycopg2/archive/refs/tags/${PSYCOPG_VER}.tar.gz \
    && tar -zxf psycopg2-${PSYCOPG_VER}.tar.gz

RUN cd psycopg2-${PSYCOPG_VER} \
    && python setup.py build_ext \
    --pg-config=${TMP_DIR}/postgresql-${POSTGRES_VER}/bin/pg_config \
    --static-libpq \
    build

RUN mkdir -p "$OUTPUT_DIR/psycopg2" \
    && cp -r psycopg2-${PSYCOPG_VER}/build/lib.linux-x86_64-cpython-$(echo "$PYTHON_VER" | tr -d '.')/psycopg2 "$OUTPUT_DIR/psycopg2"

RUN mkdir -p "$OUTPUT_DIR/psycopg2/lib" \
    && cp postgresql-${POSTGRES_VER}/lib/libpq.* "$OUTPUT_DIR/psycopg2/lib"

WORKDIR "$OUTPUT_DIR"