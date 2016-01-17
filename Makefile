#
#  Author: Hari Sekhon
#  Date: 2013-02-03 10:25:36 +0000 (Sun, 03 Feb 2013)
#
#  https://github.com/harisekhon/pytools
#
#  License: see accompanying LICENSE file
#

ifdef TRAVIS
	SUDO2 =
else
	SUDO2 = sudo
endif

# EUID /  UID not exported in Make
# USER not populated in Docker
ifeq '$(shell id -u)' '0'
	SUDO =
	SUDO2 =
else
	SUDO = sudo
endif

.PHONY: build
build:
	if [ -x /usr/bin/apt-get ]; then make apt-packages; fi
	if [ -x /usr/bin/yum ];     then make yum-packages; fi
	
	git submodule init
	git submodule update --remote --recursive
	
	cd pylib && make
	
	# json module built-in to Python >= 2.6, backport not available via pypi
	#$(SUDO2) pip install json
	
	# for impyla
	pip install --upgrade setuptools
	pip install -r requirements.txt
	# for ipython-notebook-pyspark.py
	#$(SUDO2) pip install jinja2
	# HiveServer2
	#$(SUDO2) pip install pyhs2
	# Impala
	#$(SUDO2) pip install impyla
	
	# Python >= 2.7 - won't build on 2.6, handle separately and accept failure
	$(SUDO2) pip install "ipython[notebook]" || :
	@echo
	@echo 'BUILD SUCCESSFUL (pytools)'

.PHONY: apt-packages
apt-packages:
	$(SUDO) apt-get update
	$(SUDO) apt-get install -y build-essential
	# needed to fetch the library submodule at end of build
	$(SUDO) apt-get install -y git
	$(SUDO) apt-get install -y wget
	$(SUDO) apt-get install -y python-dev
	$(SUDO) apt-get install -y python-setuptools
	$(SUDO) apt-get install -y python-pip
	# IPython Notebook fails and leave apt broken
	# The following packages have unmet dependencies:
	#  python-zmq : Depends: libzmq1 but it is not going to be installed
	#  E: Unmet dependencies. Try 'apt-get -f install' with no packages (or specify a solution).
	#$(SUDO) apt-get install -y ipython-notebook || :

.PHONY: yum-packages
yum-packages:
	rpm -q git     || $(SUDO) yum install -y git
	rpm -q wget    || $(SUDO) yum install -y wget
	rpm -q gcc     || $(SUDO) yum install -y gcc
	rpm -q gcc-c++ || $(SUDO) yum install -y gcc-c++
	rpm -q git || $(SUDO) yum install -y git
	# needed to fetch the library submodule and CPAN modules
	# python-pip requires EPEL, so try to get the correct EPEL rpm
	rpm -q epel-release || yum install -y epel-release || { wget -O /tmp/epel.rpm "https://dl.fedoraproject.org/pub/epel/epel-release-latest-`grep -o '[[:digit:]]' /etc/*release | head -n1`.noarch.rpm" && $(SUDO) rpm -ivh /tmp/epel.rpm && rm -f /tmp/epel.rpm; }
	rpm -q python-setuptools || $(SUDO) yum install -y python-setuptools
	rpm -q python-pip        || $(SUDO) yum install -y python-pip
	rpm -q python-devel      || $(SUDO) yum install -y python-devel
	rpm -q ipython-notebook  || $(SUDO) yum install -y ipython-notebook || :
	# needed to build pyhs2
	# libgsasl-devel saslwrapper-devel
	rpm -q cyrus-sasl-devel  || $(SUDO) yum install -y cyrus-sasl-devel

.PHONY: test
test:
	cd pylib && make test
	tests/all.sh

.PHONY: test2
test2:
	cd pylib && make test2
	tests/all.sh

.PHONY: install
install:
	@echo "No installation needed, just add '$(PWD)' to your \$$PATH"

.PHONY: update
update:
	make update2
	make
	make test

.PHONY: update2
update2:
	make update-no-recompile

.PHONY: update-no-recompile
update-no-recompile:
	git pull
	git submodule update --init --remote --recursive

.PHONY: clean
clean:
	@find . -maxdepth 3 -iname '*.pyc' -o -iname '*.jyc' | xargs rm -v
