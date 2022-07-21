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
$ cp yilu-common/README.MD docs/
$ git add .
$ git commit -m "version {version} has been created"
$ git push origin master
```

From the environment that you work on, You can do  
```
$ helm repo add yilu-common https://yiluhub.github.io/common-chart/
```
And then yilu-common is going to be available as dependency.


## FIXME 
* add pipeline to automatically lint, publish new versions of chart to github docs
