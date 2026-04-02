#import "../classic-evry-report/template/setup/macros.typ": *

= Redondance de Routeurs
== Architecture
Pour répondre au besoin de tolérance de panne sur la couche distribution (niveau 3) tout en maintenant la redondance de la couche accès (niveau 2), nous avons ajouté un quatrième switch (Switch-4) pour servir de secour au Switch-3.

\
#strong[Plan :] 
- Pour pallier la perte du routeur principal (Switch 3) au niveau de la couche distribution, un quatrième commutateur (Switch 4) sera ajouté à l'architecture pour servir de solution de secours (failover) tout en conservant la redondance de la couche accès.
- Pour assurer une reprise instantanée du trafic sans nécessiter de délai de bascule ni d'élection de maître, le protocole VRR (Virtual Router Redundancy), spécifique à Cumulus Linux, sera implémenté sur le Switch 3 et le Switch 4.
- Pour permettre un routage "Active-Active", la configuration VRR fera en sorte que les Switchs 3 et 4 partagent les mêmes adresses IP et adresses MAC virtuelles (192.168.1.254 et 192.168.2.254 avec les MAC 00:00:5E:00:01:10 / 00:00:5E:00:01:20). Ainsi, si le Switch 3 tombe, le Switch 4 routera les paquets instantanément car il répondra déjà aux mêmes requêtes ARP.
- Pour lier ce nouveau routeur de secours à l'infrastructure existante, de nouvelles agrégations de liens (Trunk de secours en mode 802.3ad) seront configurées pour relier les Switchs 1 et 2 vers le Switch 4.

== Mise en Place
=== Sur VMware

#grid(
  columns: 2,
  list(
    [Machine-1 : LAN1 (vers SW1) et LAN2 (vers SW2)],
    [Machine-2 : LAN3 (vers SW1) et LAN4 (vers SW2)]
  ),
  list(
    [Switch 1 : LAN1, LAN3, LAN5, LAN6, LAN7],
    [Switch 2 : LAN2, LAN4, LAN5, LAN6, LAN8],
    [Switch 3 : LAN7, LAN8]
  )  // Ajouter le switch 4
)

