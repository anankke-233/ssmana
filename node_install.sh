#!/bin/bash
systemctl stop firewalld
systemctl disable firewalld
#安装sslibev
pre_install(){
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
        yum install -y -q epel-release
    fi
    [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[Error] Install EPEL repository failed, please check it." && exit 1
    [ ! "$(command -v yum-config-manager)" ] && yum install -y -q yum-utils
    if [ x"`yum-config-manager epel | grep -w enabled | awk '{print $3}'`" != x"True" ]; then
        yum-config-manager --enable epel
    fi
    yum install -y -q unzip openssl openssl-devel gettext gcc autoconf libtool automake make asciidoc xmlto libev-devel pcre pcre-devel git c-ares-devel
}
pre_install
cd /etc/yum.repos.d
wget https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo
su -c 'yum -y update'
su -c 'yum -y install shadowsocks-libev'
#安装nodejs
cd /usr/src
wget https://nodejs.org/dist/v8.11.3/node-v8.11.3-linux-x64.tar.xz
xz -d node-v8.11.3-linux-x64.tar.xz
tar -xf node-v8.11.3-linux-x64.tar
mv node-v8.11.3-linux-x64 node8.11.3
ln -s /usr/src/node8.11.3/bin/npm /usr/bin/npm
ln -s /usr/src/node8.11.3/bin/node /usr/bin/node
#安装ssmanager
sudo npm i -g shadowsocks-manager --unsafe-perm
cd /usr/src/node8.11.3/lib/node_modules/shadowsocks-manager/
sudo npm install sqlite3 --save --unsafe-perm
ln -s /usr/src/node8.11.3/lib/node_modules/shadowsocks-manager/bin/ssmgr /usr/bin/ssmgr
#启动ss和ssmgr
mkdir /root/.ssmgr
cat > /root/.ssmgr/ss.yml<<-EOF
type: s

shadowsocks:
  address: 127.0.0.1:4000
manager:
  address: 0.0.0.0:4001
  password: 'babyshark@1989'
db: 'ss.sqlite'

EOF
nohup ss-manager -m aes-128-gcm -u --manager-address 127.0.0.1:4000 >ss.log 2>&1 &
nohup ssmgr -c ss.yml >ssmgr.log 2>&1 &

#增加自启动脚本
cat > /etc/rc.d/init.d/ssmana<<-EOF
#!/bin/sh
#chkconfig: 2345 80 90
#description:ssmana

nohup ss-manager -m aes-128-gcm -u --manager-address 127.0.0.1:4000 >ss.log 2>&1 &
nohup ssmgr -c ss.yml --debug>ssmgr.log 2>&1 &

EOF

#设置脚本权限
chmod +x /etc/rc.d/init.d/ssmana
chkconfig --add ssmana
chkconfig ssmana on
