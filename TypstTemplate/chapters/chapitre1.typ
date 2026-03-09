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