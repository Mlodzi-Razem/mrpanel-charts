# mrpanel-charts

Helm charts for deploying MRPanel.

These charts are designed to be deployed to a single-node. You might be able to configure
them to work with multiple nodes, but this has not been tested. In such a case, you definitely
should take a look at volumes and storage classes, because `hostpath` is used by default.

### Observability
Observability relies on your cluster having Grafana, Prometheus and Loki installed and
configured for monitoring the k8s node. There are `ServiceMonitor`s for each of the
components that are not included when deploying with the `docker-desktop` environment selected.

### SSL Certificates
The `mrpanel-gateway` chart is configured to use `cert-manager` to generate and renew
certificates. The default domain is `panel.mrpanel.org`, so you probably will need to override the
`domain` value.

You might want to completely disable the `mrpanel-gateway` chart if you are not using it. Just set
`includeGateway` to `false` in your environment (see [environments](environments)).

## Requirements
### Dev/prod
- Configured microk8s cluster, version 1.34 or greater. You can use any k8s distribution, but
you must know how to configure it.
- Configured addons:
  - `dns`
  - `rbac`
  - `helm`
  - `hostpath-storage`
  - `metrics-server`
  - `cert-manager`
  - `observability`,
  - `metallb`
  - `ingress`
- Cloudflare API token for `cert-manager`
- Helmfile installed

### Local
- Docker-Desktop with Kubernetes enabled
- Helm and Helmfile installed

## Configuration

### Secrets
Create a file called `secret-values.yaml` in the root of the repository. This file will be used to store all your secrets.
See `secrets.yaml.gotmpl` to understand how secrets are fetched.

#### Example `secret-values.yaml`:
```yaml
mrpanel-infra:
  postgres:
    user: "mrpanel"
    database: "mrpanel"
    password: "very-hard-password"
mrpanel-containers:
  mrpanel-ui-web:
    oauth:
      clientId: "dmfngjkslijfsldfjklsdf.apps.googleusercontent.com"
      clientSecret: "jnjklFGlskdfmsafHSADF"
    nextauth:
      secret: "afnawlksfjweopaawepfpaoesf"
mrpanel-gateway:
  cloudflare:
    apiKey: "dsnskdfmsaDFASDfnisadfSADFw4rasfSDF"
```

### Override values
You can override any value in any chart by creating a file called `overrides/RELEASE_NAME.yaml`, ex.: `overrides/mrpanel-infra.yaml`.
It is also possible to override environment-specific values by creating a file called `overrides/environment.yaml`.

Example `environment.yaml`:
```yaml
Environment:
  volumes:
    rootPath: "/Users/kamillapinski/mrpanel/volumes"
```

## Deploying mrpanel
Make sure that your `kubectl` is configured to use the cluster you want to deploy to.

For server deployment:
```shell
helmfile -e microk8s sync
```

For local development (does not include HPA and `mrpanel-gateway`):
```shell
helmfile -e docker-desktop sync
```