#import "../classic-evry-report/template/setup/macros.typ": *
#show heading : smallcaps
#let blue(body) = {
  set text(fill: rgb("#003b69") )
  body
}

= Tolérance de panne, couche "access"
== Résumé des contraintes et des demandes
- Assurer la tolérance aux pannes des commutateurs de la couche access (Switch-1 et Switch-2).
- En cas de défaillance de l'un des deux, le trafic entre Machine-1 et Machine-2 ne doit subir aucune interruption.
- Maximiser les performances : utilisation simultanée de tous les liens (actif/actif).
- Utilisation exclusive de Cumulus Linux ; aucun commutateur supplémentaire ; Machine-1 et Machine-2 ne peuvent pas être connectées directement à Switch-3.
#strong[Plan :] 
- Pour garantir la continuité de service en cas de panne d'un commutateur d'accès (Switch-1 ou Switch-2), chaque machine (Machine-1 et Machine-2) sera connectée physiquement et simultanément aux deux switchs via une agrégation de liens utilisant le protocole LACP (mode 802.3ad).
- Pour maximiser les performances en permettant l'utilisation simultanée de tous les liens (mode actif-actif), une architecture MLAG (Multi-Chassis Link Aggregation) sera déployée entre le Switch-1 et le Switch-2. Cela nécessite la mise en place d'un "Peer Link" entre ces deux commutateurs pour synchroniser leurs états et agir comme un seul commutateur logique vis-à-vis des machines.
- Pour assurer la redondance vers la couche supérieure, une agrégation de liens sera également configurée entre notre nouveau cluster MLAG (Switch-1 et 2) et le routeur de distribution (Switch-3).
- Ajouter des liens M1#sym.arrow.l.r.double S2 et M1#sym.arrow.l.r.double S1
- Ajouter un _PeerLink_  Switch-1 #sym.arrow.l.r.double Switch-2
- Agrégation de liens entre les Switch {1,2} #sym.arrow.l.r.double Switch-3

== Mise en place 
=== Sur VMware

#grid(
  columns: 2,
  list(
    [Machine-1 : connectée à LAN1 (vers SW1) et LAN2 (vers SW2)],
    [Machine-2 : connectée à LAN3 (vers SW1) et LAN4 (vers SW2)]
  ),
  list(
    [Switch-1 : connecté à LAN1, LAN3, LAN5, LAN6, LAN7],
    [Switch-2 : connecté à LAN2, LAN4, LAN5, LAN6, LAN8],
    [Switch-3 : connecté à LAN7, LAN8]
  )
)
=== Sur les machines
#strong[Sur les clients :]
Pour mettre en place l'agrégation de liens entre les clients et les switch, on utilise la configuration suivante sur les clients :
Machine-1
```bash
...
auto bond0
iface bond0 inet static
    address 192.168.1.1/24
    gateway 192.168.1.254
    bond-slaves ens34 ens35
    bond-mode 802.3ad
    bond-miimon 100
    bond-lacp-rate 1
```

Machine-2

```sh
...
auto bond0
iface bond0 inet static
    address 192.168.2.1/24
    gateway 192.168.2.254
    bond-slaves ens36 ens37
    bond-mode 802.3ad
    bond-miimon 100
    bond-lacp-rate 1

```
#line(stroke:(thickness:0.5pt, dash:"dashed"), length: 100%)
\
#underline[Sur les switch :] \
Switch-1:
```bash
auto swp1
iface swp1
auto swp2
iface swp2
auto swp3
iface swp3
auto swp4
iface swp4
auto swp5
iface swp5

auto peerlink
iface peerlink
    bond-slaves swp3 swp4
    bond-mode 802.3ad

auto peerlink.4094
iface peerlink.4094
    address 192.168.10.1/24
    clagd-peer-ip 192.168.10.2
    clagd-sys-mac 44:38:39:FF:FF:FF
    clagd-priority 1000
    clagd-backup-ip 192.168.244.155

auto bond-m1
iface bond-m1
    bond-slaves swp1
    clag-id 1
    bridge-access 10

auto bond-m2
iface bond-m2
    bond-slaves swp2
    clag-id 2
    bridge-access 20

auto bond-up
iface bond-up
    bond-slaves swp5
    clag-id 3

auto bridge
iface bridge
    bridge-ports peerlink bond-m1 bond-m2 bond-up
    bridge-vlan-aware yes
    bridge-vids 10 20


```
\
#underline[Switch-2] :
Seules les différences avec la configuration du Switch-1 sont montrées. 
```bash
...
auto peerlink.4094
iface peerlink.4094
    address 192.168.10.2/24
    clagd-peer-ip 192.168.10.1
    clagd-sys-mac 44:38:39:FF:FF:FF
    clagd-priority 2000
    clagd-backup-ip 192.168.244.154
...
```
\
#underline[Switch-3]:
```bash
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    vrf mgmt

auto mgmt
iface mgmt
    address 127.0.0.1/8
    vrf-table auto

auto bond-down
iface bond-down
    bond-slaves swp1 swp2
    bond-mode 802.3ad
    bond-miimon 100
    bond-lacp-rate 1

auto bridge
iface bridge
    bridge-ports bond-down
    bridge-vlan-aware yes
    bridge-vids 10 20

auto vlan10
iface vlan10
    vlan-id 10
    vlan-raw-device bridge
    address 192.168.1.254/24

auto vlan20
iface vlan20
    vlan-id 20
    vlan-raw-device bridge
    address 192.168.2.254/24
```
- clagd-peer-ip : Définit l'adresse IP du switch partenaire pour établir le canal de contrôle MLAG via le Peer Link.
- clagd-sys-mac : Adresse MAC système partagée par les deux commutateurs. C'est essentiel pour qu'ils apparaissent comme une seule et même entité logique (un seul switch) vis-à-vis des autres équipements (comme M1, M2 ou SW3).
- clagd-priority : Détermine le rôle du switch dans le cluster MLAG. Le switch avec la priorité la plus basse (ex: 1000 pour SW1 ) devient le "Primary", et l'autre (ex: 2000 pour SW2 ) devient le "Secondary".
- clagd-backup-ip : Définit une adresse IP de secours (généralement via le réseau de management Out-Of-Band). Si le Peer Link physique tombe, cette IP permet de vérifier si le switch partenaire est totalement en panne ou si c'est juste le lien qui est coupé, évitant ainsi le problème du "split-brain" (où les deux switchs penseraient être le maître).
- clag-id : Identifiant unique assigné à une interface agrégée (bond). Il doit être strictement identique sur les deux switchs pour qu'ils synchronisent correctement le même lien LACP vers un équipement tiers.

