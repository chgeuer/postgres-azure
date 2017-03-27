
```bash
sudo apt-get -y install jq 

zkversion=3.4.9
mirror=`curl -s "https://www.apache.org/dyn/closer.cgi?as_json=1" | jq --raw-output .preferred`
zkurl="${mirror}zookeeper/zookeeper-${zkversion}/zookeeper-${zkversion}.tar.gz"
curl --get --url $zkurl --output "zookeeper-${zkversion}.tar.gz"

patroniversion=6eb2e2114453545256ac7cbfec55bda285ffb955
curl --get --location --url "https://github.com/zalando/patroni/archive/${patroniversion}.zip" --output "patroni-${patroniversion}.zip" 
```



