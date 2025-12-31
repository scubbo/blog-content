---
title: "Switching from Keycloak to Authentik"
date: 2025-12-31T15:39:00-08:00
tags:
  - homelab
  - k8s
  - authentik
  - sso
  - argocd

---
Remember when I [set up Keycloak for SSO]({{< ref "/posts/oidc-on-k8s" >}})? Well, I've [switched to Authentik](https://github.com/scubbo/homelab-configuration/commit/9b8bffe6ea8b16a5ea54f6cd25fee3b82bd8986f), and it was surprisingly painless.
<!--more-->

## Why the Switch?

Back in April 2024, I chose Keycloak over Authentik based on community recommendations. But after actually trying to integrate more services, I discovered a critical limitation: Keycloak doesn't natively support forward authentication.

**Forward auth** is when your reverse proxy (Traefik, in my case) delegates authentication to an external service before proxying requests. This is essential for applications that don't have native OIDC support - which, in the homelab world, is most of them. The arr-stack (Sonarr, Radarr, etc.), Jellyfin[^jellyfin-plugin], and many others fall into this category.

Keycloak requires a third-party sidecar like [louketo-proxy](https://github.com/louketo/louketo-proxy) (now abandoned) or [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) to handle forward auth. Authentik has this built-in. For a homelab with a mix of OIDC-native and OIDC-ignorant applications, that's a significant advantage.

## The Setup

### Authentik Installation

Authentik deploys via Helm with a few key decisions:

1. **Database**: Rather than using the bundled PostgreSQL subchart, I used [CloudNative-PG](https://cloudnative-pg.io/) to create a managed PostgreSQL cluster (which I was already using for Immich). This gives me the ability to configure proper backups, failover capability, and consistent database management across my cluster.

2. **Storage**: PostgreSQL needs block storage (iSCSI), not NFS. SQLite on NFS is known to be problematic; PostgreSQL is even more sensitive.

3. **Secrets**: Authentik needs a `secret_key` for cryptographic operations. I created a Kubernetes Secret and mounted it into the pods using the `file://` reference pattern that Authentik supports.

The ArgoCD application definition uses `helmRemotePlusLocalApplication` to combine the upstream Helm chart with my local CloudNative-PG `Cluster` resource:

```jsonnet
appDef.helmRemotePlusLocalApplication(
    name="authentik",
    sourceRepoUrl="https://charts.goauthentik.io",
    sourceChart="authentik",
    sourceTargetRevision="2025.10.3",
    pathToLocal="charts/authentik",
    nonHelmApp=true,
    helmValues={
        authentik: {
            secret_key: "file:///authentik-secrets/secret-key",
            postgresql: {
                host: "authentik-database-rw",
                // credentials mounted from CloudNative-PG's auto-generated secret
            }
        },
        postgresql: { enabled: false },  // Don't use bundled PostgreSQL
        redis: { enabled: true }
    }
)
```

### ArgoCD Integration

ArgoCD was my first integration target, since it has native OIDC support via Dex. The configuration goes in the Helm values:

```yaml
configs:
  cm:
    dex.config: |
      connectors:
        - type: oidc
          id: authentik
          name: Authentik
          config:
            issuer: https://auth.avril/application/o/argo-cd/
            clientID: <from authentik>
            clientSecret: $dex.authentik.clientSecret
            insecureEnableGroups: true
            insecureSkipVerify: true  # TODO: proper TLS certificates
            scopes:
              - openid
              - profile
              - email
  rbac:
    policy.default: role:admin  # All authenticated users get admin
```

## The Gotchas

### TLS Certificates

My first attempt failed with a certificate error - Dex couldn't verify the TLS certificate for `auth.avril`. Traefik was serving its default self-signed cert instead of a proper one for the hostname. For now, I'm using `insecureSkipVerify: true`, but this is at the top of my TODO list to fix properly with cert-manager.

### The Slug Matters

I spent way too long debugging a 404 error before realizing that Authentik auto-generates the application slug from the name. I'd named my application "ArgoCD" which became slug `argo-cd`, but I'd configured Dex with `argocd`. One character cost me 20 minutes of debugging.

### RBAC is Opt-In

Successfully authenticating via SSO doesn't mean you can see anything. By default, SSO users have zero permissions in ArgoCD. You need to explicitly configure RBAC policies. For a single-user homelab, `policy.default: role:admin` is fine. For anything more sophisticated, you'd want to set up the `groups` scope in Authentik and map groups to roles.

## What's Next

With Authentik running, the plan is:

1. **Proper TLS certificates** - Use cert-manager to issue real certs for `auth.avril` and `argo.avril` (and others!)
2. **Grafana** - Has native OIDC support, should be straightforward
3. **Jellyfin** - Requires the [SSO plugin](https://github.com/9p4/jellyfin-plugin-sso), slightly more complex
4. **Forward auth** - For apps without native OIDC (arr-stack, etc.)

The forward auth capability is really the killer feature. Once that's set up, I can protect _any_ web application behind Authentik, regardless of whether it knows anything about authentication.

---

# The Twist

Everything before the line-rule above[^footnote] was generated by `claude` as the final output of the implementation session. I made a couple of small tweaks (correcting it that Cloudnative Postgres gives the _ability_ to do centralized management, but that I'm not doing so yet; stating that I'd already installed the database for Immich; advising to use Hugo's syntax for internal links rather than a bare `[text](/path/to/content)`; adding a link to the implementation commit), but it was 99% as-generated. I feel like it's captured my style pretty well - maybe a few more numbered-lists that I would have used, and clearer "topic words" in bulleted lists, but otherwise the structure and tone could have fooled me.

To be clear, this was a one-off experiment, not an ongoing practice - *nothing on this blog is (or ever will be) AI-/LLM-generated unless explicitly stated as such*. To slightly [misquote Chris](https://bsky.app/profile/chrisgardiner.bsky.social/post/3maogza2cic2s), the product of writing is not words, but understanding. I don't write this blog primarily so that words will exist on the Internet; I write so that:
* I can ensure that I myself understand what I did, and can solidify that understanding in my brain. Copy-pasting an LLM-generated summary does not achieve that.
* Others who want to understand or replicate what I did can have a guide, beyond just looking at the commits.

On the second point, the LLM route is _less_ clearly inferior than self-written - an LLM that's just gone through the process with me will have information on motivation, context, limitations, etc.[^code-only-says-what-it-does] that might not exist in the commits or comments. Arguably, if the choice is between "_not writing a blog post (because it takes too much effort to do it manually)_" or "_an LLM-written post_", the spread of understanding is better served by the latter. Still, though, I can't shake the feeling that there's a clear divide in intent between "_commit messages (which could be hand-written or tool-generated)_" and "_blog posts (which the social contract implies **should** be hand-written)_". For the moment, I'll encourage LLM tools into writing more-descriptive commit message and use those as the "LLM output", and keep blog posts hand-written for things that matter enough for my higher-level consciousness to discuss them.

[^jellyfin-plugin]: Jellyfin still needs a third-party plugin for SSO, but at least Authentik's configuration for it is well-documented.
[^footnote]: Well, and the footnote above this one, I guess
[^code-only-says-what-it-dows]: Shout-out one of my favourite technical articles, "[_Code Only Says What It Does_](https://brooker.co.za/blog/2020/06/23/code.html)".
