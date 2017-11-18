#!/bin/sh

# =================================
#  Deploy GitBucket to CleverCloud
# =================================

gitbucket_version="4.18.0"
gitbucket_ci_version="1.2.1"

# create fs-bucket add-on
bucket_name="gitbucket-storage"
organization="wey-yu"

clever addon create fs-bucket $bucket_name --plan s --org $organization --region eu

# create application
application_path="gitbucket-project"
application_name="gitbucket-k33g"

# === create repository ===
mkdir $application_path
cd $application_path

clever create $application_name -t war --org $organization --region par --alias $application_name

clever env set JAVA_VERSION 8 --alias $application_name
clever env set GITBUCKET_HOME /app/storage/.gitbucket --alias $application_name
clever env set PORT 8080 --alias $application_name

clever domain add $application_name.cleverapps.io --alias $application_name  
clever scale --flavor M --alias $application_name

org_id=$(grep -o '"org_id": *"[^"]*"' .clever.json | grep -o '"[^"]*"$')
app_id=$(grep -o '"app_id": *"[^"]*"' .clever.json | grep -o '"[^"]*"$')
deploy_url=$(grep -o '"deploy_url": *"[^"]*"' .clever.json | grep -o '"[^"]*"$')

echo "-------------------"
echo " $org_id"
echo " $app_id"
echo " $deploy_url"
echo "-------------------"

# connect to bucket

# link the addon to the application
clever service link-addon $bucket_name --alias $application_name

# get environment variables: BUCKET_HOST



echo "-------------------"
echo " $bucket_host"
echo "-------------------"

# bucket connected
clever env set CC_FS_BUCKET /storage:$bucket_host --alias $application_name

# pre build hook
# Install:
#  - GitBucket
#  - GitBucket CI

cat > install.sh << EOF
#!/bin/sh
echo "GitBucket setup and deployment is started"
curl -L https://github.com/gitbucket/gitbucket/releases/download/$gitbucket_version/gitbucket.war --output gitbucket.war

mkdir -p 777 storage/.gitbucket/plugins          
curl -L https://github.com/takezoe/gitbucket-ci-plugin/releases/download/$gitbucket_ci_version/gitbucket-ci-plugin-assembly-$gitbucket_ci_version.jar --output storage/.gitbucket/plugins/gitbucket-ci-plugin-assembly-$gitbucket_ci_version.jar
EOF
chmod +x install.sh

clever env set CC_PRE_BUILD_HOOK ./install.sh --alias $application_name

# Clever jar json file

# === create clever configuration files ===
mkdir clevercloud
cat > clevercloud/jar.json << EOF
{"deploy": {"jarName": "gitbucket.war"}}
EOF

# create git repository and deploy
git init
git add .
git commit -m "First 🚀 of $application_name"
git remote add clever git+ssh://git@push-par-clevercloud-customers.services.clever-cloud.com/$app_id.git
git push clever master

