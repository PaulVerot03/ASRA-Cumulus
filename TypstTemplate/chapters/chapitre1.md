```txt
M1
  adapter 1 : NAT
  adapter 2 : lan segment 4
M2
  adapter 1 : NAT
  adapter 2 : lan segment 2
NFS
  adapter 1 : NAT
  adapter 2 : lan segment 5
  adapter 3 : lan segment 6
SW1
  adapter 1 : host only 
  adapter 2 : lan segment 3
  adapter 3 : lan segment 4
  adapter 4 : lan segment 5
  adapter 5 : lan segment 6

SW2
  adapter 1 : host only 
  adapter 2 : lan segment 1
  adapter 3 : lan segment 2
SW3
  adapter 1 : host only 
  adapter 2 : lan segment 1
  adapter 3 : lan segment 3
```

SW1
```bash
net add hostname sw1
net add interface swp1,swp2,swp3,swp4
ifreload -a
net commit 

net add bridge bridge ports swp1,swp2,swp3,swp4
net add bridge bridge vlan-aware

net add interface swp2 bridge access 20
net add interface swp3, swp4 bridge access 40

net add interface swp1 bridge trunk vlans 20, 40
net commit
```

SW2
```bash
net add hostname sw2
net add interface swp1,swp2
ifreload -a
net commit 

net add bridge bridge ports swp1,swp2
net add bridge bridge vlan-aware

net add interface swp1, swp2 bridge access 30
net commit 
```

SW3
```bash
net add hostname sw3
net add interface swp1,swp2
ifreload -a
net commit 

net add bridge bridge ports swp1,swp2
net add bridge bridge vlan-aware

net add interface swp2 bridge trunk vlans 10,20 
net add interface swp1 bridge trunk vlans 20,30 

net add vlan 10 ip address 192.168.10.1/24
net add vlan 20 ip address 192.168.20.1/24
net add vlan 30 ip address 192.168.30.1/24
```

FIREWALL
```bash /etc/cumulus/acl/policy.d/50_custom.rules 
[iptables]
-A FORWARD -p tcp -s 192.168.30.3 -d 192.168.10.3 -j DROP
-A FORWARD -p tcp -s 192.168.10.3 -d 192.168.30.3 -j DROP

-A FORWARD -p icmp -s 192.168.30.3 -d 192.168.10.3 -j DROP
-A FORWARD -p icmp -s 192.168.10.3 -d 192.168.30.3 -j DROP

```


Sur NFS : 
bond sur les cartes, active-backup 
```bash
auto bond0
iface bond0 inet static
    address 192.168.20.3/24
    gateway 192.168.20.1
    bond-slaves ens36 ens37
    bond-mode active-backup
    bond-miimon 100
    bond-primary eth1

auto ens36
iface ens36 inet manual
    bond-master bond0

auto ens37
iface ens37 inet manual
    bond-master bond0
```

Pour NFS :
  packages `nfs-kernel-server`, `nfs-common`

create files : mkdir 
```bash
#Serveur NFS
mkdir /machine1
mkdir /machine2

chown nobody:nogroup /machine1 /machine2
chmod 777 /machine1 /machine2

nvim /etc/exports :
    /machine1 192.168.10.0/24(rw,sync,no_subtree_check)
    /machine2 192.168.30.0/24(rw,sync,no_subtree_check)


exportfs -a 

systemctl restart nfs-kernel-server
```

```bash
#Sur la machine 1  
mkdir /mnt/backup_m1
mount -t nfs -o vers=4 192.168.20.3:/machine1 /mnt/backup_m1

```
On peut ensuite tester que le transfer fonctionne en créant un fichier dans `/mnt/backup_m1` et vérifier qu'il apparait bien sur le serveur NFS
```bash 
#! Machine 1 
touch /mnt/backup_m1/test.ms

#! Serveur NFS 
ls -la /machine1
    VOIR CAP
```

On peut aussi verifier que l'on ne peut pas monter le mauvais share si on ne fait pas partie du réseau désigné : 

```bash
#! Machine 2 
mkdir /mnt/backup_m2
mount -t nfs -o vers=4 192.168.20.3:/machine1 /mnt/backup_m2
voir cap
```

