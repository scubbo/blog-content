---
title: "Jellyfin Over Tailscale"
date: 2025-02-21T21:18:31-08:00
tags:
  - Cloudflare-tunnels
  - Homelab
  - Jellyfin
  - K8s
  - Tailscale

---
I know just enough about computer security to know that I don't know enough about computer security, so I default to keeping my systems as closed-off from the outside world as possible. I use [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) for the few systems that I want to make externally available[^tunnel-dns] (like [Gitea](https://gitea.scubbo.org)), and [Tailscale](https://tailscale.com/) to access "internal" services or ssh while on-the-go.
<!--more-->
Recently I hit on an interesting problem - giving external access to my Jellyfin server. Cloudflare is pretty adamant that they don't support streaming over Tunnels, so that option was out. Thankfully, Tailscale provides a pretty neat solution. By creating an externally-available "jump host", connecting it to your Tailnet, and using [Nginx Proxy Manager](https://nginxproxymanager.com/) to forward requests from the public Internet to the Tailnet, you can provide externally-available access to an internal service without opening a port.

# Step-by-step instructions

## Prerequisites

* A Tailnet
* A DNS domain that you control - in my case, `scubbo.org`
* An AWS Account, with a VPC and Subnet
  * I'm sure similar approaches would work with other Cloud Providers, this is just the one that I'm most familiar with
* Jellyfin running on Kubernetes, with hosts connected to the Tailnet
  * Again, I'm pretty sure this would work on some other hosting system, just so long as you have Nginx or something similar to redirect traffic based on their `Host` header.

## Step 1 - Create the proxy host

Deploy the following Cloudformation Template, setting appropriate values for the VpcId and SubnetId:

```yaml
# https://blog.scubbo.org/posts/jellyfin-over-tailscale
AWSTemplateFormatVersion: 2010-09-09

Parameters:
  VpcIdParameter:
    Type: String
  SubnetIdParameter:
    Type: String

Resources:
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: TailnetProxySecurityGroup
      GroupDescription: Tailnet Proxy Security Group
      SecurityGroupEgress:
        - CidrIp: 0.0.0.0/0
          FromPort: 443
          ToPort: 443
          IpProtocol: -1
        - CidrIp: 0.0.0.0/0
          FromPort: 80
          ToPort: 80
          IpProtocol: -1
      SecurityGroupIngress:
        - CidrIp: 0.0.0.0/0
          FromPort: 22
          ToPort: 22
          IpProtocol: -1
        - CidrIp: 0.0.0.0/0
          FromPort: 80
          ToPort: 80
          IpProtocol: -1
      VpcId:
        Ref: VpcIdParameter

  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: TailnetLaunchTemplate
      LaunchTemplateData:
        UserData:
          Fn::Base64: |
            #!/bin/bash

            # https://docs.docker.com/engine/install/ubuntu/
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update

            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            cat <<EOF | sudo docker compose -f - up -d
            services:
              app:
                image: 'jc21/nginx-proxy-manager:latest'
                restart: unless-stopped
                ports:
                  - "80:80"
                  - "81:81"
                  - "443:443"
                volumes:
                  - data:/data
                  - letsencrypt:/etc/letsencrypt

            volumes:
              data:
              letsencrypt:
            EOF

            curl -fsSL https://tailscale.com/install.sh | sh

  JellyfinProxyInstance:
    Type: AWS::EC2::Instance
    DependsOn: "LaunchTemplate"
    Properties:
      ImageId: ami-04b4f1a9cf54c11d0
      InstanceType: t2.micro
      LaunchTemplate:
        LaunchTemplateName: TailnetLaunchTemplate
        Version: "1"
      NetworkInterfaces:
        - AssociatePublicIpAddress: "true"
          DeviceIndex: "0"
          GroupSet:
            - Ref: "SecurityGroup"
          SubnetId:
            Ref: SubnetIdParameter

```

## Step 2 - Connect the proxy host to the Tailnet

SSH to the host (e.g. via AWS Instance Connect), and run `sudo tailscale up`. Follow the instructions at the resulting URL to connect the machine.

## Step 3 - Configure Nginx Proxy Manager

From a machine already on your Tailnet, connect to `<Tailnet address of the EC2 instance>:81`. Log in with the default credentials of `admin@example.com // changeme` (and follow the instructions to change them immediately!), then:
* Go "Hosts" -> "Proxy Hosts" -> "Add Proxy Host".
* Enter your desired publically-available domain under "Domain Names". Leave "Scheme" and "Forward Port" at the defaults "http" and "80". In "Forward Hostname / IP", enter the Tailscale-name of the host running Jellyfin.
* Check "Block Common Exploits" - [might as well](https://github.com/NginxProxyManager/nginx-proxy-manager/blob/develop/docker/rootfs/etc/nginx/conf.d/include/block-exploits.conf), since the whole point of this is to reduce attack surface. I do have "Websockets Support" enabled, I haven't tested it without.

Note that port 81 is intentionally not exposed via the Security Group - configuring NPM should only be possible from trusted hosts.

## Step 4 - Configure Jellyfin host to accept requests from the publically-available domain

If using a k8s Ingress, add a new entry to the `hosts` array, with `host: <public domain>`, like [this](https://gitea.scubbo.org/scubbo/helm-charts/commit/5e08c653a35314cdf2bf5a1ff3a64d5e44660f2b).

If you're using nginx, I'm sure you can figure that out!

# Possible improvements

* Provide a Cloudformation parameter for a Tailscale Auth Key, allowing the instance to automatically self-authenticate without manually ssh-ing in.
* Preconfigure NPM with the Proxy host rather than needing to configure via the UI.

And, wouldn't you know it - right as I finished writing this blog post, I found out about [Tailscale Funnel](https://tailscale.com/blog/introducing-tailscale-funnel), which seems to do much the same thing. Oh well - this was still a learning experience!

# Why is this preferable to just opening a port?

Honestly...I don't really know. Intuitively it _feels_ safer to have traffic go via an intermediary proxy host and to add a layer of Nginx "_block\[ing\] common exploits_" than to just open up port 80 on my home firewall, but honestly I couldn't tell you why - that is, what attacks this blocks that would otherwise succeed. Like I said, I know enough security to know that there's a ton I don't know. If you have experience or insight here, please let me know!

[^tunnel-dns]: [Here]({{< ref "/posts/cloudflare-tunnel-dns" >}}) is an earlier post on that!
