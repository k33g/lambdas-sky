#!/bin/sh

# ==============================================
#  Deploy Golo and Lambdas-Sky to Clever Cloud
#  How to launch the script:
#  ./lambdas-sky.sh dvcs_token http(s)://dvcs_domain/api/v3 credentials clever_organization
# ==============================================

golo_version="3.3.0"
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
echo "Cloning Golo project..."
git clone https://github.com/eclipse/golo-lang.git
cd golo-lang
./gradlew installDist


cd ..
git clone https://github.com/k33g/lambdas-sky.git
cd lambdas-sky
./build-jar.sh
cd ..

./golo-lang/build/install/golo/bin/golo golo --classpath \$(pwd)/lambdas-sky/jars/*jar --files \$(pwd)/lambdas-sky/imports/*.golo \$(pwd)/lambdas-sky/main.golo
EOF
chmod +x install.sh

clever env set CC_PRE_BUILD_HOOK ./install.sh --alias $application_name

# Clever jar json file

# === create clever configuration files ===
# TODO: use a version number
mkdir clevercloud
cat > clevercloud/jar.json << EOF
{"deploy": {"jarName": "~/golo-lang/build/install/golo/bin/golo-$golo_version-SNAPSHOT.jar"}}
EOF

# create git repository and deploy
git init
git add .
git commit -m "First 🚀 of $application_name"
git remote add clever git+ssh://git@push-par-clevercloud-customers.services.clever-cloud.com/$app_id.git
git push clever master

