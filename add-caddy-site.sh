#!/bin/bash

set -e

# Get running container names
containers=($(docker ps --format "{{.Names}}"))
if [ ${#containers[@]} -eq 0 ]; then
  echo "No running containers found."
  exit 1
fi

echo "Select your Caddy container by number:"
select CADDY_CONTAINER in "${containers[@]}"; do
  if [ -n "$CADDY_CONTAINER" ]; then
    echo "Selected: $CADDY_CONTAINER"
    break
  else
    echo "Invalid selection."
  fi
done

read -p "Enter the domain to add (e.g. mysite.local): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "❌ Domain cannot be empty."
  exit 1
fi

read -p "Enter the backend port for this domain (e.g. 8005): " PORT
if [ -z "$PORT" ]; then
  echo "❌ Port cannot be empty."
  exit 1
fi

SITE_BLOCK="${DOMAIN} { reverse_proxy host.docker.internal:${PORT} tls internal }"

echo "Adding the following site block inside the container:"
echo "$SITE_BLOCK"
echo

# Append the site block directly inside the container
docker exec -it "$CADDY_CONTAINER" sh -c "echo '${SITE_BLOCK}' >> /etc/caddy/Caddyfile"
echo "✅ Added site block to /etc/caddy/Caddyfile inside $CADDY_CONTAINER"

echo "Formatting Caddyfile in container..."
docker exec -w /etc/caddy "$CADDY_CONTAINER" caddy fmt --overwrite
echo "✅ Caddyfile formatted in container"

echo "Reloading Caddy config..."
docker exec -w /etc/caddy "$CADDY_CONTAINER" caddy reload
echo "✅ Caddy reloaded"

echo "🎉 Done!"

echo
echo "👉 Don't forget to add '$DOMAIN' to your Windows hosts file (C:\\Windows\\System32\\drivers\\etc\\hosts) like this:"
echo "127.0.0.1 $DOMAIN"