\
\
On peut vérifier l'état du bond avec `net show clag`.

#underline[Switch-1]:
```bash
cumulus@sw1:~$ net show clag
The peer is alive
    Our Priority, ID, and Role: 1000 00:0c:29:45:30:fe primary
   Peer Priority, ID, and Role: 2000 00:0c:29:64:76:96 secondary
         Peer Interface and IP: peerlink.4094 192.168.10.2
                    Backup IP: 192.168.244.155 (active)
                   System MAC: 44:38:39:ff:ff:ff


CLAG Interfaces
Our Interface    Peer Interface   CLAG Id  Conflicts  Proto-Down
-----------      ---------------  -------  ---------  ----------
bond-m1          bond-m1          1        -          -
bond-m2          bond-m2          2        -          -
bond-up          bond-up          3        -          -
```
#blue[The peer is alive] : le Peer Link entre Switch-1 et Switch2 est fonctionnel.

Switch-1 est bien primaire (priorité 1000), Switch-2 secondaire (priorité 2000).

Les trois agrégats (bond-m1, bond-m2, bond-up) sont synchronisés sans conflit (colonne Conflicts vide).

#blue[Backup IP active] : le canal de contrôle alternatif via le réseau de management est joignable.

#underline[Switch-2]:
```bash
cumulus@sw2:~$ net show clag
The peer is alive
    Our Priority, ID, and Role: 2000 00:0c:29:64:76:96 secondary
   Peer Priority, ID, and Role: 1000 00:0c:29:45:30:fe primary
         Peer Interface and IP: peerlink.4094 192.168.10.1
                    Backup IP: 192.168.244.154 (active)
                   System MAC: 44:38:39:ff:ff:ff


CLAG Interfaces
Our Interface    Peer Interface   CLAG Id  Conflicts  Proto-Down
-----------      ---------------  -------  ---------  ----------
bond-m1          bond-m1          1        -          -
bond-m2          bond-m2          2        -          -
bond-up          bond-up          3        -          -
```

On peut vérifier l'état du bond sur les clients avec `cat /proc/net/bondinf/bond0`.
```bash
Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer2 (0)
MII Status: up
MII Polling Interval (ms): 100


802.3ad info
LACP active: on
LACP rate: fast
Aggregator selection policy (ad_select): stable


Slave Interface: ens36
MII Status: up  |  Speed: 1000 Mbps  |  Link Failure Count: 0


Slave Interface: ens37
MII Status: up  |  Speed: 1000 Mbps  |  Link Failure Count: 0
```
Identique sur la Machine-2.

On peut vérifier que les machines peuvent se ping : 
```bash 
Machine1:~# ping 192.168.2.1
64 bytes from 192.168.2.1: icmp_seq=1 ttl=63 time=2.87 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=63 time=3.56 ms
64 bytes from 192.168.2.1: icmp_seq=3 ttl=63 time=2.51 ms
```

Le TTL de 63 confirme que le paquet est bien passé par un routeur.

== Test
En faisant une capture de trame avant de couper un switch, on peut oberver les communications entre les switchs:
#figure(
  image("../figures/3/wireshark1.png", width: 100%),
  caption: [communication normale entre les switch avant coupure]
)

On lance un ping Machine-1 #sym.arrow.l.r.double Machine-2, puis on éteint le Switch-1.

```bash
--- 192.168.2.1 ping statistics ---
99 packets transmitted, 97 received, 2.0202% packet loss, time 98255ms
rtt min/avg/max/mdev = 2.315/3.127/5.782/0.614 ms
```
\

Seulement 2 paquets perdus sur 99 lors de la coupure de Switch-1. Les 2 pertes correspondent au délai minimal de détection MII (bond-miimon 100 ms) et de basculement des flux du bond0 des machines vers le seul lien restant (ens37 vers Switch-2).
