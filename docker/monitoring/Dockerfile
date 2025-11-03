# Dockerfile pentru imaginea scriptului de monitorizare bash.
#FROM alpine:3.19

# Instalăm utilitarele necesare
#RUN apk add --no-cache bash procps iproute2 lm-sensors coreutils

#WORKDIR /app
#COPY scripts/monitoring.sh /monitoing.sh

#ENV MONITORING_INTERVAL=5

#CMD ["bash", "monitoring.sh"]

FROM alpine:latest

# Instalăm utilitare necesare
RUN apk add --no-cache bash procps iproute2 lm-sensors coreutils

# Copiem scriptul de monitorizare
COPY scripts/monitoring.sh /monitoring.sh
RUN chmod +x /monitoring.sh

VOLUME ["/scripts"]
ENV MONITORING_INTERVAL=5

CMD ["bash", "/monitoring.sh"]