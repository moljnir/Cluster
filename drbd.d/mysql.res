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