Comme attendu, la machine 2 ne peut se connecter que sur son partage et pas à celui dédié à la machine 1. 




====================================================================================


SWITCH 1
```bash
net add hostname sw1
net add bridge bridge ports swp1,swp2,swp3,swp4
net add bridge bridge vlan-aware
net add interface swp2 bridge access 10
net add interface swp3,swp4 bridge access 20
net add interface swp1 bridge trunk vlans 10,20
net commit
```

```bash
cumulus@sw1:mgmt:~$ net show interface 
State  Name    Spd  MTU    Mode       LLDP        Summary
-----  ------  ---  -----  ---------  ----------  ---------------------------
UP     lo      N/A  65536  Loopback               IP: 127.0.0.1/8
       lo                                         IP: ::1/128
UP     eth0    10G  1500   Mgmt       sw2 (eth0)  Master: mgmt(UP)
       eth0                                       IP: 192.168.85.142/24(DHCP)
UP     swp1    1G   9216   Trunk/L2   sw3 (swp2)  Master: bridge(UP)
UP     swp2    1G   9216   Access/L2              Master: bridge(UP)
UP     swp3    1G   9216   Access/L2              Master: bridge(UP)
UP     swp4    1G   9216   Access/L2              Master: bridge(UP)
UP     bridge  N/A  9216   Bridge/L2
UP     mgmt    N/A  65536  VRF                    IP: 127.0.0.1/8
       mgmt                                       IP: ::1/128

cumulus@sw1:mgmt:~$ net show bridge vlan 

Interface  VLAN  Flags
---------  ----  ---------------------
swp1          1  PVID, Egress Untagged
             10
             20
swp2         10  PVID, Egress Untagged
swp3         20  PVID, Egress Untagged
swp4         20  PVID, Egress Untagged
```


SWITCH 2

```bash 
net add hostname sw2
net add bridge bridge ports swp1,swp2
net add bridge bridge vlan-aware
net add interface swp2 bridge access 30
net add interface swp1 bridge trunk vlans 20,30
net commit
```

```bash 
cumulus@sw2:mgmt:~$ net show interface 
State  Name    Spd  MTU    Mode       LLDP        Summary
-----  ------  ---  -----  ---------  ----------  ---------------------------
UP     lo      N/A  65536  Loopback               IP: 127.0.0.1/8
       lo                                         IP: ::1/128
UP     eth0    10G  1500   Mgmt       sw1 (eth0)  Master: mgmt(UP)
       eth0                                       IP: 192.168.85.141/24(DHCP)
UP     swp1    1G   9216   Trunk/L2   sw3 (swp1)  Master: bridge(UP)
UP     swp2    1G   9216   Access/L2              Master: bridge(UP)
UP     bridge  N/A  9216   Bridge/L2
UP     mgmt    N/A  65536  VRF                    IP: 127.0.0.1/8
       mgmt                                       IP: ::1/128

cumulus@sw2:mgmt:~$ net show interface 
State  Name    Spd  MTU    Mode       LLDP        Summary
-----  ------  ---  -----  ---------  ----------  ---------------------------
UP     lo      N/A  65536  Loopback               IP: 127.0.0.1/8
       lo                                         IP: ::1/128
UP     eth0    10G  1500   Mgmt       sw1 (eth0)  Master: mgmt(UP)
       eth0                                       IP: 192.168.85.141/24(DHCP)
UP     swp1    1G   9216   Trunk/L2   sw3 (swp1)  Master: bridge(UP)
UP     swp2    1G   9216   Access/L2              Master: bridge(UP)
UP     bridge  N/A  9216   Bridge/L2
UP     mgmt    N/A  65536  VRF                    IP: 127.0.0.1/8
       mgmt                                       IP: ::1/128

cumulus@sw2:mgmt:~$ net show bridge vlan 

Interface  VLAN  Flags
---------  ----  ---------------------
swp1          1  PVID, Egress Untagged
             20
             30
swp2         30  PVID, Egress Untagged
```


SWITCH 3 

