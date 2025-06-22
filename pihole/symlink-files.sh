# Run as root please

# Backup original config, just in case
mv /etc/promtail/promtail.yaml /etc/promtail/promtail.yaml.bak

# Create target directory if it doesn't exist
mkdir -p /etc/promtail

# Create the symlink
ln -s /root/home-server-config/pihole/promtail.yaml /etc/promtail/promtail.yaml

# Symlink the service too
ln -sf /root/home-server-config/pihole/promtail.service /etc/systemd/system/promtail.service
systemctl daemon-reload
systemctl restart promtail
