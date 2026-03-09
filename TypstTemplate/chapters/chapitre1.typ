#import "../classic-evry-report/template/setup/macros.typ": *
#let blue(body) = {
  set text(fill: rgb("#003b69") )
  body
}
= Partage Réseau NFS
#figure(
  image("../figures/1/maquete1.drawio.png", width: 80%)
)

#strong[Résumé des contraintes et des demandes:]

- Les Switchs 1 et 2 n'utilisent que des fonctions de niveau 2 
- Le Switch 3 peut utiliser des fonctions de niveau 3 
- Les machines 1 et 2 doivent être isolées
- Les machines 1 et 2 doivent avoir accès au serveur NFS 
- Les machines 1 et 2 doivent pour transmetre via NFS au serveur, uniquement dans leur dossiers respectifs
- Tolérance à la panne sur les interfaces du serveur NFS

\
\

#strong[Plan :]

Pour assurer l'isolation des machines, on va les placer dans des VLAN différents et interdire toute communication entres les réseau avec des règles de parefeur sur le Switch-3.
\ \
Pour garantir la disponnibilité des lien sur le serveur NFS, on va placer deux interfaces sur le serveur et les connecter au Switch-1 en LACP mode #blue[actif-backup]. Ainsi, si le lien actif tombe, le deuxième prendra le relais. 
\ \
Pour le serveur NFS, il faut configurer `nfs-kernel-server` pour créer des partages réseau et définir les modalités de montage pour les clients. 

\ \


#strong[Mise en Place :] \
On a donc besoin de mettre en place 3 VLAN, un parefeu, une aggrégation de lien et un serveur NFS.

#smallcaps[Sur #blue[VMware]:]\
```txt
M1
  adapter 1 : host only
  adapter 2 : lan segment 4
M2
  adapter 1 : host only
  adapter 2 : lan segment 2
NFS
  adapter 1 : host only
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
\ 

#smallcaps[Sur les machines :] \

Configuration des VLAN : \
#underline[Switch 1]
```bash
net add hostname sw1
net add bridge bridge ports swp1,swp2,swp3,swp4
net add bridge bridge vlan-aware
net add interface swp2 bridge access 10
net add interface swp3,swp4 bridge access 20
net add interface swp1 bridge trunk vlans 10,20
net commit
```
\ 

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

\
#underline[Switch 2]
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

cumulus@sw2:mgmt:~$ net show bridge vlan 

Interface  VLAN  Flags
---------  ----  ---------------------
swp1          1  PVID, Egress Untagged
             20
             30
swp2         30  PVID, Egress Untagged
```

\
#underline[Switch 3] 

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
\
Ces commandes servent à : 

+ `net add hostname sw1`
  - Définit le nom d'hôte du switch

+ `net add bridge bridge ports swp1,swp2,swp3,swp4`
  - Ajoute les interfaces physiques (swp1 à swp4) au bridge principal

+ `net add bridge bridge vlan-aware`
  - Active le mode "VLAN-aware" du bridge pour permettre la gestion des VLANs

+ `net add interface swp2 bridge access 10` \ `net add interface swp3,swp4 bridge access 20`
  - Configure les interfaces en mode accès:
  - swp2 appartient au VLAN 10
  - swp3 et swp4 appartiennent au VLAN 20

+ net add interface swp1 bridge trunk vlans 10,20
  - Configure swp1 en mode trunk pour transporter les VLANs 10 et 20

+ `net add vlan 10 ip address 192.168.10.1/24` \ `net add vlan 20 ip address 192.168.20.1/24`  \ ` net add vlan 30 ip address 192.168.30.1/24`
  - Crée les interfaces VLAN et assigne les adresses IP de gestion
  - VLAN 10: 192.168.10.0/24
  - VLAN 20: 192.168.20.0/24
  - VLAN 30: 192.168.30.0/24

+ `net commit`
  - Valide et applique toutes les modifications précédentes, analogue à un commit sur Git

