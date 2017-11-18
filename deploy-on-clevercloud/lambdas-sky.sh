#!/bin/sh

# =================================
#  Deploy Golo to Clever Cloud
#  git@github.com:eclipse/golo-lang.git
# =================================

organization=$4

# create application
application_path="lambdas-sky-project"
application_name="lambdas-sky"

# === create repository ===
mkdir $application_path
cd $application_path

clever create $application_name -t war --org $organization --region par --alias $application_name

clever env set JAVA_VERSION 8 --alias $application_name
clever env set PORT 8080 --alias $application_name
clever env set TOKEN $1 --alias $application_name
clever env set API $2 --alias $application_name
clever env set CREDENTIALS $3 --alias $application_name

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


cat > install.sh << EOF
#!/bin/sh
echo "Clone of Golo"
git clone git@github.com:eclipse/golo-lang.git
cd golo-lang
./gradlew installDist

export GOLO_HOME=~/golo-lang/build/install/golo
export PATH=$GOLO_HOME/bin:$PATH
export PATH=~/:$PATH

cd ..
git clone git@github.com:k33g/lambdas-sky.git
cd lambdas-sky
./build-jar.sh
golo golo --classpath jars/*.jar --files imports/*.golo main.golo


EOF
chmod +x install.sh

clever env set CC_PRE_BUILD_HOOK ./install.sh --alias $application_name

# Clever jar json file

# === create clever configuration files ===
mkdir clevercloud
cat > clevercloud/jar.json << EOF
{"deploy": {"jarName": "~/golo-lang/build/install/golo/bin/golo-3.3.0-SNAPSHOT.jar"}}
EOF

# create git repository and deploy
git init
git add .
git commit -m "First 🚀 of $application_name"
git remote add clever git+ssh://git@push-par-clevercloud-customers.services.clever-cloud.com/$app_id.git
git push clever master