```bash 
net add hostname sw3

net add bridge bridge ports swp1,swp2
net add bridge bridge vlan-aware

net add interface swp2 bridge trunk vlans 10,20  
net add interface swp1 bridge trunk vlans 20,30  

net add vlan 10 ip address 192.168.10.1/24
net add vlan 20 ip address 192.168.20.1/24
net add vlan 30 ip address 192.168.30.1/24
net commit
```

```bash
cumulus@sw3:mgmt:~$ net show interface 
State  Name    Spd  MTU    Mode          LLDP        Summary
-----  ------  ---  -----  ------------  ----------  ---------------------------
UP     lo      N/A  65536  Loopback                  IP: 127.0.0.1/8
       lo                                            IP: ::1/128
UP     eth0    10G  1500   Mgmt          sw1 (eth0)  Master: mgmt(UP)
       eth0                                          IP: 192.168.85.140/24(DHCP)
UP     swp1    1G   9216   Trunk/L2      sw2 (swp1)  Master: bridge(UP)
UP     swp2    1G   9216   Trunk/L2      sw1 (swp1)  Master: bridge(UP)
UP     bridge  N/A  9216   Bridge/L2
UP     mgmt    N/A  65536  VRF                       IP: 127.0.0.1/8
       mgmt                                          IP: ::1/128
UP     vlan10  N/A  9216   Interface/L3              IP: 192.168.10.1/24
UP     vlan20  N/A  9216   Interface/L3              IP: 192.168.20.1/24
UP     vlan30  N/A  9216   Interface/L3              IP: 192.168.30.1/24

cumulus@sw3:mgmt:~$ net show bridge vlan 

Interface  VLAN  Flags
---------  ----  ---------------------
swp1          1  PVID, Egress Untagged
             20
             30
swp2          1  PVID, Egress Untagged
             10
             20
bridge       10
             20
             30
```









backup typst

============================================================

#import "../classic-evry-report/template/setup/macros.typ": *

= Partage Réseau NFS


```yaml
---
- name: machine1
 hosts: debian1
 tasks:
   - name: vérif paquet
     apt:
       name: nfs-common ifenslave tcpdump
       state: present
       update_cache: yes
       force_apt_get: yes
       autoclean: yes
       autoremove: yes
   - name: set ip
     copy: 
      dest: /etc/network/interfaces.d 
      content: | 
        auto ens33 
        iface ens33 inet static 
          address 192.168.20.3 
          gateway 192.168.20.1
```

```yaml
---
- name: machine2
 hosts: debian2
 tasks:
   - name: vérif paquet
     apt:
       name: nfs-common ifenslave tcpdump
       state: present
       update_cache: yes
       force_apt_get: yes
       autoclean: yes
       autoremove: yes
   - name: set ip
     copy: 
      dest: /etc/network/interfaces.d 
      content: | 
        auto ens33 
        iface ens33 inet static 
          address 192.168.30.3 
          gateway 192.168.30.1
```

SW1
```bash
net add hostname sw1
net add interface swp1,swp2,swp3,swp4
ifreload -a
net commit 

net add bridge bridge ports swp1,swp2,swp3,swp4
net add bridge bridge vlan-aware

net add interface swp2 bridge access 20
net add interface swp3, swp4 bridge access 40

net add interface swp1 bridge trunk vlans 20, 40
net commit
```
```bash  
cumulus@sw1:mgmt:~$ net show interface 
State  Name    Spd  MTU    Mode       LLDP        Summary
-----  ------  ---  -----  ---------  ----------  ---------------------------
UP     lo      N/A  65536  Loopback               IP: 127.0.0.1/8
       lo                                         IP: ::1/128
UP     eth0    10G  1500   Mgmt       sw2 (eth0)  Master: mgmt(UP)
       eth0                                       IP: 192.168.85.142/24(DHCP)
UP     swp1    1G   9216   Trunk/L2               Master: bridge(UP)
UP     swp2    1G   9216   Access/L2              Master: bridge(UP)
UP     swp3    1G   9216   Access/L2              Master: bridge(UP)
UP     swp4    1G   9216   Access/L2              Master: bridge(UP)
UP     bridge  N/A  9216   Bridge/L2
UP     mgmt    N/A  65536  VRF                    IP: 127.0.0.1/8
       mgmt                                       IP: ::1/128

```

