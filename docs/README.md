# Yilu Common chart

Yilu-Common is a base chart for all internally used charts.

## VERSIONS AND BREAKING CHANGES

This template supports semantic versioning as helm.

with the version `0.3.0` breaking changes are introduced and template is not backward compatible.
*Helm v3 supported only.*
Lots of changes on how the templates are configured.
But generated manifest is still same.

## USAGE

### How to use

You can use `helm create .` then helm will automatically creates necessary folders.

```bash
~/tmp/demo-service$ helm create demo-service-chart
Creating demo-service
/tmp/$ cd demo-service-chart && ls -l
total 16
-rw-r--r--   1 guneriu  wheel   1.1K Sep 29 14:39 Chart.yaml
drwxr-xr-x   2 guneriu  wheel    64B Sep 29 14:39 charts
drwxr-xr-x  10 guneriu  wheel   320B Sep 29 14:39 templates
-rw-r--r--   1 guneriu  wheel   1.8K Sep 29 14:39 values.yaml

```

Helm generated a bunch of files inside the templates folder \
but we won't need them for common chart. Because common-chart will generate \
all necessary files for the deployment. Also clean the variables from values.yaml

```bash

~/tmp/demo-service/demo-service-chart$ rm -rf /templates
~/tmp/demo-service/demo-service-chart$ echo "" > values.yaml

```

Add yilu-common repo to your helm repos list.

```bash
~/tmp/demo-service$ helm repo add yilu-common https://yiluhub.github.io/common-chart/
```

Now let's add yilu-common as a dependency, append the lines to Chart.yaml

```yaml
dependencies:
  - name: yilu-common
    version: 0.3.0
    repository: https://yiluhub.github.io/common-chart/
```

Update dependency to fetch the chart

```bash
 ~/tmp/demo-service$ helm dependency update demo-service-chart
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "local" chart repository (http://127.0.0.1:8879/charts):
Get "http://127.0.0.1:8879/charts/index.yaml": dial tcp 127.0.0.1:8879: connect: connection refused
...Successfully got an update from the "kubernetes" chart repository
...Successfully got an update from the "yilu-common" chart repository
...Successfully got an update from the "hashicorp" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Downloading yilu-common from repo https://yiluhub.github.io/common-chart/
Deleting outdated charts
```

Ideally, you would pass the params via values.yaml but let's test if things are fine until now.
You should see manifest output.

```bash
 ~/tmp/demo-service$ helm template  demo-service-chart --debug --set yilu-common.image.tag="test" --set serviceName="demo-service"

 ---
# Source: demo-service/charts/yilu-common/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-service
  labels:
    simpletrip: demo-service
spec:
  type: NodePort
  ports:
  - port: 8080
    name: http
  selector:
    simpletrip: demo-service
---
# Source: demo-service/charts/yilu-common/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-service
  labels:
    simpletrip: demo-service
spec:
  selector:
    matchLabels:
      simpletrip: demo-service
  template:
    metadata:
      labels:
        simpletrip: demo-service
    spec:
      containers:
      - name: simpletrip
        image: 432560034976.dkr.ecr.eu-central-1.amazonaws.com/yiluhub/demo-service:test
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: spring-boot-cloud
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 300
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
        env:
        - name: SPRING_ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: spring-boot-cloud
              key: spring.environment
        - name: CLOUD_ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: spring-boot-cloud
              key: cloud.environment
        - name: SERVER_PORT
          value: "8080"
        - name: DD_AGENT_HOST
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        - name: DD_TRACE_ENABLED
          valueFrom:
            configMapKeyRef:
              name: datadog-config
              key: apm.enabled
        - name: DD_SERVICE_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['simpletrip']
        - name: DD_TRACE_ANALYTICS_ENABLED
          valueFrom:
            configMapKeyRef:
              name: datadog-config
              key: apm.enabled
        - name: DD_LOGS_INJECTION
          valueFrom:
            configMapKeyRef:
              name: datadog-config
              key: apm.enabled
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: simpletrip
                operator: In
                values:
                -
            topologyKey: kubernetes.io/hostname
      nodeSelector:
        role: general-purpose
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
---
# Source: demo-service/charts/yilu-common/templates/hpa.yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: demo-service
spec:
  minReplicas: 2
  maxReplicas: 10
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-service
  targetCPUUtilizationPercentage: 80
```

