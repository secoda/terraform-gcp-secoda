# Helm Chart (Enterprise)

## Disclaimer

### New customers

Please contact us for your company-specific Docker token. Secoda on-premise is an enterprise product, and we are happy to provide you with a token if you contact us through Intercom or Slack.


## Prerequisites

- This chart requires **Helm 3.0**.
- A PostgreSQL database.
  - Persistent volumes are not reliable - we strongly recommend that a long-term
    installation of Secoda host the database on an externally managed database (for example, AWS RDS).
-  This chart runs Secoda in a single pod and requires about *4 vCPU* and *16 GB memory*.

## Setup

Once your database is created, connect to it and then create the keycloak user and two seperate databases on it.

```bash
psql -h <HOST> -U postgres
```

```bash
create database keycloak;
create database secoda;
create user keycloak with encrypted password 'xxxx';
grant all privileges on database keycloak to keycloak;
grant all privileges on database secoda to keycloak;
```

## Usage

1.  Add the Secoda Helm repository:

        $ helm repo add secoda https://secoda.github.io/secoda-helm
        "secoda" has been added to your repositories

2.  Ensure you have access to the `secoda` chart:

        $ helm search repo secoda/secoda
        NAME         	CHART VERSION	APP VERSION	DESCRIPTION
        secoda/secoda	4.12.0       	4.1.1      	helm x secoda

3.  Run this command `git clone https://github.com/secoda/secoda-helm.git`

4.  Modify the `examples/predefined-secrets.yaml` file. Replace all values that have a comment next to them.

- Uncomment `ingress.hosts` and change `ingress.hosts.host` to be the hostname where you will access Secoda.
- Load Balancer TLS is required for Secoda, uncomment `ingress.tls` and:
  - Specify the name of the SSL certificate to use as the value of `ingress.tls.secretName`.
  - Specify an array containing the hostname where you will access Secoda (the same value you configured for `ingress.hosts.host`).

GKE-specific configurations:

- Specify `/*` as the value of `ingress.hosts.paths.path`.
- The field `ingress.tls.servicePort` is not required.
- (Optional) Follow SQL Auth Proxy [guide](https://cloud.google.com/sql/docs/postgres/connect-kubernetes-engine) and enable `cloudSqlAuthProxy.enabled` and modify `cloudSqlAuthProxy.databaseName`.

5.  Add your customer-specific docker secret, this is required to pull Secoda's images:

        $ kubectl create secret docker-registry secoda-dockerhub --docker-server=https://index.docker.io/v1/ --docker-username=secodaonpremise --docker-password=<CUSTOMER_SPECIFIC_PASSWORD> --docker-email=carter@secoda.co

6.  Now you're all ready to install Secoda:

        $ gcloud container clusters get-credentials <CLUSTER> --region <REGION> # If using GKE
        $ helm repo update
        $ helm install my-secoda secoda/secoda -f predefined-secrets.yaml

# Different Configurations

1. Nginx Ingress instead of HAProxy. You can modify the `predefined-secrets.yaml` with the following to use nginx:

```yaml
annotations:
  kubernetes.io/ingress.class: nginx
  nginx.org/server-snippets: |
    location / {
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_buffer_size 128k;
        proxy_buffers 8 256k;
        proxy_busy_buffers_size 256k;
    }
```

## Contributing

Install these tools:

```bash
brew install pre-commit
pre-commit install
```

## Troubleshooting

1. If you receive a white page in the keycloak admin console, make sure you are accessing the ingress over HTTPS 443, _not_ HTTP 80.

2. Some k8s are prone to different errors depending on the ingress type. If getting invalid `redirect_uri` on the admin login page, try updating the keycloak database with the following SQL:

```SQL
UPDATE redirect_uris SET value='*' WHERE true;
UPDATE web_origins SET value='*' WHERE true;
```

3. If getting "Failed to sign in" error, your secret environment variable may not match what is in the keycloak configuration. Make sure the environment variable passed to `api` container matches the result of this command:

```SQL
SELECT secret FROM client WHERE client_id='secoda-frontend';
```

4. If you are getting the status error `ImagePullBackOff`. It usually has to do with Docker access token issues. Check the following:
* `imagePullSecrets` must all be in the same namespace as the Pod.
* Confirm the docker secret has been created: `kubectl get secrets` and `kubectl get secret secoda-dockerhub`
