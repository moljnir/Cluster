#!/bin/bash
set -x


# Local variables
SERVICE=mysql
CONFIG="./$SERVICE.cfg"

# Create the mysql drbd resource
#
#
function setup_drbd {
cat > /etc/drbd.d/mysql.res <<EOF
resource mysql {
device /dev/drbd0;
meta-disk internal;
net {
    protocol C;
    allow-two-primaries yes;
    fencing resource-and-stonith;
    verify-alg sha256;
    allow-two-primaries;
    }
syncer {
    verify-alg sha256;
    }
disk {
 on-io-error detach;
}
on node-a {
    node-id 0;
    disk /dev/node-a/mysql00 ;
    address 172.56.0.89:7789;
    }
on node-b {
    node-id 1;
    disk /dev/node-b/mysql00 ;
    address 172.56.0.90:7789;
    }
connection-mesh {
    hosts  node-a node-b;
    }
}
EOF
}

function setup_firewall {
# Assume firewalld
# Update the firewall configuration to permit the cluster & drbd specific service endpoints (7789 for mysql)
firewall-cmd --add-service high-availability --permanent
firewall-cmd --add-port 7789/tcp --permanent
firewall-cmd --reload
# Check...
firewall-cmd --list-all

# Note: the network security group MUST also allow these ports 
# ingress_cluster contains all the required ports
# egress_cluster containts all the required ports
# each node's vnic is placed in both network security groups.
}

function create_drbd_md {
# Create the mysql drbd device
drbdarm create-md $SERVICE
}

function start_drbd_md {
# Start the mysql drbd resource (on all participating nodes)
drbdadm up $SERVICE 
}

function force_drbd_primary {
# on ONE node , force mode to primary
drbdadm primary $SERVICE --force
}

function create_xfs {
# on ONE node, create a XFS file system and mount the device 
mkfs.xfs /dev/dbrb/by-res/$SERVICE
mount /dev/dbrb/by-res/$SERVICE /mnt
df -h /mnt
# unmount /mnt
}

# --------------------- MAIN ---------------------------
# 
# perform actions in offline CIB file
pcs cluster cib $CONFIG
# Disable STONITH **** MUST USE IN PRODUCTION *****
#pcs stonith disable
# 
# Create VIP
pcs -f $CONFIG resource create "p_ip_$SERVICE" ocf:heartbeat:IPaddr2 \
 ip=172.56.0.91 cidr_netmask=24 op monitor interval=30s 

# Create filesystem mount
pcs -f $CONFIG resource create "p_fs_$SERVICE" ocf:heartbeat:Filesystem device="/dev/drbd/by-res/$SERVICE" directory=/u01 fstype=xfs 

# Create storage

pcs -f $CONFIG resource create "ms_drbd_$SERVICE" ocf:linbit:drbd drbd_resource="$SERVICE" promotable \
  promoted-max=1 promoted-node-max=1 clone-max=2 clone-node-max=1 notify=true 


# Create mysql service
pcs -f $CONFIG resource create "p_$SERVICE" "ocf:heartbeat:$SERVICE" binary="/usr/sbin/mysqld" \
  config="/etc/mysql/my.cnf" datadir="/u01/mysql/data" pid="/var/run/mysqld/mysqld.pid" \
  socket="/var/run/mysqld/mysqld.sock"  \
  additional_parameters="--bind-address=172.56.0.91" \
  op start timeout=60s op stop timeout=60s  op monitor interval=20s timeout=30s 

# Create a resource group to marshal the above resources
# g_mysql is the group and contains p_fs_mysql p_ip_mysql p_mysql

pcs -f $CONFIG resource group add  "g_$SERVICE" "p_fs_$SERVICE" "p_ip_$SERVICE" "p_$SERVICE"

# Constraints
#    Colocation
#pcs constraint colocation add g_mysql with ms_drbd_mysql-clone with-rsc-role=Master
pcs -f $CONFIG constraint colocation add "g_$SERVICE" with "ms_drbd_$SERVICE-clone" with-rsc-role=Master --force
#    Order

pcs -f $CONFIG constraint order promote "ms_drbd_$SERVICE-clone" then start "g_$SERVICE" kind=Mandatory --force


#
#pcs resource enable mysql_service
#
# Push the configuration
#pcs cluster cib-push mysql
