FROM redhat/ubi8 as build

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

RUN rm /etc/yum/pluginconf.d/subscription-manager.conf
COPY subscription-manager.conf /etc/yum/pluginconf.d/
# runtime dependencies
RUN set -eux; \
    yum update ca-certificates \
		tzdata \
	;

ENV PYTHON_VERSION 3.6.8

RUN curl -o python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
	# curl -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"; \
	# GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
	# gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"; \
	# gpg --batch --verify python.tar.xz.asc python.tar.xz; \
	# command -v gpgconf > /dev/null && gpgconf --kill all || :; \
	# rm -rf "$GNUPGHOME" python.tar.xz.asc; \
	mkdir -p /usr/src/python; \
	tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; \
    nproc="$(nproc)"; \
	make -j "$nproc"; \
    make install; \
    rm python.tar.xz; \
    cd /usr/src/python

RUN INSTALL_PKGS="gcc gcc-c++ unixODBC unixODBC-devel"; \
    yum -y install python3; \
    yum -y install python3-devel; \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS; \
    rpm -V $INSTALL_PKGS

# RUN yum -y install python3; \
#     yum -y install python3-devel; \
#     yum -y install gcc; \
#     yum -y install gcc-c++; \
#     yum -y install unixODBC; \
#     yum -y install unixODBC-devel
	
RUN python3 --version;
ENV PYTHON_PIP_VERSION 22.3.1
ENV PYTHON_SETUPTOOLS_VERSION 65.5.0
ENV PYTHON_GET_PIP_URL https://bootstrap.pypa.io/get-pip.py
#https://github.com/pypa/get-pip/raw/66030fa03382b4914d4c4d0896961a0bdeeeb274/public/get-pip.py

# Install from our requirements list
COPY requirements.txt .
RUN python3 -m pip download -qr requirements.txt; \
    python3 -m pip install -qr requirements.txt; 

#Install Terradata Client
ADD TeradataToolsAndUtilitiesBase__linux_x8664.17.20.09.00-1.tar.gz /usr/src/terradataClient
RUN cd /usr/src/terradataClient/TeradataToolsAndUtilitiesBase; \
    ./setup.sh a

# WORKDIR /usr/src/terradataClient
# RUN gzip TeradataToolsAndUtilitiesBase__linux_x8664.17.20.09.00-1.tar.gz; \
#     tar --extract --directory /usr/src/terradataClient --strip-components=1 --file TeradataToolsAndUtilitiesBase__linux_x8664.17.20.09.00-1.tar


#Install Perl 

RUN mkdir -p /usr/src/perl; \
    curl -o perl-5.26.3.tar.gz "https://www.cpan.org/src/5.0/perl-5.26.3.tar.gz"; \
    tar --extract --directory /usr/src/perl --strip-components=1 --file perl-5.26.3.tar.gz; \
    nproc="$(nproc)"; \
	make -j "$nproc"; \
    make install; \
    rm perl-5.26.3.tar.gz; \
    cd /usr/src/perl

RUN yum -y install perl

WORKDIR /work
COPY testfile.py .

CMD ["python3", "testfile.py"]

# RUN curl -O get-pip.py "$PYTHON_GET_PIP_URL"; 
    
# RUN python3 get-pip.py; \
# 	rm -f get-pip.py; \
# 	\
# 	pip --version

# make some useful symlinks that are expected to exist ("/usr/local/bin/python" and friends)
# RUN set -eux; \
# 	for src in idle3 pydoc3 python3 python3-config; do \
# 		dst="$(echo "$src" | tr -d 3)"; \
# 		[ -s "/usr/local/bin/$src" ]; \
# 		[ ! -e "/usr/local/bin/$dst" ]; \
# 		ln -svT "$src" "/usr/local/bin/$dst"; \
# 	done

# # if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
# ENV PYTHON_PIP_VERSION 22.3.1
# # https://github.com/docker-library/python/issues/365
# ENV PYTHON_SETUPTOOLS_VERSION 65.5.0
# # https://github.com/pypa/get-pip
# ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/66030fa03382b4914d4c4d0896961a0bdeeeb274/public/get-pip.py
# ENV PYTHON_GET_PIP_SHA256 1e501cf004eac1b7eb1f97266d28f995ae835d30250bec7f8850562703067dc6

# RUN set -eux; \
# 	\
# 	curl -O get-pip.py "$PYTHON_GET_PIP_URL"; \
# 	echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum -c -; \
# 	\
# 	export PYTHONDONTWRITEBYTECODE=1; \
# 	\
# 	python get-pip.py \
# 		--disable-pip-version-check \
# 		--no-cache-dir \
# 		--no-compile \
# 		"pip==$PYTHON_PIP_VERSION" \
# 		"setuptools==$PYTHON_SETUPTOOLS_VERSION" \
# 	; \
# 	rm -f get-pip.py; \
# 	\
# 	pip --version

# CMD ["python3"]