=== Sur les Machines
#strong("Sur les Client")
#grid(
  columns: (1fr,1fr),
  gutter: 5pt,
  ```bash
  # Machine-1
  auto ens36
  iface ens36 inet manual
  auto ens37
  iface ens37 inet manual

  auto bond0
  iface bond0 inet static
  address 192.168.1.1/24
  gateway 192.168.1.254
  bond-slaves ens36 ens37
  bond-mode 802.3ad
  bond-miimon 100
  bond-lacp-rate 1```,
  ```bash
  #Machine-2
  auto ens36
  iface ens36 inet manual
  auto ens37
  iface ens37 inet manual

  auto bond0
  iface bond0 inet static
  address 192.168.2.1/24
  gateway 192.168.2.254
  bond-slaves ens36 ens37
  bond-mode 802.3ad
  bond-miimon 100
  bond-lacp-rate 1```
)
#strong("Sur les Switch :")
#grid(
  columns: (1fr,1fr),
  inset: 8pt,
  gutter: 3pt,
  fill: rgb("e4e4ea"),
  raw(("
    #Switch 1
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

    # Nouveau port vers le Switch 4
    auto swp6
    iface swp6

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
    clagd-backup-ip 192.168.244.170

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

    # Agrégat vers Switch 3
    auto bond-up
    iface bond-up
    bond-slaves swp5
    clag-id 3

    # Agrégat vers Switch 4 (Trunk de secours)
    auto bond-up-sw4
    iface bond-up-sw4
    bond-slaves swp6
    clag-id 4

    auto bridge
    iface bridge
    bridge-ports peerlink bond-m1 bond-m2 bond-up bond-up-sw4
    bridge-vlan-aware yes
    bridge-vids 10 20"),lang: "bash"),
  raw(("
    #Switch 2
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
    # Nouveau port vers le Switch 4
    auto swp6
    iface swp6

    auto peerlink
    iface peerlink
    bond-slaves swp3 swp4
    bond-mode 802.3ad

    auto peerlink.4094
    iface peerlink.4094
    address 192.168.10.2/24
    clagd-peer-ip 192.168.10.1
    clagd-sys-mac 44:38:39:FF:FF:FF
    clagd-priority 2000
    clagd-backup-ip 192.168.244.169

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

    # Agrégat vers Switch 3
    auto bond-up
    iface bond-up
    bond-slaves swp5
    clag-id 3

    # Agrégat vers Switch 4 (Trunk de secours)
    auto bond-up-sw4
    iface bond-up-sw4
    bond-slaves swp6
    clag-id 4

    auto bridge
    iface bridge
    bridge-ports peerlink bond-m1 bond-m2 bond-up bond-up-sw4
    bridge-vlan-aware yes
    bridge-vids 10 20"),lang: "sh"),
  raw(("
    #Switch 3
    auto bond-down
    iface bond-down
    bond-slaves swp1 swp2
    bond-mode 802.3ad
    bond-miimon 100
    bond-lacp-rate 1

    # Lien Trunk vers le Switch 4
    auto swp3
    iface swp3

    auto bridge
    iface bridge
    bridge-ports bond-down swp3
    bridge-vlan-aware yes
    bridge-vids 10 20

    auto vlan10
    iface vlan10
    vlan-id 10
    vlan-raw-device bridge
    address 192.168.1.252/24
    address-virtual 00:00:5E:00:01:10 192.168.1.254/24

    auto vlan20
    iface vlan20
    vlan-id 20
    vlan-raw-device bridge
    address 192.168.2.252/24
    address-virtual 00:00:5E:00:01:20 192.168.2.254/24"), lang:"sh"),
  raw(("
    #Switch 4
    auto bond-down
    iface bond-down
    bond-slaves swp1 swp2
    bond-mode 802.3ad
    bond-miimon 100
    bond-lacp-rate 1

    # Lien Trunk vers le Switch 3
    auto swp3
    iface swp3

    auto bridge
    iface bridge
    bridge-ports bond-down swp3
    bridge-vlan-aware yes
    bridge-vids 10 20

    auto vlan10
    iface vlan10
    vlan-id 10
    vlan-raw-device bridge
    address 192.168.1.253/24
    address-virtual 00:00:5E:00:01:10 192.168.1.254/24

    auto vlan20
    iface vlan20
    vlan-id 20
    vlan-raw-device bridge
    address 192.168.2.253/24
    address-virtual 00:00:5E:00:01:20 192.168.2.254/24"),lang: "sh")) 

- address-virtual : Cette directive assigne l'adresse MAC virtuelle (ex: 00:00:5E:00:01:10) et l'IP de la passerelle partagée (ex: 192.168.1.254/24) à l'interface VLAN. C'est elle qui permet le fonctionnement Actif-Actif sans nécessiter de protocole complexe comme VRRP.

== Tests
=== Coupure dans la couche Access 
Pour tester le réseau, on va lancer un ping M1 $<=>$ M2 puis éteindre le Switch-1.
#figure(
  image("../figures/4/image4.png", width: 70%),
  caption: "Ping de M1 à M2"
)
Comme on peut le voir, la coupure du switch 1 entraine un délai (#sym.tilde.rev 7ms) à la requete N°53.

#figure(
  image("../figures/4/image3.png", width: 70%),
  caption: "tcpdump sur un des clients"
)
Le tcpdump confirme que les requêtes ICMP continuent d'être transférées et routées correctement à travers l'infrastructure restante.

=== Coupure dans la couche Disribution

 En coupant le Switch-3, le Switch-4 prend immédiatement le relais. Grâce au protocole VRR, Switch-4 partage la même passerelle (IP et adresse MAC virtuelle) que Switch-3. Par conséquent, les caches ARP des hôtes n'ont pas besoin d'expirer ou de se mettre à jour ; le trafic est instantanément traité par
 l'interface bond-down de Switch-4.

#figure(
  image("../figures/4/image1.png", width: 70%),
  caption: "Ping de M1 à M2"
)
#figure(
  grid(
  image("../figures/4/image2.png", width: 70%),
  image("../figures/4/image5.png", width: 70%)
  ),
  caption: "tcpdump sur un des clients"
)

L'analyse de la trace réseau montre bien les requêtes ICMP qui s'enchaînent , et on voit également les requêtes ARP Request _who-has 192.168.1.1_ traitées par les équipements sans interruption fatale du flux. La redondance du routeur est donc fonctionnelle.