SW2
```bash
net add hostname sw2
net add interface swp1,swp2
ifreload -a
net commit 

net add bridge bridge ports swp1,swp2
net add bridge bridge vlan-aware

net add interface swp1, swp2 bridge access 30
net commit 
```
```bash
cumulus@sw2:mgmt:~$ net show interface 
State  Name    Spd  MTU    Mode       LLDP        Summary
-----  ------  ---  -----  ---------  ----------  ---------------------------
UP     lo      N/A  65536  Loopback               IP: 127.0.0.1/8
       lo                                         IP: ::1/128
UP     eth0    10G  1500   Mgmt       sw3 (eth0)  Master: mgmt(UP)
       eth0                                       IP: 192.168.85.141/24(DHCP)
UP     swp1    1G   9216   Access/L2              Master: bridge(UP)
UP     swp2    1G   9216   Access/L2              Master: bridge(UP)
UP     bridge  N/A  9216   Bridge/L2
UP     mgmt    N/A  65536  VRF                    IP: 127.0.0.1/8
       mgmt                                       IP: ::1/128
```

SW3
```bash
net add hostname sw3
net add interface swp1,swp2
ifreload -a
net commit 

net add bridge bridge ports swp1,swp2
net add bridge bridge vlan-aware

net add interface swp2 bridge trunk vlans 10,20 
net add interface swp1 bridge trunk vlans 20,30 

net add vlan 10 ip address 192.168.10.1/24
net add vlan 20 ip address 192.168.20.1/24
net add vlan 30 ip address 192.168.30.1/24
```
```bash
cumulus@sw3:mgmt:~$ net show interface 
State  Name    Spd  MTU    Mode          LLDP        Summary
-----  ------  ---  -----  ------------  ----------  ---------------------------
UP     lo      N/A  65536  Loopback                  IP: 127.0.0.1/8
       lo                                            IP: ::1/128
UP     eth0    10G  1500   Mgmt          sw1 (eth0)  Master: mgmt(UP)
       eth0                                          IP: 192.168.85.140/24(DHCP)
UP     swp1    1G   9216   Trunk/L2      sw2 (swp1)  Master: bridge(UP)
UP     swp2    1G   9216   Trunk/L2      sw1 (swp1)  Master: bridge(UP)
UP     bridge  N/A  9216   Bridge/L2
UP     mgmt    N/A  65536  VRF                       IP: 127.0.0.1/8
       mgmt                                          IP: ::1/128
UP     vlan10  N/A  9216   Interface/L3              IP: 192.168.10.1/24
UP     vlan20  N/A  9216   Interface/L3              IP: 192.168.20.1/24
UP     vlan30  N/A  9216   Interface/L3              IP: 192.168.30.1/24
```





M1
  adapter 1 : NAT
  adapter 2 : lan segment 4
M2
  adapter 1 : NAT
  adapter 2 : lan segment 2
NFS
  adapter 1 : NAT
  adapter 2 : lan segment 5
  adapter 3 : lan segment 6
SW1
  adapter 1 : host only 
  adapter 2 : lan segment 3
  adapter 3 : lan segment 4
  adapter 4 : lan segment 5
  adapter 5 : lan segment 6

SW2
  adapter 1 : host only 
  adapter 2 : lan segment 1
  adapter 3 : lan segment 2
SW3
  adapter 1 : host only 
  adapter 2 : lan segment 1
  adapter 3 : lan segment 3




```bash
cumulus@sw1:mgmt:~$ net show bridge vlan 

Interface  VLAN  Flags
---------  ----  ---------------------
swp1          1  PVID, Egress Untagged
             10
             20
swp2         20  PVID, Egress Untagged
swp3         10  PVID, Egress Untagged
swp4         10  PVID, Egress Untagged



cumulus@sw2:mgmt:~$ net show bridge vlan 

Interface  VLAN  Flags
---------  ----  ---------------------
swp1          1  PVID, Egress Untagged
             20
             30
swp2         30  PVID, Egress Untagged


cumulus@sw3:mgmt:~$ net show bridge vlan 

Interface  VLAN  Flags
---------  ----  ---------------------
swp1          1  PVID, Egress Untagged
             20
             30
swp2          1  PVID, Egress Untagged
             10
             20
bridge       10
             20
             30
```


