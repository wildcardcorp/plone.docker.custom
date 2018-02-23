# be base the image off of the official python 2.7 image -- Plone is working
# towards full 3.x compatibility, is not quite there yet (at the time of this
# writing)
FROM python:2.7-slim

# create a user to run the client instance under -- it should be a system user
# with a home directory created at /plone
RUN useradd --system -m -d /plone plone

# also, create a /data/ directory where we can mount an external volume to
# persist things like the database and uploaded files.
RUN mkdir -p /data/filestorage /data/blobstorage \
    && chown -R plone /data

# install system requirements
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        libxml2 libxslt1.1 libjpeg62 rsync lynx wv libtiff5 libopenjp2-7 \
        poppler-utils wget sudo python-setuptools python-dev build-essential \
        libssl-dev libxml2-dev libxslt1-dev libbz2-dev libjpeg62-turbo-dev \
        libtiff5-dev libopenjp2-7-dev

# tell the docker runtime which folder to use as a default starting point for
# executing commands against
WORKDIR /plone/

# add the buildout.cfg and requirements.txt files to the image
COPY ./requirements.txt /plone/requirements.txt
COPY ./buildout.cfg /plone/buildout.cfg

# install the requirements for buildout
RUN pip install -r /plone/requirements.txt

# and run the buildout -- this will download all the packages, create scripts,
# generate configuration, and, in general, setup the installation
RUN buildout -c /plone/buildout.cfg \
    && chown -R plone /plone /data

# tell the docker runtime that we want to use the USER as the UID to run when
# performing further RUN, CMD, ENTRYPOINT, COPY and ADD instructions
USER plone

# tell the docker runtime that we expect port 8080 to be accessible
EXPOSE 8080

# tell the docker runtime that we expect the /data/ folder to be an external volume
VOLUME /data/

# tell the docker runtime what process we expect to run when a container is started
CMD [ "/plone/bin/instance", "console" ]
