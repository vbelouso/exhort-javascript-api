ARG JAVA_MINOR_PATCH_VERSION=0.2

# first stage
FROM registry.access.redhat.com/ubi9/nodejs-18 as builder

# use privilaged user
USER root

# assign token for reading packages from github package registry
ARG PACKAGE_REGISTRY_ACCESS_TOKEN=''

ARG JAVA_MINOR_PATCH_VERSION

# install Java
RUN curl -kL https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz -o /tmp/java-package.tar.gz \
    && tar xvzf /tmp/java-package.tar.gz -C /usr/

# install Maven package manager
RUN curl -kL https://dlcdn.apache.org/maven/maven-3/3.9.4/binaries/apache-maven-3.9.4-bin.tar.gz -o /tmp/maven-package.tar.gz \
    && tar xvzf /tmp/maven-package.tar.gz -C /usr/

# install golang package manager
RUN curl -kL https://go.dev/dl/go1.21.1.linux-amd64.tar.gz -o /tmp/golang-package.tar.gz \
    && tar xvzf /tmp/golang-package.tar.gz -C /usr/

# install python package manager (pip)
RUN python3 -m ensurepip --upgrade

# install jq JSON formating tool
RUN curl -kL https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 -o /usr/bin/jq

# install linux utils Package to enable UUID generation
RUN yum install util-linux

# copy the .npmrc file
COPY configs/.npmrc .
# replace placeholder with the actual environment variable
RUN sed -i "s/__PACKAGE_REGISTRY_ACCESS_TOKEN__/${PACKAGE_REGISTRY_ACCESS_TOKEN}/g" ./.npmrc
# install Exhort javascript API
RUN npm install --global @RHEcosystemAppEng/exhort-javascript-api

# add RHDA script
COPY scripts/rhda.sh /

ENV JDK_VERSION=jdk-21.${JAVA_MINOR_PATCH_VERSION}
# assign executable permissions to all installed binaries
RUN chmod +x /usr/${JDK_VERSION} \
    && chmod +x /usr/apache-maven-3.9.4/bin/mvn \
    && chmod +x /usr/go/bin/go \
    && chmod +x /usr/local/bin/pip3 \
    && chmod +x /usr/bin/jq \
    && chmod +x /usr/bin/uuidgen \
    && chmod +x /opt/app-root/src/.npm-global/bin/exhort-javascript-api \
    && chmod +x /rhda.sh

# use default user
USER default

# second stage
FROM registry.access.redhat.com/ubi9/nodejs-18-minimal

LABEL org.opencontainers.image.source https://github.com/RHEcosystemAppEng/exhort-javascript-api

ARG JAVA_MINOR_PATCH_VERSION

# assign token for exhort authentication with Snyk provider
ENV EXHORT_SNYK_TOKEN=''
# assign rhda token for rhda user authentication with exhort
ENV RHDA_TOKEN=''
# assign rhda source for exhort tracking purposes
ENV RHDA_SOURCE=''

ENV JDK_VERSION=jdk-21.${JAVA_MINOR_PATCH_VERSION}

USER root
# Copy java executable from the builder stage
COPY --from=builder /usr/$JDK_VERSION/ /usr/$JDK_VERSION/
ENV JAVA_HOME=/usr/$JDK_VERSION

# Copy maven executable from the builder stage
COPY --from=builder /usr/apache-maven-3.9.4/ /usr/apache-maven-3.9.4/
ENV MAVEN_HOME=/usr/apache-maven-3.9.4

# Copy golang executable from the builder stage
COPY --from=builder /usr/go/ /usr/go/
ENV GOLANG_HOME=/usr/go

# Update PATH
ENV PATH=$PATH:$JAVA_HOME/bin:$MAVEN_HOME/bin:$GOLANG_HOME/bin

# Copy python executable from the builder stage
COPY --from=builder /usr/bin/python3 /usr/bin/python3
COPY --from=builder /usr/local/bin/pip3 /usr/local/bin/pip3
COPY --from=builder /usr/lib64/python3.9 /usr/lib64/python3.9
COPY --from=builder /usr/local/lib/python3.9 /usr/local/lib/python3.9
COPY --from=builder /usr/lib64/libpython3.9.so.1.0 /usr/lib64/libpython3.9.so.1.0
COPY --from=builder /usr/lib64/libexpat.so.1 /usr/lib64/libexpat.so.1

RUN ln -s /usr/bin/python3 /usr/bin/python \
    && ln -s /usr/local/bin/pip3 /usr/bin/pip

# Copy jq executable from the builder stage
COPY --from=builder /usr/bin/jq /usr/bin/jq

# Copy uuidgen executable from the builder stage
COPY --from=builder /usr/bin/uuidgen /usr/bin/uuidgen

# Copy exhort-javascript-api executable from the builder stage
COPY --from=builder /opt/app-root/src/.npm-global/ /opt/app-root/src/.npm-global/

# Copy RHDA executable script from the builder stage
COPY --from=builder /rhda.sh /rhda.sh

#Original UID in base image
USER 1001