```bash
cumulus@sw3:mgmt:~$ net add acl ipv4 rule1 drop tcp source-ip 192.168.30.3/24 source-port any dest-ip 192.168.10.3/24 dest-port any 
NOTE: 192.168.30.3/24 was converted to 192.168.30.0/24
NOTE: 192.168.10.3/24 was converted to 192.168.10.0/24 
cumulus@sw3:mgmt:~$ net add acl ipv4 rule1 drop tcp source-ip 192.168.10.3/24 source-port any dest-ip 192.168.30.3/24 dest-port any 
NOTE: 192.168.10.3/24 was converted to 192.168.10.0/24
NOTE: 192.168.30.3/24 was converted to 192.168.30.0/24 
cumulus@sw3:mgmt:~$ net pending
--- /var/lib/cumulus/nclu/nclu_acl.conf	2021-01-21 20:19:16.000000000 +0000
+++ /run/nclu/accesslist/nclu_acl.conf	2026-03-09 19:42:48.612048169 +0000
@@ -0,0 +1,3 @@
+acl ipv4 rule1 priority 10 drop tcp source-ip 192.168.30.0/24 source-port any dest-ip 192.168.10.0/24 dest-port any
+acl ipv4 rule1 priority 20 drop tcp source-ip 192.168.10.0/24 source-port any dest-ip 192.168.30.0/24 dest-port any
+



net add/del commands since the last "net commit"
================================================

User     Timestamp                   Command
-------  --------------------------  ---------------------------------------------------------------------------------------------------------------
cumulus  2026-03-09 19:42:19.602364  net add acl ipv4 rule1 drop tcp source-ip 192.168.30.3/24 source-port any dest-ip 192.168.10.3/24 dest-port any
cumulus  2026-03-09 19:42:48.612473  net add acl ipv4 rule1 drop tcp source-ip 192.168.10.3/24 source-port any dest-ip 192.168.30.3/24 dest-port any
cumulus@sw3:mgmt:~$ net commit
--- /var/lib/cumulus/nclu/nclu_acl.conf	2021-01-21 20:19:16.000000000 +0000
+++ /run/nclu/accesslist/nclu_acl.conf	2026-03-09 19:42:48.612048169 +0000
@@ -0,0 +1,3 @@
+acl ipv4 rule1 priority 10 drop tcp source-ip 192.168.30.0/24 source-port any dest-ip 192.168.10.0/24 dest-port any
+acl ipv4 rule1 priority 20 drop tcp source-ip 192.168.10.0/24 source-port any dest-ip 192.168.30.0/24 dest-port any
+



net add/del commands since the last "net commit"
================================================

User     Timestamp                   Command
-------  --------------------------  ---------------------------------------------------------------------------------------------------------------
cumulus  2026-03-09 19:42:19.602364  net add acl ipv4 rule1 drop tcp source-ip 192.168.30.3/24 source-port any dest-ip 192.168.10.3/24 dest-port any
cumulus  2026-03-09 19:42:48.612473  net add acl ipv4 rule1 drop tcp source-ip 192.168.10.3/24 source-port any dest-ip 192.168.30.3/24 dest-port any

```
WORKING
```bash /etc/cumulus/acl/policy.d/50_custom.rules 
[iptables]
-A FORWARD -p tcp -s 192.168.30.3 -d 192.168.10.3 -j DROP
-A FORWARD -p tcp -s 192.168.10.3 -d 192.168.30.3 -j DROP

-A FORWARD -p icmp -s 192.168.30.3 -d 192.168.10.3 -j DROP
-A FORWARD -p icmp -s 192.168.10.3 -d 192.168.30.3 -j DROP

```


Sur NFS : 
bond sur les cartes, active-backup 

Pour NFS :
  packages __ 
create files : mkdir 


mount FS : 

check transfer :

