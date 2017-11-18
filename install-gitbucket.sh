#!/bin/sh

# =================================
#  Install GitBucket
# =================================

gitbucket_version="4.18.0"
gitbucket_ci_version="1.2.1"

# create application
application_path="gitbucket"

mkdir $application_path
cd $application_path

echo "GitBucket setup and deployment is started"
curl -L https://github.com/gitbucket/gitbucket/releases/download/$gitbucket_version/gitbucket.war --output gitbucket.war

mkdir -p 777 storage/.gitbucket/plugins          
curl -L https://github.com/takezoe/gitbucket-ci-plugin/releases/download/$gitbucket_ci_version/gitbucket-ci-plugin-assembly-$gitbucket_ci_version.jar --output storage/.gitbucket/plugins/gitbucket-ci-plugin-assembly-$gitbucket_ci_version.jar



