# Centos下Redis集群搭建

## 1.虚拟机先打快照，方便操作失误时及时回退

## 2.备份旧Redis数据

停掉redis服务，我个人是启动脚本放在/etc/init.d下，执行下面指令关停redis服务

``` shell
./redis stop
#查看redis服务状态
netstat -nlpt | grep redis
```

先找到自己的redis数据文件(rdb)以及redis的配置文件(conf)进行备份

``` shell
find / -name "*.rdb"
find / -name "6479.conf"
mv /data/redis_dbs /data/redis_dbs_bak
mv /etc/redis /etc/redis_bak
```

## 3.升级redis版本，配置redis配置文件

此处更换为redis版本5.0.6，压缩包放在文75件夹中，解压并源码包安装

``` shell
tar -zxvf redis-5.0.6.tar.gz
cd redis-5.0.6
make && make install
```

替换旧版本可执行文件，通常位于/usr/local/bin

``` shell
rm -rf /usr/local/bin/*
cd src
mv redis-benchmark redis-check-aof redis-check-rdb redis-cli redis-sentinel redis-server /usr/local/bin/
```

配置一份conf配置文件, 此处拿6479举例

``` shell
cd ..
#没有文件夹就自己创建
mv redis.conf /etc/redis/6479.conf
cd /etc/redis
#修改redis配置
1.改端口, 命令行模式输入%s/6379/6479/g进行全局替换
2.将bind 127.0.0.1注释掉
3.关闭保护模式, protected-mode no
4.设置数据文件名称和保存路径
dbfilename dpzj-6479.rdb
dir /data/redis_dbs/
5.开启集群
cluster-enabled yes
cluster-config-file nodes-6479.conf
cluster-node-timeout 15000
6.后台运行模式 daemonize yes
```

配置完后在6479.conf所在的目录下执行脚本生成集群配置文件

``` shell
./create_redis_conf.sh
```

配置主从redis配置文件

``` shell
#主redis
cp 6479.conf 6579.conf
sed -i 's/6479/6579/g' ./6579.conf
#修改redis配置
1.修改数据文件名称 
dbfilename dpzj_cache.rdb
2.关闭集群
#cluster-enabled yes
#cluster-config-file nodes-6579.conf
#cluster-node-timeout 15000
#从redis
cp 6579.conf 7579.conf
sed -i 's/6579/7579/g' ./7579.conf
#修改redis配置
1.修改数据文件名称 
dbfilename dpzj_cache_readonly.rdb
2.添加主从配置 
slaveof 192.168.1.90 6579
```

6679和7679配置同为主从，数据文件名称为dpzj_online.rdb与dpzj_online_readonly.rdb

至此，配置文件配置完毕

## 4.redis集群开机自启动脚本

将压缩包文件中的redis放在/etc/init.d/下，即可开机自启动

可使用./redis start ./redis stop进行redis服务的开启与关停

用netstat -nlpt | grep redis看redis是否正常启动

## 5.创建集群

集群划分：

集群1： 6479、6480、6481、7479、7480、7481

集群2： 6779、6780、6781、7779、7780、7781

其中 6开头的为主节点，7开头的为备用节点

PS.以6479为例建立集群

``` shell
redis-cli -h localhost -p 6479
CLUSTER MEET 192.168.1.90 6480
CLUSTER MEET 192.168.1.90 6481
CLUSTER MEET 192.168.1.90 7479
CLUSTER MEET 192.168.1.90 7480
CLUSTER MEET 192.168.1.90 7481
```

配置主备节点(连接备用节点的数据库)

``` shell
redis-cli -h localhost -p 7479
localhost:7479> CLUSTER NODES
b7da32151ab87515b3d16740298b15f9f9af3af4 192.168.1.90:7479@17479 myself,master - 0 1653360068000 3 connected
f7b75a976414a1e1750e2f21a3fdb4e7e684c36f 192.168.1.90:6481@16481 master - 0 1653360069000 0 connected
412eacf402d826fbbc3e48a1f35e19819204a9da 192.168.1.90:6480@16480 master - 0 1653360068985 2 connected
45aaf741ec723c9923fdf384b984da1b10c16b84 192.168.1.90:7480@17480 master - 0 1653360067000 4 connected
1f1638465efc8d1e6e03813737953281b580359a 192.168.1.90:6479@16479 master - 0 1653360069992 1 connected
b5c6df0924a27b58f173176e9a0228ae81968bd8 192.168.1.90:7481@17481 master - 0 1653360067978 5 connected
localhost:7479> CLUSTER REPLICATE 1f1638465efc8d1e6e03813737953281b580359a
#7480与7481依次类推
```

通过上述方式，建立各个集群，并配置好主备节点

## 6.配置redis集群的槽点

依旧使用脚本add_nodes_slot.sh

``` shell
find / -name nodes-* | xargs -L 1 ./add_nodes_slot.sh
```

至此，集群配置完毕

## 7.重启redis服务，检查集群是否启动成功

``` shell
/etc/init.d/redis stop
/etc/init.d/redis start
netstat -nlpt | grep redis
redis-cli -h localhost -p 6479
localhost:6479> CLUSTER INFO
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:6
cluster_size:3
cluster_current_epoch:5
cluster_my_epoch:1
cluster_stats_messages_ping_sent:37
cluster_stats_messages_pong_sent:40
cluster_stats_messages_sent:77
cluster_stats_messages_ping_received:40
cluster_stats_messages_pong_received:32
cluster_stats_messages_received:72
```

## 8.恢复旧数据

将redis-shake工具放到虚拟机, 我放在/etc/redis/目录下

根据需要配置redis-shake.conf文件

``` shell
1.源数据的路径
source.rdb.input =  /data/redis_dbs_bak/dpzj-6479.rdb;/data/redis_dbs_bak/dpzj-6480.rdb;/data/redis_dbs_bak/dpzj-6481.rdb
2.目标ip
target.address = 192.168.1.90:6479;192.168.1.90:6480;192.168.1.90:6481
```

执行redis-shake还原旧数据

``` shell
./redis-shake.linux -type restore -conf redis-shake.conf
```

至此, 项目redis集群搭建完毕