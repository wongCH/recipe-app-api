FROM python:3.9-alpine3.13 AS build-env
#FROM public.ecr.aws/docker/library/python:3.9-alpine3.13


LABEL maintainer="wong.hun@gmail.com"
ENV PYTHONUNBUFFERED 1

COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app app

WORKDIR /app
#EXPOSE 8000

ARG DEV=false
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
   rm -rf /tmp && \
   apk del .tmp-build-deps && \
   adduser \
        --disabled-password \
        --no-create-home \
        django-user

 
    
ENV PATH="/py/bin:$PATH"

#USER django-user


FROM gcr.io/distroless/python3-debian9
COPY --from=build-env /app /app
 
COPY --from=build-env /usr/bin/libreoffice/ /usr/bin/
COPY --from=build-env /usr/share/libreoffice /usr/share/
COPY --from=build-env /usr/bin/unoconv /usr/bin/
COPY --from=build-env /etc/libreoffice /etc/
COPY --from=build-env /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
RUN sed -i 's|#!/usr/bin/env python3|#!/usr/bin/python3|' /usr/bin/unoconv

WORKDIR /app

RUN python -m venv /py && \
    adduser \
      --disabled-password \
      --no-create-home \
      django-user



ENV PYTHONPATH=/usr/local/lib/python3.9/site-packages
EXPOSE 8000 

#USER django-user