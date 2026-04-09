#import "../unofficial-sorbonne-presentation-0.3.1/lib.typ": *

#show: sorbonne-template.with(
  title: [Projet ASRA II],
  subtitle: [Architecture réseau et switching avec Cumulus Linux & Debian],
  author: [Thony LENG, Paul VEROT],
  affiliation: [Master I CNS-SR],
  faculty: "univ", // Options: "univ" (blue), "sante" (red), "sciences" (light blue), "lettres" (yellow)
  date: datetime.today().display(),
  show-outline: true,
  progress-bar: "bottom",

  logo-transition: "Logo_blanc_centré.png",
  logo-slide: "Logo_bleu_centré.svg",
  text-size: 16pt,
  text-font: "Libertinus Serif",
)

//#set text(8pt)
= Serveur NFS

#figure-slide(
  grid(
    columns: (40%, auto),
    rows: 2,
    gutter: 10pt,
    figure(
      image("archi1.png", width: 100%),
      caption: none,
    ),
    [
      // + Serveur NFS
      //- `nfs-kernle-server`
      //- `/etc/exports` → ``
      //
      #grid(
        //fill: rgb("#d1d1d1"),
        inset: 8pt,
        gutter: 3pt,
        align: left,
        [#strong("Contraintes :")
          SW1 & SW2 : niveau 2 uniquement \
          SW3 : niveau 3 (routage inter-VLAN + firewall) \
          Isoler M1 / M2 mais accès commun au serveur NFS \
          Tolérance panne sur les interfaces NFS],

        [#strong("Solution :")\
          VLAN 10 → M1 (192.168.10.3)\
          VLAN 20 → NFS (192.168.20.3)\
          VLAN 30 → M2 (192.168.30.3)\
          Pare-feu SW3 : DROP bidirectionnel 10↔30\
          Bond0 NFS (active-backup, miimon=100ms)
        ],
      )
    ],
  ),
)

#slide[
  #strong("Résultats :")
  - Transfert opérationel : tout les fichiers transmis sont visibles sur le seveur
  - Isolation totale : les machines qui ne doivent pas communiquer ne peuvent pas
    - Ping M1 #sym.arrow.l.r M2 : 100% packet loss
  - Accès restreint : M2 ne peut pas accéder au partage désigné à M1
  - Tolérance à la panne : communication opérationelles même avec un lien coupé
  - Intégrité des données garantie : sha256 identique sur le serveur et la machine
    - Même en cas de coupure du lien principal


]

= STP et RSTP
#slide[
  #grid(
    columns: (45%, auto),
    gutter: 8pt,
    rows: 2,
    [#strong("Problème: Broadcast storm") \
      Sans STP (bridge-stp off), topologie en anneau :
      - 21 191 paquets capturés en quelques secondes
      - 25 284 paquets dropped by kernel
      Réseau totalement inutilisable
      \

      #strong("Solution :")\
      sudo mstpctl setforcevers bridge stp \
      sudo mstpctl setforcevers bridge rstp \
      Root Bridge : SW2 (MAC la plus faible, prio 32768) \
      Port bloqué : swp3/SW1 → rôle Alternate (Discarding) \
    ],
    [
      #strong("Rôle et état des ports")
      #table(
        inset: 12pt,
        columns: (auto, auto, auto, auto),
        table.header([*Switch*], [*Port*], [*Rôle*], [*État*]),
        [SW1], [swp2], [root], [Forwarding],
        [SW1], [swp1], [designated], [Forwarding],
        [SW1], [swp3], [alternate], [discarding],
        [SW2], [swp1-3], [designated], [Forwarding],
        [SW3], [swp2], [root], [Forwarding],
        [SW3], [swp1,3], [designated], [Forwarding],
      )
    ],
  )
]
#slide[
  #smallcaps[#strong("STP vs RSTP")]
  #grid(
    gutter: 10%,
    columns: (1fr, 1fr),
    [
      #strong[STP (802.1D)] \
      #underline("Observations :") \
      Paquets envoyés : 51
      Paquets reçus : 22
      Perte : 56.86%
      Durée interruption : ~30 s
      Séquences perdues : icmp_seq 11→39
      \
      \
      #underline("Explication :") \
      Les timers imposent des phases
      Listening (15s) + Learning (15s) \
      #sym.arrow.r.curve convergence = 2×forward_delay = 30s

    ],
    [
      #strong[RSTP (802.1w)] \
      #underline("Observations :") \
      Paquets envoyés : 67
      Paquets reçus : 67
      Perte : 0%
      Durée interruption : < 1 s
      Continuité quasi parfaite
      \
      \
      #underline("Explication :") \
      Mécanisme Proposal/Agreement entre switches voisins → pas de timers fixes, passage direct en Forwarding.

    ],
  )
]
= Redondance de Liens

