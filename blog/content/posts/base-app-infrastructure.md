---
title: "Base App Infrastructure"
date: 2024-05-10T03:00:23-07:00
tags:
  - crossplane
  - homelab
  - k8s
  - SDLC
  - vault

---
In my [previous post]({{< ref "/posts/vault-secrets-into-k8s" >}}), I had figured out how to inject Vault secrets into Kubernetes Secrets using the [Vault Secrets Operator](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator). My runthrough of the walkthrough worked, but I [swiftly ran into namespacing issues]({{< ref "/posts/vault-secrets-into-k8s#added-2024-04-29-namespacing-secrets" >}}) when trying to use it "_in production_".

<!--more-->

# The Problem

The setup can be divided into two parts[^platform-vs-app-team]:
* Creation of a Vault Role (with `boundServiceAccountNamespaces` corresponding with the k8s namespaces that should be permitted to access it) and Policy, and a k8s `VaultAuth` object telling the Vault Secrets Operator how to access the Vault Role.
* Creation of a `VaultStaticSecret` (referencing the VaultAuth object) in the app's `-deployment` repo, which results in a k8s secret.

As I started trying to extend my initial installation to other apps, I realized that simply adding more k8s namespaces to the `boundServiceAccountNamespaces` of a single Vault Role would not be a secure solution - it would allow _any_ pods in any of the bound namespaces to access any secret of any of the (other) applications. Ideally, each application-stage (or, equivalently, each k8s namespace[^namespaces-per-application]) would have its own resources created, with the Vault Role only accessible from that namespace[^sub-namespace-permissions].

## Why do I care?

You may be wondering why I care about Least Privilege - after all, it's only my own homelab, surely I know and trust every application that's running on it? Well, to an extent. I trust them enough to install them, but it still doesn't hurt to limit their privileges so that any unforeseen misbehaviour - whether deliberate or accidental - has limited impact. More importantly, my primary motivation in running this homelab is to learn and practice technical skills - the tasks don't have to be entirely practical, so long as they are educational! In fact, as you'll see shortly, this problem is almost-exactly equivalent to one I'm going to be solving at work soon, so doing this "right" is a good head-start.

# The solution

Ideally, I'd be able to automate (via extracted-and-parameterized logic) the creation of these resources as part of the application definition, since many apps will have similar requirements and I want to minimize any manual or imperative setup.

Thankfully, this is pretty close to a problem that I've been looking into at work, so I have a solution ready to go - [Crossplane](https://www.crossplane.io/), a tool that allows:
* management of "_External Resources_" (i.e. resources in systems outside Kubernetes, like Vault, Argo, etc.) via Kubernetes objects - i.e. you can declaratively create and update a Kubernetes object (a "_Managed Resource_") which represents the External Resource, and the Kubernetes reconciliation loop will keep the External Resource up-to-date.
* "bundling" of resources into Compositions - parameterized and inter-related collections of resources, analagous to Constructs in CDK.

