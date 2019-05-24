# Common chard

This is an example charts repository.

### How It Works

I set up GitHub Pages to point to the `docs` folder. From there, I can
create and publish docs like this:

```console
$ helm package yilu-common
$ mv yilu-common-{version}.tgz docs // do not forget to increase the version after making changes
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
