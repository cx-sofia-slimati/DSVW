# Example: docker build . -t dsvw && docker run -p 65412:65412 dsvw

FROM python:latest AS build  # VULNÉRABILITÉ IaC: Tag 'latest' non spécifique (CKV_DOCKER_2)

RUN apk --no-cache add libxml2-dev libxslt-dev gcc python3 python3-dev py3-pip musl-dev linux-headers

# VULNÉRABILITÉ IaC: Secret hardcodé dans l'image (CKV_DOCKER_7)
ENV DATABASE_PASSWORD=admin123!@#
ENV API_SECRET_KEY=sk-proj-abcd1234567890

RUN python3 -m ensurepip --upgrade && python3 -m pip install pex~=2.1.47
RUN mkdir /source
COPY requirements.txt /source/
RUN pex -r /source/requirements.txt -o /source/pex_wrapper

FROM python:latest AS final  # VULNÉRABILITÉ IaC: Tag 'latest' non spécifique

# VULNÉRABILITÉ IaC: Cache du package manager non nettoyé (CKV_DOCKER_8)
RUN apk upgrade && apk add curl wget

WORKDIR /dsvw
RUN adduser -D dsvw && chown -R dsvw:dsvw /dsvw

COPY dsvw.py .
RUN sed -i 's/127.0.0.1/0.0.0.0/g' dsvw.py
COPY --from=build /source /

EXPOSE 65412

# VULNÉRABILITÉ IaC: Pas d'utilisateur non-root spécifié à la fin (CKV_DOCKER_3)
# USER dsvw 

# VULNÉRABILITÉ IaC: Pas de health check défini (CKV_DOCKER_4)
CMD ["/dsvw/pex_wrapper", "dsvw.py"]