---

#### Example CronJob configuration

```yaml
serviceName: "whatever-name"
containerName: "whatever-container-name"
job:
  enabled: true
  concurrencyPolicy: "Forbid"
  schedule: "'*/15 * * * *'"
  successfulJobsHistoryLimit: 10
  failedJobsHistoryLimit: 10
  overrideImageUrl: busybox  # optional; otherwise it uses the same image used for deployment
  extraEnvConfigMapRef: extra-env-config-map-name  # optional; if you want to have extra env configuration
  image:
  args:
    - java
    - -jar
    - /usr/local/lib/app.jar
    - -v
```

### Deprecated - AWS Configuration

Configuring AWS access for your app is done via injecting existing k8s secret containing AWS credentials to container

```yaml
aws:
  enabled: true
  secretKeyRefName: "aws-secrets"
```

will generate the code below, please configure your secret accordingly to match with the keys `key_id`, `secret`

```yaml
    env:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: aws-secrets
          key: key_id
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: aws-secrets
          key: secret
```

#### New Method Static Secrets & Environment Secrets
Please use staticSecret and environment secrets to generate the same configuration.


```yaml
yilu-common:
  staticSecrets:
    enabled: true
    secrets:
    - secretName: "bookings-s3-secrets"
      secretPath: "aws_s3_credentials"
      mountPath: "kv/infra/secrets"
      type: kv-v2
      
  environmentSecrets:
    - name: AWS_ACCESS_KEY_ID
      secretKeyRef:
        name: bookings-s3-secrets
        key: key_id
    - name: AWS_SECRET_ACCESS_KEY
      secretKeyRef:
        name: bookings-s3-secrets
        key: secret
```

### Secrets Configuration

