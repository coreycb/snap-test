#!/bin/bash

set -ex

source $BASE_DIR/admin-openrc

snap list | grep -q nova || {
    sudo snap install --edge nova
}

openstack user show nova || {
    openstack user create --domain default --password nova nova
    openstack role add --project service --user nova admin
}

openstack service show compute || {
    openstack service create --name nova \
      --description "OpenStack Compute" compute

    for endpoint in public internal admin; do
        openstack endpoint create --region RegionOne \
          compute $endpoint http://localhost:8774/v2.1/%\(tenant_id\)s || :
    done
}

sudo cp -r $BASE_DIR/etc/nova/common/* /var/snap/nova/common

sudo nova.manage db sync
sudo nova.manage api_db sync

sudo systemctl restart snap.nova.*

openstack flavor show m1.tiny || openstack flavor create --id 1 --ram 512 --disk 1 --vcpus 1 m1.tiny
openstack flavor show m1.small || openstack flavor create --id 2 --ram 2048 --disk 20 --vcpus 1 m1.small
openstack flavor show m1.medium || openstack flavor create --id 3 --ram 4096 --disk 20 --vcpus 2 m1.medium
openstack flavor show m1.large || openstack flavor create --id 4 --ram 8192 --disk 20 --vcpus 4 m1.large
openstack flavor show m1.xlarge || openstack flavor create --id 5 --ram 16384 --disk 20 --vcpus 8 m1.xlarge