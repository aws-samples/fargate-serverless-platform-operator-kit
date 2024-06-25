FROM alpine
COPY microenforcer /bin/microenforcer

USER root
RUN ["chmod", "+x", "/bin/microenforcer"]
RUN ["/bin/microenforcer", "aqua-init"]
VOLUME ["/.aquasec"]

# Include the next line to embed an Image Profile
# ADD policy.json /.aquasec/policy/policy.json
# Include the next line to embed a Firewall Policy
# ADD firewall.json /.aquasec/policy/firewall.json

COPY microenforcer /.aquasec/bin/microenforcer

RUN addgroup -g 11433 -S aqua && \
adduser -h /home/aqua -g "aqua user" -s /sbin/nologin -G aqua -S -u 11431 aqua
USER aqua

ENV LD_PRELOAD=/.aquasec/bin/$PLATFORM/slklib.so
ENV AQUA_MICROENFORCER="1"
ENV AQUA_DEBUG_TYPE=STDOUT
LABEL   name="Aqua MicroEnforcer" \
        vendor="Aqua Security Software Ltd." \
        summary="Aqua Security Microenforcer" \
        description="The Aqua Security MicroEnforcer provides runtime protection." \
        com.aquasec.component=microenforcer \
        com.aquasec.baseimage=alpine \
        product=aquasec \
        maintainer="admin@aquasec.com"