![Diagram of the interrelation of the various Crossplane concepts](https://docs.crossplane.io/media/composition-how-it-works.svg "Diagram of the interrelation of the various Crossplane concepts")

With Crossplane in hand, the solution becomes simple:
* (while wearing my "Platform Team" hat) install a Provider (the interface between Crossplane and an external service) for Vault, and create a Composition which bundles the Vault resources that are necessary for Vault Secrets Operator setup.
* (wearing my "App team" hat) whenever I install an app which requires secret injection, do so alongside a Composite Resource (an instance of a Composition). All from the convenience of a single deployment repo, and with only a few extra lines of configuration!

## Walkthrough

You can see the solution [here](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/e798564692f71187e3ff3f9d77f3aa1c46ca9ee4/charts/vault-crossplane-integration/base-app-infra.yaml).

### XRD

(Lines 1-26) A [Composite Resource Definition](https://docs.crossplane.io/latest/concepts/composite-resource-definitions/) (or "XRD" - yeah, I know, but Kubernetes had already taken the term "CRD") is like (in Programming Language terms) the Interface to a [Composition](https://docs.crossplane.io/latest/concepts/compositions/)'s Implementation, or (in Web Service) the API Spec or schema. It defines how a consumer can invoke a Composition - the name they should use, and the parameters they should pass. Consumers can either invoke this by its name if creating a cluster-scoped [Composite Resource](https://docs.crossplane.io/latest/concepts/composite-resources/), or in a namespaced context via a [Claim](https://docs.crossplane.io/latest/concepts/claims/).

This definition is saying:
* (Lines 6-8) "_There's a Composition that can be addressed as `xbaseapplicationinfrastructures.scubbo.org`_..."
* (Lines 10-12) "_...(which can also be addressed by the Claim Name `BaseAppInfra`)..._"
* (Lines 13-25) "_...which has only a single version defined, which takes a single string parameter named `appName`_"

It is apparently possible to provide [multiple schema versions](https://docs.crossplane.io/v1.15/concepts/composite-resource-definitions/#multiple-schema-versions) - but since "_new required fields are a 'breaking change.'_" and "_Only one version can be `referenceable` \[...which...\] indicates which version of the schema Compositions use_", I'm not really sure how that is actually useful - and this is borne out by the fact that "_Crossplane recommends implementing breaking schema changes as brand new XRDs._".

### Top-level Composition

The only point to note in lines 29-36 is that `spec.compositeTypeRef.apiVersion` and `spec.compositeTypeRef.kind` must match the values set on 6, 8, and 14.

### Vault Resources

Lines 37-136 define Vault Resources, provided by the [Vault Provider](https://github.com/upbound/provider-vault). These create a Vault Role, Policy, and KV Secrets Mount roughly as described in the [walkthrough](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator). Note the use of [patches and transforms](https://docs.crossplane.io/latest/concepts/patch-and-transform/) to set values in the Managed Resources based on properties of the Claim (the Kubernetes namespace and the parameter `appName`)

### Kubernetes Resource

The [Vault Secrets Operator walkthrough](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator) also [requires](https://github.com/hashicorp-education/learn-vault-secrets-operator/blob/main/vault/vault-auth-static.yaml) the creation of a `VaultAuth` object (specifying how the Secrets Operator should authenticate to Vault - i.e. which Role to use), and that is [not an object provided by the Vault Provider](https://doc.crds.dev/github.com/upbound/provider-vault)[^limited-vault-provider], so I also needed to use the [Kubernetes Provider](https://github.com/crossplane-contrib/provider-kubernetes) to create an arbitrary Kubernetes object as part of the Composition.

### Actual usage

After deploying this Composition to my cluster, actual usage was a doddle:

```bash
$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: example-namespace-for-crossplane-vault-secrets-demo
---
apiVersion: scubbo.org/v1alpha1
kind: BaseAppInfra
metadata:
  name: example-app-base-infra
  namespace: example-namespace-for-crossplane-vault-secrets-demo
spec:
  appName: example-app
EOF
namespace/example-namespace-for-crossplane-vault-secrets-demo created
baseappinfra.scubbo.org/example-app-base-infra created

$ kubectl ns example-namespace-for-crossplane-vault-secrets-demo
Context "default" modified.
Active namespace is "example-namespace-for-crossplane-vault-secrets-demo".

$ kubectl get BaseAppInfra example-app-base-infra
NAME                     SYNCED   READY   CONNECTION-SECRET   AGE
example-app-base-infra   True     True                        29s

$ vault secrets list | grep 'example-app'
app-example-app-kv/    kv           kv_d4b378a7           KV storage for app example-app

$ vault read auth/kubernetes/role/vault-secrets-operator-example-app-role
Key                                 Value
---                                 -----
alias_name_source                   serviceaccount_uid
audience                            vault
bound_service_account_names         [default]
bound_service_account_namespaces    [example-namespace-for-crossplane-vault-secrets-demo]
token_bound_cidrs                   []
token_explicit_max_ttl              0s
token_max_ttl                       0s
token_no_default_policy             false
token_num_uses                      0
token_period                        0s
token_policies                      [vault-secrets-operator-example-app-policy]
token_ttl                           24h
token_type                          default

$ vault kv put -mount app-example-app-kv example-secret key=value-but-make-it-secret
============= Secret Path =============
app-example-app-kv/data/example-secret

======= Metadata =======
Key                Value
---                -----
created_time       2024-05-09T05:53:59.20680794Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1

$ kubectl get secrets
No resources found in example-namespace-for-crossplane-vault-secrets-demo namespace.

$ cat <<EOF | kubectl apply -f -
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: vault-kv-app
  namespace: example-namespace-for-crossplane-vault-secrets-demo
spec:
  type: kv-v2
  mount: app-example-app-kv
  path: example-secret

  destination:
    name: secretkv
    create: true
  refreshAfter: 30s
  vaultAuthRef: vault-auth-example-app
EOF
vaultstaticsecret.secrets.hashicorp.com/vault-kv-app created

$ kubectl get VaultStaticSecret
NAME           AGE
vault-kv-app   6s

$ kubectl get secrets
NAME       TYPE     DATA   AGE
secretkv   Opaque   2      23s

$ kubectl get secret secretkv -o jsonpath='{.data.key}' | base64 -d
value-but-make-it-secret
```

Almost all of the steps above were executed "as if" I was a memeber of the App Team. The Platform Team (or, more accurately, automation owned by the Platform Team, but triggered during Application Creation via the Developer Platform like [Backstage](https://backstage.io/)) should take care of creating the Namespace, but everything else - creating the `BaseAppInfra`, populating the Vault Secret, and creating the `VaultStaticSecret` - are tasks that the App Team can handle.

# Next Steps and Further Thoughts

* Unwinding my yak-shaving-stack by another level, my motivation for injecting secrets from Vault was to be able to set up [Velero](https://velero.io/) with AWS Credentials so I can back up my PVs to S3. Most of my pods are using my TrueNAS cluster as a persistent storage provider (thanks to [this great walkthrough](https://jonathangazeley.com/2021/01/05/using-truenas-to-provide-persistent-storage-for-kubernetes/)), with RAID for redundancy[^raidz1], so they should be _reasonably_ durable - but, backups are still important!
  * I should probably export the ZFS Snapshots off-site as well. The task stack never ends...
* My system's getting complex enough that an architecture diagram in the [README](https://gitea.scubbo.org/scubbo/helm-charts) would be useful - at least, as a reminder to myself of what tools I have running, even if no-one else would be interested!
* Because I'm using an [App Of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/), I don't need to create Argo Applications[^argo-application] and Policies for the applications - but, for setups that don't use that pattern (like, say, my work :P ), those resources should also be part of the Base Infrastructure. Assumable (Vault) Roles for the application _itself_ to use would also be good.
* This setup defines a Composition that any App Team can create (via Claim), but I haven't looked into how to prevent (non-admin) users from creating arbitrary Managed Resources (outside the scope of a Composition). That is, there's nothing to prevent a user from using Crossplane to create a Vault Policy that has global access, creating a Vault Role using that Policy that's available to their namespace, and wreaking havoc. I suspect this would be a use-case for [Kyverno](https://kyverno.io/), [OpenPolicyAgent](https://www.openpolicyagent.org/docs/latest/kubernetes-introduction/), or other policy tools.
* Several fields in the [Composition](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/e798564692f71187e3ff3f9d77f3aa1c46ca9ee4/charts/vault-crossplane-integration/base-app-infra.yaml) are mutually-dependent. For instance, the name of the Vault Role ([line 71](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/e798564692f71187e3ff3f9d77f3aa1c46ca9ee4/charts/vault-crossplane-integration/base-app-infra.yaml#L71)) must be referenced by the VaultAuth on [line 166](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/e798564692f71187e3ff3f9d77f3aa1c46ca9ee4/charts/vault-crossplane-integration/base-app-infra.yaml#L166), and the name of the Vault Policy ([line 128](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/e798564692f71187e3ff3f9d77f3aa1c46ca9ee4/charts/vault-crossplane-integration/base-app-infra.yaml#L128)) must be assigned to the Role on [line 79](https://gitea.scubbo.org/scubbo/helm-charts/src/commit/e798564692f71187e3ff3f9d77f3aa1c46ca9ee4/charts/vault-crossplane-integration/base-app-infra.yaml#L79). I'd _love_ to use [cdk8s](https://cdk8s.io/) to _define_ the resources instantiated by Crossplane, so that these dependencies can be made explicit, rather than incidental. As a coworker of mine is fond of proclaiming, "_YAML is the assembly language of Cloud-Native_" - although it's a universally-comprehended language that tools can use to communicate, we as human developers should be using higher-level tools and abstractions.
* I've still only used the Secrets Operator to inject static secrets. I'd be interested to see how [Dynamic Secrets](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator#setup-dynamic-secrets) - for secret values which have to change over time, such as TTL'd creds for other services -  would work. According to the [docs](https://kubernetes.io/docs/concepts/configuration/secret/#editing-a-secret), "_updates to existing `Secret` objects are propagated automatically to Pods that use the data_", which is pretty cool.
  * An alternative would be to use the [Vault Sidecar Injector service](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar) to directly inject and update Vault secret values into the Pod. At first glance, I'd be averse to running both this _and_ Vault Secrets Operator - I'd prefer to have one-and-only-one way of getting Vault Secrets into Kubernetes, and VSO (plus native Secret mounting) seems to cover all use-cases whereas Vault Sidecare only covers injection (and not setting Secret values as env variables) - but, it's always good to know the alternative options!

[^platform-vs-app-team]: In a production setup in a fully-operationalized company, these tasks would be carried out by the Platform team and by the App team, respectively. Obviously in my own homelab setup, I fulfil both roles - but if it ever seems odd in this article that I'm jumping through hoops to keep permission segregated "from myself", keep in mind that I'm effectively "acting as" two different teams.
[^namespaces-per-application]: or, for grants that should be available to all stages of the application, "_each set of namespaces which correspond with a single application_". IDK if this is an industry-standard Best Practice, but the norm at work is to have k8s namespaces `foo-application-dev`, `foo-application-qa`, and `foo-application-prod` for each of the stages of the application, which seems like a sensible way to limit blast radius of changes. I wonder if there's a k8s-native concept of "namespace hierarchies", where you could define (say) a parent namespace `foo-application` (which "contains" the three leaf namespaces), and havy any permission grants "trickle down" to its children.
[^sub-namespace-permissions]: not relevant right now, but I wonder if there's a use-case for even stricter restrictions than just the namespace granularity. I can imagine a case where there are several pods/jobs within a(n application-stage - that is, within a) namespace, but where a given secret should only be accessible to a subset of them. Something for Future-Jack to look into! That level of restriction would presumably be handled at the k8s-level, not the Vault level - the App/Platform boundary interface ensures only that the right secrets are available to the right App, and then the App itself (via k8s) is responsible for further scope-restrictions.
[^limited-vault-provider]: which is fair - it's a CRD inherent to the Vault Secrets Operator and is an object which exists "in" Kubernetes, not in the external service Vault itself
[^raidz1]: Only RAIDZ1, which is apparently [frowned upon](https://serverfault.com/questions/634197/zfs-is-raidz-1-really-that-bad) - but, given that I'm paying for my own hardware rather than designing it for a corporate budget, I'm making a tradeoff between redundancy and cost-of-drives.
[^argo-application]: Argo is pretty great as a tool, but I will _never_ forgive them for the heinous naming decision of giving the name "Application" to "_a single stage/deployment of an application_"

<!--
Reminders of patterns you often forget:

Images:
![Alt-text](url "Caption")

Internal links:
[Link-text](\{\{< ref "/posts/name-of-post" >}})
(remove the slashes - this is so that the commented-out content will not prevent a built while editing)
-->