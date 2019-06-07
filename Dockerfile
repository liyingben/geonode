FROM python:2.7.16
MAINTAINER GeoNode development team ben

RUN mkdir -p /usr/src/{app,geonode}

WORKDIR /usr/src/app

# This section is borrowed from the official Django image but adds GDAL and others
RUN apt-get update && apt-get install -y \
		gcc \
		gettext \
		postgresql-client libpq-dev \
		sqlite3 \
                python-psycopg2 \
                python-imaging python-lxml \
                python-dev libgdal-dev \
                python-ldap \
                libmemcached-dev libsasl2-dev zlib1g-dev \
                python-pylibmc \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*


COPY wait-for-databases.sh /usr/bin/wait-for-databases
RUN chmod +x /usr/bin/wait-for-databases

# Upgrade pip
RUN pip install --upgrade pip

# To understand the next section (the need for requirements.txt and setup.py)
# Please read: https://packaging.python.org/requirements/

#let's install pygdal wheels compatible with the provided libgdal-dev
RUN gdal-config --version | cut -c 1-5 | xargs -I % pip install 'pygdal>=%.0,<=%.999'

# install shallow clone of geonode master branch
RUN git clone --depth=1 https://github.com/liyingben/geonode --branch master /usr/src/geonode
RUN cd /usr/src/geonode/; pip install --upgrade --no-cache-dir -r requirements.txt; pip install --upgrade -e .


RUN cp /usr/src/geonode/tasks.py /usr/src/app/
RUN cp /usr/src/geonode/entrypoint.sh /usr/src/app/

RUN chmod +x /usr/src/app/tasks.py \
    && chmod +x /usr/src/app/entrypoint.sh


# use latest master
RUN cd /usr/src/geonode/; git pull ; pip install --upgrade --no-cache-dir -r requirements.txt; pip install --upgrade -e .
COPY . /usr/src/app
RUN pip install --upgrade --no-cache-dir -r /usr/src/app/requirements.txt
RUN pip install -e /usr/src/app --upgrade

COPY requirements.txt /usr/src/app/
RUN pip install --upgrade pip
RUN pip install -r requirements.txt --upgrade
RUN python manage.py makemigrations --settings=geonode.settings
RUN python manage.py migrate --settings=geonode.settings

EXPOSE 8000

# CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
# CMD ["paver", "start_django", "-b", "0.0.0.0:8000"]
# CMD ["uwsgi", "--ini", "uwsgi.ini"]
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
