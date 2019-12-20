# Common chart

This is an example charts repository.

### How It Works

I set up GitHub Pages to point to the `docs` folder. From there, I can
create and publish docs like this:


- Increase the `version` in `Chart.yml` file 
- Run the commands shown below

```console
$ helm package yilu-common
$ mv yilu-common-{version}.tgz docs 
$ helm repo index docs --url https://yiluhub.github.io/common-chart/
$ git add .
$ git commit -m "version {version} has been created"
$ git push origin master
```

From the environment that you work on, You can do  
```
$ helm repo add yilu-common https://yiluhub.github.io/common-chart/
```
And then yilu-common is gonna be available as dependency.

### Example chart

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
```
serviceName: "whatever-name"
containerName: "whatever-container-name"
job:
  concurrencyPolicy: "Forbid"
  schedule: "'*/15 * * * *'"
  successfulJobsHistoryLimit: 10
  failedJobsHistoryLimit: 10
  overrideImageUrl: busybox  # optional; otherwise it uses the same image used for deployment
  extraEnv: extra-env-name  # optional; if you want to have extra env configuration
  image:
  args:
    - java
    - -jar
    - /usr/local/lib/app.jar
    - -v
```