We have enabled Kubernetes & Vault secret integration in chart version 0.4.0 and above.
More details can be found [here](https://yiluts.atlassian.net/wiki/spaces/YILU/pages/2463694899/HCP+Vault+-+Kubernetes+Integration)

You can fetch secrets from Vault via Vault Secrets Operator(VSO).
Either static or dynamic secrets, VSO can fetch the secret and serve you in a few ways (please check [environment-secrets](#using-environment-secrets)    (later on [secret data transformation](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/secret-transformation)) will be introduced)  
More details around adding/ updating secrets in Vault can be found [here](https://github.com/yiluhub/vault-service-secret)

### Adding dynamic and static secrets with vault secrets operator

To enable the `dynamicSecrets`, you need to set `enabled` as true, provide a valid `mountPath`, `permissionsRolePath`.

To enable the `staticSecrets`, you need to set `enabled` as true, provide a valid `mountPath`, `secretName`, `secretPath`, `secretKeys`

Shown below is an example of how to set this up:

```yaml
yilu-common:
  secrets:
    dynamicSecrets:
      enabled: false
      mountPath: "<some path here>" # example: aws/secret-engines"
      secrets:
        - name: "some-name" # something like worldshop
          type: "type of dynamic secrets engine" # example: aws
          permissionsRolePath: "vault role path here>" # example: creds/service-read"
          renewalPercent: 70
    staticSecrets:
      enabled: false
      secrets:
        - secretName: "<some name here"  # example: Yilu-static-secret
          secretPath: "<some secret path here>" # example: worldshop
          mountPath: "<some path here>" # example: kv/services/secrets
          refreshInterval: "1h"
          secretKeys:
            - KEY1
            - KEY2
```

> [!WARNING] 
> Deprecated   
> The `secretKeys` are the ones that will be assigned to env vars for the deployment, they also match the keys in vault for the specific secret

To know which exact `permissionsRolePath` value to use for a given environment, you need to check the respective vault for the given environment under the `aws/secrets-engine` for AWS, and among the roles, select one with the permissions your application needs.

>[!NOTE]
>NOTE: This secrets stanza is the same one used by the external secrets operator.  
> This will remain the same for now until we fully migrate to the new vault secrets operator to avoid confusion.

### Using Static Secret Data Transformations
With version 0.6.6, [secret-data-transformation](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/secret-transformation)  
Let's think of the backend services secrets configuration, 
it's a secret with key `application.yaml` that contains `base64` encoded secrets. 
We need to `decode` them before creating the k8s secret. (externalsecrets had internal function to support this, decodingStrategy)
Otherwise, we end up secrets being encoded twice (remember, k8s `base64` encodes the secret value)

To be able to have the same functionality using Vault Secrets Operator transformation templates.
For list of the functions that can be used, please check [template-functions](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/secret-transformation#template-functions)

```yaml
  staticSecrets:
    enabled: true
    secrets:
      - secretName: "payment-secrets" 
        secretPath: "payments" 
        mountPath: "kv/services/secrets"
        type: kv-v2
        transformation:
          key: application.yaml
          function: b64dec
```
will generate
```yaml
apiVersion: v1
data:
  application.yaml: c3ByaW5nOgogIGthZmthOgogICAgcHJvcGVydGllczoKICAgICAgc2FzbC5qYWFzLmNvbmZpZzogb3JnLmFwYWNoZS5rYWZrYS5jb21tb24uc2VjdXJpdHkucGxhaW4uUGxhaW5Mb2dpbk1vZHVsZSByZXF1aXJlZCB1c2VybmFtZT0iVUNOU0Q3N1c2VkhIM1RSNyIgcGFzc3dvcmQ9InAvVEZaSHFhTDJGN1BDMWVJNDFBZzlydHdYbE8wakpLNlNLdnZ6VS9HRjZ6SGhraTY1eHhCNWpqeFA2bXVmQU0iOwogICAgICBzY2hlbWEucmVnaXN0cnkuYmFzaWMuYXV0aC51c2VyLmluZm86IDJIVlBPSVFUQVQ2VFRRTlA6NStDUHFxY000bHQveVpSWldDRXZHQnR6cG00d2N4TTc3MjdPRlBUcC9qR1FkdHh1d1JaMzdmMVRBNXljZk9jagphd3MtczM6CiAgYnVja2V0OgogICAgYWNjZXNzLWtleTogQUtJQVdKTlVXS1NRS0RQS0JQVjUKICAgIHNlY3JldC1rZXk6IDdOOUFXSFJ6QXlVMDZScEZCV0szVk5aVWdGaEc5dW52djZoeldIcm4KYm9va2luZy1zZXR0aW5nczoKICBsdWZ0aGFuc2E6CiAgICBjbGllbnQtaWQ6IHM3ZXl4bmtua3N5MmpnZGg3azlidDU4bgogICAgY2xpZW50LXNlY3JldDogZW1oREJwek1TZTRwVk5EUktBYk4=
kind: Secret
```

>[!IMPORTANT]
> And now we need to mount this secret to container and pass a value so spring framework can find the file
> This is required because monorepo and amp-monorepo configured to mount the secrets
> in future we need to switch to reading secrets from environment values

```yaml
yilu-common:
  extraVolumeMounts:
    - name: payment-secrets
      mountPath: /etc/secrets
      
  extraVolumes:
    - name: payment-secrets
      secret:
        secretName: payment-secrets

  extraEnv:
    - name: SPRING_CONFIG_ADDITIONAL-LOCATION
      value: file:/etc/secrets/

```

### Using Environment Secrets

Environment secrets usage is provided via `environmentSecrets` parameter.
This feature gives you the flexibility to specify additional environment variables to be populated from Kubernetes secrets.

Let's assume our chart has 2 static secrets defined, `bookings-s3-secrets` and `sonarqube-secrets`

with the configuration below, you expose 3 environment variables from 2 different secret. 
```yaml
environmentSecrets:
  - name: SONARQUBE_TOKEN
    secretKeyRef:
      - name: sonarqube-secrets
        key: token
  - name: AWS_S3_BUCKET_ACCESS_KEY_ID
    secretKeyRef:
      - name: bookings-s3-secrets
        key: access_key_id
  - name: AWS_S3_BUCKET_ACCESS_SECRET
    secretKeyRef:
      - name: bookings-s3-secrets
        key: access_secret
```

### Migration from 0.5.x to 0.6.x

If you are migrating from `0.6.0` or earlier, the major changes are the way we handle vault secrets.

The strategy here is:

1. add the new secret format, while maintaining the old one
2. deploy the new chart
3. once that has been applied and all looks good after deployment
4. adjust the code of the application to read the new secrets as environment variables defined in the values.yaml file
5. once this has been tested over a few days, then remove the old secret declarations

Please follow the steps below for step 1 describe above:

1. Change the chart version in the `Chart.yaml` file to `0.6.3`
2. Set `yilu-common.secrets.dynamicSecrets.enabled` `yilu-common.secrets.staticSecrets.enabled` to `true` in your values file, depending on what your application needs. This will enable the static or dynamic secrets.
3. For each of the dynamic secrets your application needs (aws or database), add them to the `yilu-common.secrets.dynamicSecrets.secrets` list specifying all the required attributes and values. This will hold all your dynamic secrets configurations.
4. For each of the static secrets your application needs, add them to the `yilu-common.secrets.staticSecrets.secretKeys` exactly how they are named in vault preserving their format (uppercase or lowercase or camel case, etc).

These steps will upgrade your existing Vault Secrets in Kubernetes to the new Secret Format which uses the dynamic and static secret vault engines.

At this point, if the upgrade is complete and deployments work as expected with no errors, ask the developers to adjust the application code to read the "secrets" from env vars as specified in `yilu-common.secrets.staticSecrets.secretKeys` or `AWS_ACCESS_KEY_ID` `AWS_SECRET_ACCESS_KEY` for AWS dynamic credetials and `username` `password` for database dynamic credentials.

Once that migration is complete, and all looks good, go ahead and remove the following keys in the helm chart as they are not needed anymore:

- `yilu-common.secrets.enabled`
- `yilu-common.secrets.refreshInterval`
- `yilu-common.secrets.data`

### Migration from 0.6.5 to 0.6.6
`secrets.staticSecrets` parameter altered to accept list of secrets.

Old config
```yaml
  secrets:
    staticSecrets:
      enabled: true
      mountPath: kv/services/secrets
      refreshInterval: 1h
      secretName: worldshop-secrets
      secretPath: worldshop-secrets
      version: 1
      secretKeys:
      - AUTHORIZATION_TOKEN
      - WORLDSHOP_PRICING_API

```

New Config, please don't use `version` parameter, unless you really intend to use a specific version of the Vault secret
```yaml
  secrets:
    staticSecrets:
      enabled: true
      secrets:
        - secretName: worldshop-secrets
          secretPath: worldshop-secrets
          mountPath: "kv/services/secrets"
          refreshInterval: 1h
          type: kv-v2
          secretKeys:
            - AUTHORIZATION_TOKEN
            - WORLDSHOP_PRICING_API

```

## Parameters

## Yilu-Common parameters

| Name                     | Description                                                                                                                  | Value                                                     |
|--------------------------|------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| `serviceName`            | Service name, *mandatory*                                                                                                    | ``                                                        |
| `containerName`          | Service container name                                                                                                       | ``                                                        |
| `image.repository`       | Service image repository                                                                                                     | `432560034976.dkr.ecr.eu-central-1.amazonaws.com/yiluhub` |
| `image.tag`              | Service image tag (immutable tags are recommended), *mandatory*                                                              | `""`                                                      |
| `image.pullPolicy`       | Service image pull policy                                                                                                    | `Always`                                                  |
| `secrets.enabled`        | Enable injection of existing secrets                                                                                         | `false`                                                   |
| `secrets.name`           | name of the existing secrets                                                                                                 | `""`                                                      |
| `aws.enabled`            | DEPRECATED- Enable injection of AWS credentials via secrets                                                                  | `DEPRECATED - false`                                      |
| `aws.secretKeyRefName`   | DEPRECATED - name of the existing secrets contains AWS credentials                                                           | `"DEPRECATED " `                                          |
| `args`                   | Override default container args (useful when using custom images)                                                            | `[]`                                                      |
| `extraEnv`               | Extra environment variables to be set on the container                                                                       | `[]`                                                      |
| `extraVolumeMounts`      | Extra volume mounts to be configured on the container, for details please refer to [extraVolumeMounts](#extra-volume-mounts) | `[]`                                                      |
| `environmentSecrets`     | Extra environment values to be set from given secret, for details please refer to [environmentSecrets](#environment-secrets) | `[]`                                                      |
| `mockClientsConfEnabled` | Setup environment variables for Mocking (useful for dev)                                                                     | `false`                                                   |
| `labels`                 | labels to add to container                                                                                                   | `""`                                                      |
| `resources`              | add resource request                                                                                                         | `"check readme file"`                                     |

### Exposure parameters

| Name                               | Description                            | Value                    |
|------------------------------------|----------------------------------------|--------------------------|
| `service.type`                     | Kubernetes service type                | `NodePort`               |
| `service.port`                     | Kubernetes service HTTP port           | `8080`                   |
| `service.ports.https.enabled`      | Enable Kubernetes service HTTPS port   | `false`                  |
| `service.ports.https`              | Kubernetes service HTTPS port          | `443`                    |

### Service Health

| Name                                 | Description                                                       | Value              |
|--------------------------------------|-------------------------------------------------------------------|--------------------|
| `livenessProbe.path`                 | LivenessProbe path                                                | `/actuator/health` |
| `livenessProbe.port`                 | LivenessProbe port. If empty/null, falls back to `service.port`   | `""`               |
| `livenessProbe.initialDelaySeconds`  | LivenessProbe initial delay second to make request                | `300`              |
| `readinessProbe.path`                | ReadinessProbe path                                               | `/actuator/health` |
| `readinessProbe.port`                | ReadinessProbe port. If empty/null, falls back to `service.port`  | `""`               |
| `readinessProbe.initialDelaySeconds` | ReadinessProbe initial delay second to make request               | `30`               |

### Monitoring

| Name                             | Description                                | Value             |
|----------------------------------|--------------------------------------------|-------------------|
| `datadog.serviceNameEnv`         | Environment variable name for service name | `DD_SERVICE_NAME` |
| `datadog.analyzedSpansEnabled`   | Enable span analyze                        | `false`           |

### AutoScaling

| Name                                 | Description                                  | Value |
|--------------------------------------|----------------------------------------------|-------|
| `hpa.targetCPUUtilizationPercentage` | Target Cpu percentage to trigger autoscaling | `80`  |
| `hpa.minReplicas`                    | Min number of replicas                       | `2`   |
| `hpa.maxReplicas`                    | Max number of replicas                       | `10`  |

### CronJob

| Name                             | Description                                        | Value   |
|----------------------------------|----------------------------------------------------|---------|
| `job.enable`                     | Enable creation of the cronjob                     | `false` |
| `job.overrideImageUrl`           | Image url, otherwise uses default image repository | `""`    |
| `job.concurrencyPolicy`          | Job concurrency policy                             | `""`    |
| `job.schedule`                   | Job schedule, cron tab format                      | `""`    |
| `job.successfulJobsHistoryLimit` | Job successful jobs history limit                  | `""`    |
| `job.failedJobsHistoryLimit`     | Job failed jobs history limit                      | `""`    |
| `job.command`                    | Command to run on the container                    | `""`    |
| `job.args`                       | Extra args to pass to container                    | `[]`    |
| `job.extraEnvConfigMapRef`       | Name of the configmap to inject to container       | `""`    |

### Dynamic/Static Secrets (Vault Secrets Operator)

| Name                                                   | Description                                                                                                                                                                                                 | Value                              |
|--------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------|
| `secrets.vault.namespace`                              | Namespace in Vault where the secrets are created                                                                                                                                                            | `admin/yiluhub`                    |
| `secrets.vault.vaultSecretsOperatorName`               | Name of the Vault secrets operator name                                                                                                                                                                     | `"vault-secrets-operator"`         |
| `secrets.vault.authRef`                                | vault secrets operator auth ref name prefixed with the namespace                                                                                                                                            | `"vault-secrets-operator/default"` |
| `secrets.dynamicSecrets.enabled`                       | This value enables the dynamic secrets                                                                                                                                                                      | `false/true`                       |
| `secrets.dynamicSecrets.mountPath`                     | The Vault dynamic secret engine mount path                                                                                                                                                                  | `"eg. aws/secrets-engine"`         |
| `secrets.dynamicSecrets.secrets`                       | The list of secrets to be created in k8s secret resource                                                                                                                                                    | `"[]"`                             |
| `secrets.dynamicSecrets.secrets[].name`                | The name of the of the secret to be created in k8s secret resource                                                                                                                                          | `""`                               |
| `secrets.dynamicSecrets.secrets[].type`                | The type of the dynamic secret                                                                                                                                                                              | `"aws or database"`                |
| `secrets.dynamicSecrets.secrets[].permissionsRolePath` | the dynamic secrets role path in vault                                                                                                                                                                      | `"eg. creds/service-read"`         |
| `secrets.dynamicSecrets.secrets[].renewalPercent`      | percentage of the TTL at which the secret is renewed. value is represented as % (percentage), so 70 is 70% of the TTL                                                                                       | `"eg. 70"`                         |
| `secrets.staticSecrets.enabled`                        | This value enables the static secrets                                                                                                                                                                       | `false/true`                       |
| `secrets.staticSecrets.secrets`                        | The list of secrets to be created in k8s secret resource                                                                                                                                                    | `[]`                               |
| `secrets.staticSecrets[].secretName`                   | The name of the secret to be created in k8s secrets resource                                                                                                                                                | `""`                               |
| `secrets.staticSecrets[].secretPath`                   | The static secrets path in vault                                                                                                                                                                            | `"worldshop"`                      |
| `secrets.staticSecrets[].mountPath`                    | The Vault static secret engine mount path                                                                                                                                                                   | `"kv/service/secrets"`             |
| `secrets.staticSecrets[].refreshInterval`              | The refresh interval of the secret                                                                                                                                                                          | `""`                               |
| `secrets.staticSecrets[].version`                      | The version of the secret to use, leave empty to use latest                                                                                                                                                 | `"1"`                              |
| `secrets.staticSecrets[].type`                         | The type of static secret engine                                                                                                                                                                            | `"kv-v2"`                          |
| `secrets.staticSecrets[].secretKeys`                   | DEPRECATED use environmentSecrets, The list of secret Keys from the secret, will be exposed as environment variables with same name                                                                         | `DEPRECATED[]`                     |
| `secrets.staticSecrets[].transformation.key`           | The key of the vault secret will be fetch from Vault and will be used with same name for k8s secret                                                                                                         | `""`                               |
| `secrets.staticSecrets[].transformation.function`      | The transformation template function to be applied to secret, refer [here](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/secret-transformation#template-functions) for all supported function | `""`                               |

### DEPRECATED - Secrets (External Secrets Operator) 

| Name                                      | Description                                                  | Value                        |
|-------------------------------------------|--------------------------------------------------------------|------------------------------|
| `secrets.enabled`                         | This value enables the external secrets                      | `false/true`                 |
| `secrets.name`                            | The name of the secret to be created in k8s secrets resource | `""`                         |
| `secrets.refreshInterval`                 | The refresh interval of the secret                           | `""`                         |
| `secrets.data.secretKey`                  | The key of the secret                                        | `"application.yaml"`         |
| `secrets.data.remoteRef.parentKey`        | The vault parent key/mount path for the data                 | `"kv/services/secrets/data"` |
| `secrets.data.remoteRef.property`         | The key of in the vault secret                               | `"application.yaml"`         |
| `secrets.data.remoteRef.decodingStrategy` | The decoding strategy                                        | `Base64`                     |


### Environment Secrets

| Name                                      | Description                                  | Value |
|-------------------------------------------|----------------------------------------------|-------|
| `name`                                    | The name of the environment variable         | `""`  |
| `secretKeyRef.name`                       | The name of the kubernetes secret name       | `""`  |
| `secretKeyRef.key`                        | The key of the given kubernetes secret name  | `""`  |


### Extra Volume Mounts

| Name               | Description                                  | Value |
|--------------------|----------------------------------------------|-------|
| `name`             | The name of the environment variable         | `""`  |
| `mountPath`        | The name of the kubernetes secret name       | `""`  |

### Extra Volumes

| Name   | Description                                                                                                                             | Value |
|--------|-----------------------------------------------------------------------------------------------------------------------------------------|-------|
| `name` | The name of the extra volume                                                                                                            | `""`  |
| 'body' | either empty dir, or generate from secret or configmap, [please refer here](https://kubernetes.io/docs/concepts/configuration/secret/)  | `""`  |

