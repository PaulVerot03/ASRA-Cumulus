M1
    if1 : host-only
    if2 : ls3
    if3 : ls6
M2
    if1 : host-only
    if2 : ls4
    if3 : ls5
SW1
    if1 : host-only
    if2 : ls1
    if3 : ls3
    if4 : ls5
SW2
    if1 : host-only
    if2 : ls2
    if3 : ls4
    if4 : ls6
SW3
    if1 : host-only
    if2 : ls1
    if3 : ls2

machine 
```bash 
auto bond0
iface bond0 inet static
    address 192.168.1.1/24
    bond-slaves ens36 ens37
    bond-mode 4
    bond-miimon 100
    bond-lacp-rate 1
    
auto ens36 
iface ens36 inet manual 
    bond-master bond0
    
auto ens37 
iface ens37 inet manual 
    bond-master bond0
```

dual-homed

CLAG → Cumulus Linux MLAG
Bonding sur les clients

Switch 1
```bash
net add bond peerlink bond slaves swp4,swp5

net add clag peer sys-mac 44:38:39:FF:FF:FF
net add clag peer interface peerlink
net add clag peer primary

#M1
net add bond bond-m1 bond slaves swp2
net add bond bond-m1 clag id 1

#M2
net add bond bond-m2 bond slaves swp3
net add bond bond-m2 clag id 2

net pending
net commit
```
https://docs.nvidia.com/networking-ethernet-software/cumulus-linux-59/Layer-2/Multi-Chassis-Link-Aggregation-MLAG/

Switch 2
```bash
net add bond peerlink bond slaves swp4,swp5

net add clag peer sys-mac 44:38:39:FF:FF:FF
net add clag peer interface peerlink
net add clag peer primary

#M1
net add bond bond-m1 bond slaves swp3
net add bond bond-m1 clag id 1

#M2
net add bond bond-m2 bond slaves swp2
net add bond bond-m2 clag id 2

net pending
net commit
```

sw1
```bash
net add bond peerlink bond slaves swp4,swp5
net add clag peer sys-mac 44:38:39:FF:FF:FF interface swp4,swp5 primary

net add clag peer backup-ip 192.168.59.151 vrf mgmt

net add bond bond-m1 bond slaves swp2
net add bond bond-m1 clag id 1
net add bond bond-m2 bond slaves swp3
net add bond bond-m2 clag id 2

net pending
net commit
```
net add clag peer sys-mac 44:38:39:FF:FF:FF interface swp4,swp5 secondary backup-ip 192.168.59.152 vrf mgmt


sw2
```bash
net add bond peerlink bond slaves swp4,swp5
net add clag peer sys-mac 44:38:39:FF:FF:FF interface swp4,swp5 secondary

net add clag peer backup-ip 192.168.59.152 vrf mgmt

net add bond bond-m1 bond slaves swp3
net add bond bond-m1 clag id 1
net add bond bond-m2 bond slaves swp2
net add bond bond-m2 clag id 2

net pending
net commit
```


```bash
ERROR: --- /etc/network/interfaces	2021-01-30 17:00:25.000000000 +0000
+++ /run/nclu/ifupdown2/interfaces.tmp	2026-03-12 16:02:57.897192366 +0000
@@ -5,15 +5,54 @@
 
 # The loopback network interface
 auto lo
 iface lo inet loopback
 
 # The primary network interface
 auto eth0
 iface eth0 inet dhcp
     vrf mgmt
 
+auto swp2
+iface swp2
+
+auto swp3
+iface swp3
+
+auto swp4
+iface swp4
+
+auto swp5
+iface swp5
+
+auto bond-m1
+iface bond-m1
+    bond-slaves swp3
+    clag-id 1
+
+auto bond-m2
+iface bond-m2
+    bond-slaves swp2
+    clag-id 2
+
+auto bridge
+iface bridge
+    bridge-ports peerlink
+    bridge-vlan-aware yes
+
 auto mgmt
 iface mgmt
     address 127.0.0.1/8
     address ::1/128
     vrf-table auto
+
+auto peerlink
+iface peerlink
+    bond-slaves swp4 swp5
+
+auto peerlink.4094
+iface peerlink.4094
+    clagd-backup-ip 192.168.59.152 vrf mgmt
+    clagd-peer-ip linklocal
+    clagd-priority 2000
+    clagd-sys-mac 44:38:39:FF:FF:FF
+



net add/del commands since the last "net commit"
================================================

User     Timestamp                   Command
-------  --------------------------  -----------------------------------------------------------------------------------------------------------
cumulus  2026-03-12 16:01:50.760742  net add bond peerlink bond slaves swp4,swp5
cumulus  2026-03-12 16:02:41.063068  net add clag peer sys-mac 44:38:39:FF:FF:FF interface swp4,swp5 secondary backup-ip 192.168.59.152 vrf mgmt
cumulus  2026-03-12 16:02:45.719488  net add bond bond-m1 bond slaves swp3
cumulus  2026-03-12 16:02:48.706203  net add bond bond-m1 clag id 1
cumulus  2026-03-12 16:02:51.452400  net add bond bond-m2 bond slaves swp2
cumulus  2026-03-12 16:02:54.671611  net add bond bond-m2 clag id 2



"/sbin/ifreload -a" failed:
error: bond-m1: netlink: swp3: cannot set link swp3 protodown on: operation failed with 'Operation not supported' (95)
error: cmd '/bin/ip link set swp3 protodown on' failed: returned 2
error: bond-m2: netlink: swp2: cannot set link swp2 protodown on: operation failed with 'Operation not supported' (95)
error: cmd '/bin/ip link set swp2 protodown on' failed: returned 2
Command '['/sbin/ifreload', '-a']' returned non-zero exit status 1

"net commit" failed for ifupdown2.  All changes will remain in "net pending".
```


