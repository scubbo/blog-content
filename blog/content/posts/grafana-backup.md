---
title: "Grafana Backup"
date: 2022-01-23T11:02:55-08:00
tags:
  - homelab
---

**Update**: I'm preserving the post below for posterity, but I had the obvious solution in the final sentence - I changed my setup to [run Grafana from Docker and mount a folder from my external Hard Drive](https://github.com/scubbo/pi-tools/blob/main/scripts-on-pi/2_full_setup.sh#L236-L239) (I haven't saved up for a NAS yet!), and now my dashboard definition is persistent across restarts/re-images.
<!--more-->

---

I've [installed Grafana](https://github.com/scubbo/pi-tools/blob/main/scripts-on-pi/2_full_setup.sh#L229-L249) to monitor the Raspberry Pis in my homelab setup, but after a bit of poking around I couldn't find a file that contains the dashboard configuration that can be backed-up to prevent losing configuration if the image/Pi crashed (remember to [check your backups]({{< ref "/posts/check-your-backups" >}})!). To that end, I created a [backup script](https://github.com/scubbo/pi-tools/blob/main/backup-scripts/grafana_backup.py) that retrieves a JSON representation of the currently-saved dashboards, checks if there have been any updates against the previously-saved version (using a hash), and persists it if so. Cron-scheduling of the backup happens [here](https://github.com/scubbo/pi-tools/blob/main/scripts-on-pi/2_full_setup.sh#L256) in my general Pi-setup script.

It's not ideal to have the Grafana username and password persisted into a cron definition - one day I'll update it to use an [API Key](https://grafana.com/docs/grafana/latest/http_api/auth/#create-api-token) (though, before that, I'd like to automate the setup of Grafana itself, such as adding the Prometheus data source and the admin user). Honestly in hindsight I can't remember why I installed Grafana via `apt-get install` and `systemctl start` rather than with Docker as [here](https://grafana.com/docs/grafana/latest/administration/configure-docker/). That way, I could just mount a directory from my hard drive (or, one day, NAS) to persist configuration options.