\ \ \
Configuration des IP sur les machines :  \
Dans le fichier ```bash /etc/network/interfaces ``` \  
#underline("Machine 1")
```bash 
auto ens36 
iface ens36 inet static 
  address 192.168.10.3/24
  gateway 192.168.10.1
```
#figure(
  image("../figures/1/10-3.png", width: 80%)
)

\

#underline("Machine 2")
```bash 
auto ens36 
iface ens36 inet static 
  address 192.168.30.3/24
  gateway 192.168.30.1
```
#figure(
  image("../figures/1/30-3.png", width: 80%)
)


#underline("Serveur NFS")
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

Ces commandes permètent de : 
- définir une adresse 
- définir une passerelle par défaut (les 3 machines ont comme passerelle par defaut le Switch-3)
- indiquer les interfaces membres de l'aggrégation
- indiquer le mode d'aggrégation
- indiquer le délai de bascule 
- indiquer l'interface principale (celle qui serai UP par défaut)
\

- indiquer que le maitre d'aggrégation aux interfaces

\
#figure(
  image("../figures/1/20-3.png", width: 80%)
)
On peut vérifier l'état du Bond : 
#figure(
  image("../figures/1/catbond.png", width: 50%)
)

\ \ \
Configuration du parefeu : \
#underline("Sur Switch-3 :")\

Dans ```bash /etc/cumulus/acl/policy.d/50_custom.rules 
[iptables]
-A FORWARD -p tcp -s 192.168.30.3 -d 192.168.10.3 -j DROP
-A FORWARD -p tcp -s 192.168.10.3 -d 192.168.30.3 -j DROP

-A FORWARD -p icmp -s 192.168.30.3 -d 192.168.10.3 -j DROP
-A FORWARD -p icmp -s 192.168.10.3 -d 192.168.30.3 -j DROP
``` 
\
Ces règles de parefeu ont pour but de détruire tout paquet entre les deux réseau, afin d'assurer l'isolation. \
On peut tester que les machines ne peuvent pas se ping : 
#figure(
  image("../figures/1/noping.png", width: 80%)
)
On peut voir que la Machine-2 peut communiquer avec le serveur NFS mais pas avec la Machine-1

\
Configuration du partage NFS :  \
#underline("Sur le serveur NFS :")\
\
```bash 
apt install nfs-kernel-server

mkdir /machine1
mkdir /machine2

chown nobody:nogroup /machine1 /machine2
chmod 777 /machine1 /machine2
```
\
\
dans `/etc/exports` : 
```bash
    /machine1 192.168.10.0/24(rw,sync,no_subtree_check)
    /machine2 192.168.30.0/24(rw,sync,no_subtree_check)
```
\
```bash
exportfs -a 
systemctl restart nfs-kernel-server
```
\ \
```bash
#! Machine-1  
mkdir /mnt/backup_m1
mount -t nfs -o vers=4 192.168.20.3:/machine1 /mnt/backup_m1
```
\ \
On peut ensuite tester que le transfer fonctionne en créant un fichier dans `/mnt/backup_m1` et vérifier qu'il apparait bien sur le serveur NFS
\
```bash 
#! Machine-1 
touch /mnt/backup_m1/test.ms

#! Serveur NFS 
ls -la /machine1
```
#figure(
  grid(
    image("../figures/1/touch.png", width: 80%),
    
    image("../figures/1/receive-touch.png", width: 80%)
  ), 
  caption: [En haut la création du fichier `test.ms` dans le dossier `/mnst/backup_m1` sur la Machine-1, en bas on constate la présence de `test.ms` dans `/machine1` sur le Serveur-NFS]
  
)
\
On peut aussi verifier que l'on ne peut pas monter le mauvais share si on ne fait pas partie du réseau désigné : 
\
```bash
#! Machine-2 
mkdir /mnt/backup_m2
mount -t nfs -o vers=4 192.168.20.3:/machine1 /mnt/backup_m2
```
#figure(
  image("../figures/1/connect-fail.png", width: 80%)
)
\ \
Comme attendu, la Machine-2 ne peut se connecter que sur son partage et pas à celui dédié à la Machine-1. 

