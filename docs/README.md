# Yilu Common chart

Yilu-Common is a base chart for all internally used charts.

## VERSIONS AND BREAKING CHANGES
This template supports semantic versioning as helm. 

with the version `0.3.0` breaking changes are introduced and template is not backward compatible.
*Helm v3 supported only.*  
Lots of changes on how the templates are configured.
But generated manifest is still same. 


### Migration from 0.2.z to 0.3.z
with the new template you don't have to explicitly import values when using the chart. 

this is how it used to be with versions 0.2.z

in the requirements.yaml (Helm v2) or in the Chart.yaml(Helm v3) calling import-values block is mandatory
```yaml
dependencies:
  - name: yilu-common
    version: 0.2.0
    repository: https://yiluhub.github.io/common-chart/
    import-values:
      - data
```

```yaml
serviceName: "communication-engine"
yilu-common:
  exports:
    data:
      secretsEnabled: true
      secretsName: communication-engine-secrets
```

and now it's simplified, import-values is not necessary. 

```yaml
dependencies:
  - name: yilu-common
    version: 0.3.0
    repository: https://yiluhub.github.io/common-chart/
```

```yaml
serviceName: "communication-engine"
yilu-common:
  secretsEnabled: true
  secretsName: communication-engine-secrets
```

## USAGE

### How to use

```bash
$ pwd
/Projects/yilu/example-service

# globally configured (run once after Helm install)
$ helm init --client-only
$ helm repo add yilu-common https://yiluhub.github.io/common-chart/

# project folder specific
$ helm dependency update example-service-chart
$ helm template example-service-chart
---
# Source: example-service-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: example-service
  labels:
    simpletrip: example-service
spec:
  type: NodePort
  ports:
  - port: 8080
  selector:
    simpletrip: example-service
---
```

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

### AWS Configuration

Configuring AWS access for your app is done via injecting AWS credentials to container


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

## Parameters

## Yilu-Common parameters

| Name                      | Description                                                       | Value                                                     |
|---------------------------|-------------------------------------------------------------------|-----------------------------------------------------------|
| `serviceName`             | Service name                                                      | `yilu-common`                                             |
| `containerName`           | Service container name                                            | `yilu-common`                                             |
| `image.repository`        | Service image repository                                          | `432560034976.dkr.ecr.eu-central-1.amazonaws.com/yiluhub` |
| `image.tag`               | Service image tag (immutable tags are recommended)                | `""`                                                      |
| `image.pullPolicy`        | Service image pull policy                                         | `Always`                                                  |
| `secrets.enabled`         | Enable injection of existing secrets                              | `false`                                                   |
| `secrets.name`            | name of the existing secrets                                      | `""`                                                      |
| `aws.enabled`             | Enable injection of AWS credentials via secrets                   | `false`                                                   |
| `aws.secretKeyRefName`    | name of the existing secrets contains AWS credentials             | `""`                                                      |
| `args`                    | Override default container args (useful when using custom images) | `[]`                                                      |
| `extraEnv`                | Extra environment variables to be set on the container            | `[]`                                                      |
| `mockClientsConfEnabled`  | Setup environment variables for Mocking (useful for dev)          | `false`                                                   |
| `labels`                  | labels to add to container                                        | `""`                                                      |


### Exposure parameters

| Name                               | Description                            | Value                    |
|------------------------------------|----------------------------------------|--------------------------|
| `service.type`                     | Kubernetes service type                | `NodePort`               |
| `service.port`                     | Keycloak service HTTP port             | `8080`                   |
| `service.ports.https.enabled`      | Enable Keycloak service HTTPS port     | `false`                  |
| `service.ports.https`              | Keycloak service HTTPS port            | `443`                    |


### Monitoring

| Name                                 | Description                                | Value             |
|--------------------------------------|--------------------------------------------|-------------------|
| `datadog.serviceNameEnv`             | Environment variable name for service name | `DD_SERVICE_NAME` |
| `datadog.autoTraceIdInjection`       | enable trace id injection                  | `false`           |
| `datadog.traceAnalyticsEnabled`      | Enable trace analytics                     | `false`           |
| `datadog.analyzedSpansEnabled.https` | Enable span analyze                        | `false`           |


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
