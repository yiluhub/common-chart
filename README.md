# Common chart

This repository contains helm charts for yilu. 

## Yilu-Common
Base template to create k8s deployments. For more info check [yilu-common/README.md](yilu-common/README.md)

From the environment that you work on, You can do  
```
$ helm repo add yilu-common https://yiluhub.github.io/common-chart/
```
And then yilu-common is going to be available as dependency.

## New version of common-chart

In the scope of [YAF-5543: Refactor the common-chart repo to use the chart-releaser github action](https://yiluts.atlassian.net/browse/YAF-5543) was created test fork with chart-releaser action.  
Fork: [yiluhub/YAF-5543-common-chart](https://github.com/yiluhub/YAF-5543-common-chart)  
  
SRE team decision:  
* if what we have currently works fine, lets leave it as is for now until such a time when these github actions have matured and can deliver the solution we are looking for
* if we migrate to them, we may introduce new bugs into our workflow, which in part is what we want to avoid since we wana standardize the release process...
* i think this we can shelve it and revisit it in 3 or 6 months...
