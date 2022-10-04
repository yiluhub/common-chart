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

also notice exports:data is not necessary, parameter names als changed. please refer to [parameters](#parameters) part of this documentation
```yaml
yilu-common:
  serviceName: "communication-engine"
  secrets
    enabled: true
    name: communication-engine-secrets
```

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
| `serviceName`             | Service name, *mandatory*                                         | ``                                                        |
| `containerName`           | Service container name                                            | ``                                                        |
| `image.repository`        | Service image repository                                          | `432560034976.dkr.ecr.eu-central-1.amazonaws.com/yiluhub` |
| `image.tag`               | Service image tag (immutable tags are recommended), *mandatory*   | `""`                                                      |
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
| `service.port`                     | Kubernetes service HTTP port           | `8080`                   |
| `service.ports.https.enabled`      | Enable Kubernetes service HTTPS port   | `false`                  |
| `service.ports.https`              | Kubernetes service HTTPS port          | `443`                    |


### Service Health

| Name                                   | Description                                         | Value              |
|----------------------------------------|-----------------------------------------------------|--------------------|
| `livenessProbe.path`                   | LivenessProbe path                                  | `/actuator/health` |
| `livenessProbe.initialDelaySeconds`    | LivenessProbe initial delay second to make request  | `300`              |
| `readinessProbe.path`                  | ReadinessProbe path                                 | `/actuator/health` |
| `readinessProbe.initialDelaySeconds`   | ReadinessProbe initial delay second to make request | `30`               |


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
