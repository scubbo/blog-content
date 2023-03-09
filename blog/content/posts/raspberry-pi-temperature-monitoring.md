---
title: "Raspberry Pi Temperature Monitoring"
date: 2023-03-08T19:44:07-08:00
tags:
  - homelab
  - observability

---
As I've [discussed before]({{< ref "/posts/self-hosting-blog" >}}), this blog is hosted on a k3s cluster which runs on 3 Raspberries Pi in a [nifty little case](https://amzn.to/41W5DU5). The router that powers our home network is in my partner's office, with the Pi cluster nearby so that it can benefit from a fast stable wired Ethernet connection.
<!--more-->
The fans are _pretty_ quiet, but not silent. A couple of weeks back I wondered - are the fans _necessary_? Our home's not terribly hot, the Pi's aren't in direct sunlight, and it's not like I'm running intensive workloads - maybe I could disable the fans and give my partner a bit more quiet in her working day? But on the other hand, I didn't want to fry my precious (and increasingly rare) Pi boards. This sounds like a job for Observability!

Temperature metrics aren't exported from the Node metrics of the [Prometheus stack I'm using](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) (not surprising, as the stack is presumably hardware-independent), but it was a breeze to add them: [this article](https://pimylifeup.com/raspberry-pi-temperature/) described how to access the Pi's internal temperature sensors, and with a [little finangling](https://unix.stackexchange.com/questions/706170/get-raspis-cpu-temperature-within-docker-container/706181#706181) I had a [teeny-tiny app](https://gitea.scubbo.org/scubbo/pi-temperature-monitoring) ready to deploy as a DaemonSet to my nodes (note the [ServiceMonitor](https://gitea.scubbo.org/scubbo/pi-temperature-monitoring/src/branch/main/helm/templates/service-monitor.yaml) which tells Prometheus to pick up metrics from this Service). A Prometheus Query of `max by (node_name) (avg_over_time(sys_cpu_temp_celsius_degrees[$__interval]))` gave a lovely Grafana visualization:

![Grafana Visualization of Raspberry Pi temperature](/img/RaspberryPiTemperatureGraph.png)

I find it particularly pleasing that you can see a representation of their physical layout - there are 3 Pi's in a 4-bay case, so `rasnu2` is closest to an open space with airflow and `rassigma` is furthest. Neat!

The temperature's generally hovering between 35°C and 45°C - that's pretty reasonable! Since they're [apparently specced to go up to 85°C](https://pimylifeup.com/raspberry-pi-temperature/), there should be no risk of disabling the fan.

Unfortunately, the power to the case-fans comes from an adapter that's plugged into one of the Pi's USB-C ports, and I couldn't find a way to selectively depower it[^depower], so I had to power off `rassigma` (the cluster control-plane), physically remove it, and disconnect the power cables to carry out this experiment. Despite using [Longhorn](https://longhorn.io/) Storage Class, Prometheus seems to lose metric history over this disconnection, so I don't have the data to show the graph, but the temperature only jumped up about 10 degrees - still well within the bounds of safety!

...and then the fans on the PoE hats themselves powered up, which were even louder and more irritating than the case fans, so it was back to the default setup pretty quickly. Ah well - not every experiment has the desired outcome, it's still a success if you learn something!


[^depower]: in fact, messing around with [uhubctl](https://github.com/mvp/uhubctl) not only didn't achieve this, but also gave me a minor panic when I realized I'd forgotten to unmount my primary hard drive. Thankfully, all the data was safe. Another sign from the technology gods that I need to [check my backups](https://blog.scubbo.org/posts/check-your-backups/)...