#figure-slide[
  #grid(
    columns: (55%, auto),
    rows: 2,
    gutter: 10pt,
    figure(image("partie3.drawio.png", width: 100%), caption: none),
    [
      #grid(
        //fill: rgb("#d1d1d1"),
        inset: 8pt,
        gutter: 3pt,
        align: left,
        [#strong("Contraintes :") \
          Tolérer la panne de SW1 ou SW2 \
          Aucune interruption M1↔M2 \
          Mode actif/actif (max performances) \
          Pas de switch supplémentaire
        ],
        [#strong("Solution :")\
          LACP 802.3ad : chaque machine connectée aux 2 switchs \
          Peer Link SW1↔SW2 (swp3+swp4) \
          `clagd-sys-mac` : MAC partagée \
          #sym.arrow.curve.r 1 switch logique \
          //Backup IP : anti split-brain
        ],
      )
    ],
  )
]
#slide[
  #strong("Tests") \ \
  #underline[Résultat :] coupure SW1 pendant ping M1↔M2\ \
  99 paquets envoyés   →   97 reçus   →   2 perdus (2.02%)
  #grid(
    fill: rgb("e4e4ea"),
    stroke: (x, y) => (
      //top: if y > 0 { black },
      left: if x >= 0 { black },
    ),
    gutter: 15pt,
    inset: 8pt,
    columns: (1fr, 1fr, 1fr),
    [2 paquets perdus], [100ms \ Délai `bond-miimon`], [Perte minimale de paquets],
  )

  #underline[Mécanisme de bascule]
  + bond-miimon (100ms) détecte la perte du lien vers SW1
  + bond0 bascule tout le trafic sur l'interface restante (ens37 → SW2)
  + MLAG sync via Peer Link : SW2 continue de relayer les trames
  + SW3 reçoit les trames via son bond-down vers SW2 uniquement
  #sym.arrow.r.double routage continu
]

// #focus-slide[
// ]

= Redondance de Switch
#figure-slide[
  #grid(
    columns: (55%, auto),
    rows: 2,
    gutter: 10pt,
    figure(image("partie4.drawio_1.png", width: 100%), caption: none),
    [
      #grid(
        //fill: rgb("#d1d1d1"),
        inset: 8pt,
        gutter: 3pt,
        align: left,
        [#strong("Contraintes :") \
          Tolérer la perte de SW3\
          Conserver la redondance couche accès\
          Ajout de SW4 comme routeur de secours\
          Mode Active-Active : pas d'élection, pas\
          de délai de bascule

        ],
        [#strong("Protocole : VRR Cumulus :")\
          SW3 & SW4 partagent :\
          IP virt. 192.168.1.254 & 192.168.2.254\
          //MAC virt. 00:00:5E:00:01:10/20\
          //address-virtual dans /e/n/interfaces\
          Cache ARP inchangé → bascule instantanée\

        ],
      )
    ],
  )
]
#slide[
  #grid(
    columns: (1fr, 1fr),
    [#strong("Panne couche access (SW1)")\
      65 paquets envoyés / 62 reçus | Perte : 4.6% \
      Délai visible : ~7ms à la req. N°53

      Mécanisme :
      - bond-miimon (100ms) détecte la perte
      - bond0 bascule sur le lien restant
      - MLAG resync via Peer Link
      - trafic repris via SW2

      tcpdump confirme :
      requêtes ICMP continuées sans interruption fatale
    ],
    [#strong("Panne couche Distribution (SW3)")\
      35 paquets envoyés / 31 reçus | Perte : 11.4% \
      Durée : ~4 s de perturbation

      Mécanisme VRR :
      - SW4 partage déjà la même VIP
        - MAC: 00:00:5E:00:01:10 → 192.168.1.254/24
        - MAC: 00:00:5E:00:01:20 → 192.168.2.254/24
      //- Cache ARP inchangé sur M1/M2
      - bond-down/SW4 reprend le routage

      Délai résiduel :\
      MLAG doit détecter la perte du lien vers SW3 (`bond-miimon 100ms`) et re-synchroniser

    ],
  )
]
#ending-slide(
  title: [Merci pour votre attention !],
  subtitle: [Des Questions?],
  contact: ([Thony LENG & Paul VEROT], "github.com/PaulVerot03/ASRA-Cumulus"),
)
