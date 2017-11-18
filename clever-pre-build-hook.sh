#!/bin/sh
echo "Clone of Golo"
git clone https://github.com/eclipse/golo-lang.git
cd golo-lang
./gradlew installDist

export GOLO_HOME=~/golo-lang/build/install/golo
export PATH=$GOLO_HOME/bin:$PATH
export PATH=~/:$PATH

cd ..

./build-jar.sh
golo golo --classpath jars/*.jar --files imports/*.golo main.golo


