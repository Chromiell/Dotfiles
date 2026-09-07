docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e WATCHTOWER_SCHEDULE="0 0 0 * * *" \
  -e WATCHTOWER_CLEANUP="true" \
  -e TZ="Europe/Rome" \
  nickfedor/watchtower
