#!/bin/bash
set +o

groupadd --system pwx-etcd
useradd --home-dir "/var/lib/pwx-etcd" \
      --system \
      --shell /bin/false \
      -g pwx-etcd \
      pwx-etcd

mkdir -p /etc/pwx-etcd
chown -R pwx-etcd:pwx-etcd /etc/pwx-etcd
mkdir -p /var/lib/pwx-etcd
chown -R pwx-etcd:pwx-etcd /var/lib/pwx-etcd


ETCD_VER=v3.3.2
rm -rf /tmp/etcd && mkdir -p /tmp/etcd
curl -L https://github.com/coreos/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd --strip-components=1
cp /tmp/etcd/etcd /usr/bin/etcd
cp /tmp/etcd/etcdctl /usr/bin/etcdctl

# curl -s -L -o /usr/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
# curl -s -L -o /usr/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
# chmod +x /usr/bin/{cfssl,cfssljson}

# curl -s -L -o /tmp/j2y.zip https://github.com/y13i/j2y/releases/download/v0.0.8/j2y-linux_amd64.zip
# unzip /tmp/j2y.zip
# mv /tmp/j2y /usr/bin/j2y

# mkdir /root/cfssl
# cd /root/cfssl
# cfssl print-defaults config | j2y > ca-config.yaml
# cfssl print-defaults csr | j2y > ca-csr.yaml
set -x
echo ${ETCD_HOSTNAME}
set +x

IP=`ip addr | grep -Po '(?!(inet 127.\d.\d.1))(inet \K(\d{1,3}\.){3}\d{1,3})'  | grep 192`
PEERS='http://192.168.1.6:2390,http://192.168.1.7:2390,http://192.168.1.135:2390'
CLUSTER='infra0=http://192.168.1.135:2390,infra1=http://192.168.1.6:2390,infra2=http://192.168.1.7:2390'

cat <<EOF >/etc/pwx-etcd/pwx-etcd.conf.yml
name: ${ETCD_HOSTNAME}
data-dir: /var/lib/pwx-etcd
initial-cluster-state: 'new'
initial-cluster-token: 'pwx-cluster-home'
initial-advertise-peer-urls: ${PEERS}
advertise-client-urls: http://${IP}:2389
listen-peer-urls: http://0.0.0.0:2390
listen-client-urls: http://${IP}:2389,http://127.0.0.1:2389
EOF

cat /etc/etcd/pwx-etcd.conf.yml
echo "\n\n=====================\n\n"

cat <<EOF >/lib/systemd/system/pwx-etcd.service
[Unit]
After=network.target
Description=pwx-etcd - highly-available key value store

[Service]
LimitNOFILE=65536
Restart=on-failure
Type=notify
ExecStart=/usr/bin/etcd --config-file /etc/pwx-etcd/pwx-etcd.conf.yml
User=pwx-etcd

[Install]
WantedBy=multi-user.target
EOF

cat /lib/systemd/system/pwx-etcd.service
echo "\n\n"

systemctl daemon-reload
systemctl enable pwx-etcd
systemctl start pwx-etcd

