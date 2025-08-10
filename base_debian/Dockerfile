FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN echo '#!/bin/bash\n\
set -e\n\
apt-get update\n\
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"\n\
rm -rf /var/lib/apt/lists/*\n' > /usr/local/bin/install_packages && chmod +x /usr/local/bin/install_packages

CMD [ "bash" ]
