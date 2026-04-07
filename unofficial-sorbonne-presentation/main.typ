#import "../unofficial-sorbonne-presentation-0.3.1/lib.typ": *

#show: sorbonne-template.with(
  title: [Projet ASRA II],
  subtitle: [Architecture réseau et switching avec Cumulus Linux & Debian],
  author: [Thony LENG, Paul VEROT],
  affiliation: [Master I CNS-SR],
  faculty: "univ", // Options: "univ" (blue), "sante" (red), "sciences" (light blue), "lettres" (yellow)
  date: datetime.today().display(),
  show-outline: true,

  logo-transition: "Logo_blanc_centré.png",
  logo-slide: "Logo_bleu_centré.svg",
)

#set text(8pt)

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
    rows:2,
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
        inset: 8pt,
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

    [
      

    ],
  )
]

= Redondance de Liens

#slide[
]

// #focus-slide[
// ]

= Redondance de Switch

#ending-slide(
  title: [Merci pour votre attention !],
  subtitle: [Questions?],
  contact: ([Thony LENG & Paul VEROT], "github.com/PaulVerot03/ASRA-Cumulus"),
)
