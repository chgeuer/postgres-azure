#!/bin/bash

function createIp {
  startIpInput=$1
  index=$2

  #change internal field separator
  oldIFS=$IFS
  IFS=.
  #parse IP into array
  ary=($startIpInput)
  #reset internal field separator
  IFS=$oldIFS

  ip=""
  #create C-Net of Ip
  for (( i=0; i<$((${#ary[@]}-1)); i++ ))
  do
    ip="$ip${ary[$i]}."
  done

  #create D-Net of Ip
  ip="$ip$((${ary[-1]}+index))"
  printf "%i" "$ip"
}

# "commandToExecute": "[concat('./start-zk.sh ', 
#                              copyIndex(), ' ', 
#                              variables('zookeeperInstanceCount'), ' ', 
#                              variables('zookeeperNetPrefix'), variables('zookeeperNetStartIP'))]"

#myIndex=$1
#instanceCount=$2
#startIp=$3

myIndex=1
instanceCount=3
startIp=10.0.0.10

zkversion=3.4.9
javaversion1=7u75
javaversion2=b13

sudo apt-get -y install jq supervisor

#
# Install Java
#
# wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -c -O "jdk-8u121-linux-x64.tar.gz" "http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jdk-8u121-linux-x64.tar.gz"
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" -c -O "jdk-${javaversion1}-linux-x64.tar.gz"  "http://download.oracle.com/otn-pub/java/jdk/${javaversion1}-${javaversion2}/jdk-${javaversion1}-linux-x64.tar.gz"

mkdir --parents /usr/lib/jvm/jdk-${javaversion1}
tar -xvf jdk-${javaversion1}-linux-x64.tar.gz --strip-components=1 --directory /usr/lib/jvm/jdk-${javaversion1} 
update-alternatives --install "/usr/bin/java"   "java"   "/usr/lib/jvm/jdk-${javaversion1}/bin/java" 1
update-alternatives --install "/usr/bin/javac"  "javac"  "/usr/lib/jvm/jdk-${javaversion1}/bin/javac" 1
update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/lib/jvm/jdk-${javaversion1}/bin/javaws" 1
chmod a+x /usr/bin/java
chmod a+x /usr/bin/javac
chmod a+x /usr/bin/javaws

#
# Install ZooKeeper
#
zkbindir=/usr/local/zookeeper-${zkversion}
zkworkdir=/var/lib/zookeeper
mkdir --parents $zkbindir
mkdir --parents $zkworkdir
mirror=$(curl -s "https://www.apache.org/dyn/closer.cgi?as_json=1" | jq --raw-output .preferred)
curl --get --url "${mirror}zookeeper/zookeeper-${zkversion}/zookeeper-${zkversion}.tar.gz" --output "zookeeper-${zkversion}.tar.gz"
tar -xvf "zookeeper-${zkversion}.tar.gz" --strip-components=1 --directory "$zkbindir"

cat > "$zkbindir/conf/zoo.cfg" <<-EOF 
	tickTime=2000
	dataDir=${zkworkdir}
	clientPort=2181
	initLimit=5
	syncLimit=2
EOF

i=1
while [[ $i -le $instanceCount ]]; do
	cat > "$zkbindir/conf/zoo.cfg" <<-EOF 
		server.$i=$(createIp "$startIp" "$(i-1)"):2888:3888
	EOF
  i=$(i+1)
done

cat > "${zkworkdir}/myid" <<-EOF 
	$(myIndex + 1)
EOF

cat > /etc/supervisor/conf.d/zookeeper.conf <<-EOF 
	[program:zookeeper]
	command=$zkbindir/bin/zkServer.sh start-foreground
	autostart=true
	autorestart=true
	stopsignal=KILL
	startsecs=10
	startretries=999
	stderr_logfile=/var/log/zookeeper.err.log
	stdout_logfile=/var/log/zookeeper.out.log
	logfile_maxbytes=20MB
	logfile_backups=10d;
EOF

service supervisor restart
supervisorctl reread
supervisorctl update
