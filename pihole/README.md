## Promtail
I use promtail to forward logs to my rev_proxy (npm.home) service, where i push my logs to Grafana.

Pihole service container does not use pihole as it's own dns (should it even?) so npm.home doesn't resolve anywhere. Instead i use 10.0.0.61, which is the static ip for npm.home. If that ever changes, this will bork.

## Promtail service
There's a background service running in the background. It runs /opt/promtail. It's enable to start on boot. 
The actual config file is in /etc/promtail/promtail.yaml.
The actual service config is in /etc/systemd/system/promtail.service
