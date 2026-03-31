#import "../classic-evry-report/template/setup/macros.typ": *
#show heading: smallcaps
#let blue(body) = {
  set text(fill: rgb("#003b69"))
  body
}
= Redondance de liens

== Résumé des contraintes et des demandes
- Les trois commutateurs (Switch 1, 2 et 3) n'utilisent que des fonctions de niveau 2.
- Il est impératif de mettre en place un réseau redondant entre les trois commutateurs tout en garantissant l'absence de boucle L2.
- La solution doit permettre une reprise du trafic la plus rapide possible en cas de coupure d'un lien.

#strong[Plan :]

- Nous allons configurer les connexions physiques et logiques (ponts) sur les trois commutateurs pour lier les machines.
- Afin d'éviter les tempêtes de diffusion (boucles L2) causées par la topologie en anneau, nous allons forcer l'utilisation du protocole STP (Spanning Tree Protocol) standard, analyser les rôles des ports, puis simuler une panne de lien pour observer le temps de convergence.
- Ensuite, nous passerons sur le protocole RSTP (Rapid Spanning Tree Protocol) pour comparer les performances de basculement et répondre à l'exigence de reprise rapide du trafic.

== Mise en place
=== Sur VMWare
Machine 1 : lan segment 1 (IP : 192.168.0.1)
Machine 2 : lan segment 2 (IP : 192.168.0.2)
Machine 3 : lan segment 3 (IP : 192.168.0.3)
Switch 1 : lan segment 1, lan segment 4, lan segment 6
Switch 2 : lan segment 2, lan segment 4, lan segment 5
Switch 3 : lan segment 3, lan segment 5, lan segment 6

=== Configuration des switch
On peut forcer l'activation du protocole avec :
```bash
# Sur chaque switch
sudo mstpctl setforcevers bridge stp
```
- #blue[mstpctl] est la commande qui sert a configurer mstpd (Multiple Spanning Tree daemon)\
- #blue[setforcevesr] sert à spécifier une version du protocole, ici stp (defaut mstp) #footnote[#link("https://github.com/mstpd/mstpd/blob/master/utils/mstpctl.8")[mstpctl.8 | sourcecode - mstpctl]]

==== Rôle et état des ports
On peut voir l'état du protocole avec la commande `net show bridge spanning-tree` :
#figure(
  grid(
    columns: 2,
    gutter: 3pt,
    image("../figures/3/image8.png", width: 100%), image("../figures/3/image6.png", width: 100%),
    image("../figures/3/image12.png", width: 100%),
  ),
)
Switch 1, 2 et 3 respectivement.
\
#list(
  [Switch 1 : Son port swp2 est le Root Port (Root) (état Forwarding) avec un coût de 20000. Son port swp1 est Designated (Desg) (état Forwarding).\
    Prévention de la boucle : Le port swp3 du Switch 1 a été placé en rôle Alternate (Altn) et en état Discarding (disc). Il bloque le trafic pour casser la boucle L2, tout en restant à l'écoute d'éventuels changements de topologie
  ],
  [
    Switch 2 (Root Bridge) : Ce commutateur a été élu pont racine (This bridge is root) car il possède l'adresse MAC la plus faible parmi ceux ayant la priorité par défaut (32768). Ses trois ports (swp1, swp2, swp3) sont en rôle Designated (Desg) et en état Forwarding (forw).
  ],
  [
    Switch 3 : Son port swp2 a été élu Root Port (Root) (état Forwarding) car c'est le chemin le plus court vers le Root Bridge. Les autres ports (swp1, swp3) sont en rôle Designated (Desg) (état Forwarding).
  ],
)
=== Test
Pour simuler une panne, on va desactiver un des lien actif. Un des lien passif devrait alors prendre le relais pour assurer la communication.\
On coupe le lien avec la commande `sudo ip link set swp2 down`:
Un ping est lancé sur une des machines.
#figure(
  image("../figures/3/image15.png", width: 70%),
  caption: [Ping vers machine 2 lancé depuis machine 1]
)

#figure(
  grid(
    image("../figures/3/image7.png", width: 70%),
    image("../figures/3/image9.png", width: 70%)
  ),
  caption: [Tcpdump sur une des machines]
)
#strong[Observation :]  Le flux ICMP a été interrompu à la séquence #blue[icmp_seq=10]. Le trafic n'a repris qu'à la séquence #blue[icmp_seq=40]. On observe une perte : #raw("51 packets transmitted, 22 received, 56.8627% packet loss, time 50748ms", lang:"bash") \

Le lien passif à bien prit le relais mais avec un délais qui a permit une perte de paquets.\
#strong[Explication] : Avec le protocole STP classique (802.1D), lorsqu'un lien tombe, le réseau doit recalculer la topologie. Le port bloqué (swp3) doit passer par plusieurs états intermédiaires temporisés (Listening et Learning) avant de passer en Forwarding. Les timers par défaut (max age 20, forward delay 15 ) imposent un délai de convergence, ce qui explique les ~30 requêtes ICMP perdues (de la séquence 11 à 39) avant la reprise de la connectivité.
\
En théorie, le délai est $ 2 * "forward delay" = 2 * 15s = 30s $ (15s en _Listening_, puis 15s en _Learning_), ce qui coïncide avec les 30 paquets ICMP perdu, qui sont envoyés à une fréquence de (1 paquet)s#super[-1].

== Configuration de RSTP
Pour répondre à la contrainte de "reprise du trafic la plus rapide possible", nous modifions la version du protocole sur les commutateurs pour utiliser RSTP (802.1w).\
Pour cela, on force à nouveau un protocole spécifique : `sudo mstpctl setforcevers bridge rstp`.\
=== Test
On coupe à nouveau le lien (`sudo ip link set swp2 down`)

