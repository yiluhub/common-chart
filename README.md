# Common chard

This is an example charts repository.

### How It Works

I set up GitHub Pages to point to the `docs` folder. From there, I can
create and publish docs like this:

```console
$ helm package yilu-common
$ mv yilu-common-{version}.tgz docs // do not forget to increase the version after makind changes
$ helm repo index docs --url https://yiluhub.github.io/common-chart/
$ git add -i
$ git commit -av
$ git push origin master
```

From there, I can do a `helm repo add yilu-common
https://yiluhub.github.io/common-chart/