FIX : SUDO net commit



====================================================================================================================
19 mars

switch 1
```bash
net add bond peerlink interfaces swp4,swp5
net add interface peerlink clag peer-ip 169.254.1.2 secondary-ip 192.168.59.161

net add bond bond-m1 interfaces swp1
net add bond bond-m1 clag id 10
net add bond bond-m1 bridge access 10

net add interface swp3 bridge trunk allowed 10,20

net pending
net commit
```

switch 2
```bash
net add bond peerlink interfaces swp4,swp5
net add interface peerlink clag peer-ip 169.254.1.1 secondary-ip 192.168.59.160

net add bond bond-m1 interfaces swp1
net add bond bond-m1 clag id 10
net add bond bond-m1 bridge access 10

net add interface swp3 bridge trunk allowed 10,20

net pending
net commit
```

switch 3
```bash
net add vlan 10 ip address 192.168.1.254/24
net add vlan 20 ip address 192.168.2.254/24

net add interface swp1 bridge trunk allowed 10,20
net add interface swp2 bridge trunk allowed 10,20
net pending
net commit
```


Machines 
```bash 
sudo nmcli con add type bond con-name bond0 ifname bond0 bond.options "mode=802.3ad,miimon=100"
sudo nmcli con add type ethernet con-name bond0-port1 ifname ens36 master bond0
sudo nmcli con add type ethernet con-name bond0-port2 ifname ens37 master bond0
```



```bash 
# ==========================================
# CONFIGURATION DU SWITCH 1 (Accès - MLAG Primaire)
# ==========================================

# 1. Création des VLANs
net add vlan 10,20

# 2. Configuration du Peerlink (Lien ISL entre SW1 et SW2)
net add bond peerlink interfaces swp4,swp5
net add clag peer sys-mac 44:38:39:ff:00:01
net add clag peer priority 4096
net add interface peerlink clag peer-ip link-local

# 3. Configuration de l'agrégation vers la Machine 1 (VLAN 10)
net add bond bond-m1 interfaces swp1
net add bond bond-m1 clag id 10
net add bond bond-m1 bridge access 10

# 4. Configuration de l'agrégation vers la Machine 2 (VLAN 20)
net add bond bond-m2 interfaces swp2
net add bond bond-m2 clag id 20
net add bond bond-m2 bridge access 20

# 5. Configuration du Trunk vers le Switch 3
net add interface swp3 bridge trunk allowed 10,20

# 6. Application de la configuration
net pending
net commit


# ==========================================
# CONFIGURATION DU SWITCH 2 (Accès - MLAG Secondaire)
# ==========================================

# 1. Création des VLANs
net add vlan 10,20

# 2. Configuration du Peerlink
net add bond peerlink interfaces swp4,swp5
# La MAC doit être EXACTEMENT la même que sur SW1
net add clag peer sys-mac 44:38:39:ff:00:01 
net add clag peer priority 8192
net add interface peerlink clag peer-ip link-local

# 3. Configuration de l'agrégation vers la Machine 1 (VLAN 10)
# Le clag id doit être le même que sur SW1
net add bond bond-m1 interfaces swp1
net add bond bond-m1 clag id 10
net add bond bond-m1 bridge access 10

# 4. Configuration de l'agrégation vers la Machine 2 (VLAN 20)
# Le clag id doit être le même que sur SW1
net add bond bond-m2 interfaces swp2
net add bond bond-m2 clag id 20
net add bond bond-m2 bridge access 20

# 5. Configuration du Trunk vers le Switch 3
net add interface swp3 bridge trunk allowed 10,20

# 6. Application de la configuration
net pending
net commit


# ==========================================
# CONFIGURATION DU SWITCH 3 (Distribution/Core - L3)
# ==========================================

# 1. Création des interfaces de routage (SVI)
net add vlan 10 ip address 192.168.1.254/24
net add vlan 20 ip address 192.168.2.254/24

# 2. Configuration des Trunks vers SW1 et SW2
# STP bloquera automatiquement un des deux liens pour éviter une boucle L2
net add interface swp1 bridge trunk allowed 10,20
net add interface swp2 bridge trunk allowed 10,20

# 3. Application de la configuration
net pending
net commit
```