#!/bin/bash

set -e

COMPOSE_FILE="compose.yaml"

echo "---" >"$COMPOSE_FILE"
echo "services:" >>"$COMPOSE_FILE"

for dockerfile in $(find . -maxdepth 1 -name 'Dockerfile.*' -type f | sort -V); do
  if [[ -f "$dockerfile" ]]; then
    # Extract browser type and version from filename
    # Format: Dockerfile.{browser}_{version}
    filename=$(basename "$dockerfile")
    browser_version="${filename#Dockerfile.}"
    browser_type="${browser_version%%_*}"
    version="${browser_version#*_}"

    # Extract major version for service name (e.g., 104 from 104.0.5112.102)
    major_version="${version%%.*}"

    # Generate service name (e.g., chrome-81, firefox-144)
    service_name="${browser_type}-${major_version}"

    # Generate image name
    image_name="gitsang/browser-vnc:${browser_type}-${version}"

    # Generate title with capitalized browser name and major version
    title_browser="${browser_type^}"
    title="${title_browser} ${major_version}"

    cat >>"$COMPOSE_FILE" <<EOF
  ${service_name}:
    image: ${image_name}
    container_name: ${service_name}
    restart: unless-stopped
    shm_size: "512mb"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - TITLE=${title}
    volumes:
      - /etc/fonts:/etc/fonts
      - /usr/share/fonts:/usr/share/fonts
      - ./${service_name}:/config
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.to-${service_name}.rule=Host(\`${service_name}.\${DOMAIN}\`)"
      - "traefik.http.routers.to-${service_name}.tls.certResolver=ali_resolver"
      - "traefik.http.routers.to-${service_name}.service=${service_name}"
      - "traefik.http.services.${service_name}.loadBalancer.server.port=3000"

EOF
  fi
done

echo "Generated $COMPOSE_FILE from $(find . -maxdepth 1 -name 'Dockerfile.*' -type f | wc -l) Dockerfile(s)"
