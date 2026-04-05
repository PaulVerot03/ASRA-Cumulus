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



= Partie I : Serveur NFS

#figure-slide(
  grid(
    columns: 2,
    rows: 2,
    gutter: 10pt,
    figure(
      image("archi1.png", width: 65%),
      caption: none,
    ),
    [
      + Serveur NFS 
        //- `nfs-kernle-server`
        //- `/etc/exports` → ``
      + VLANS 
        - 10 : M1, S1, S3
        - 20 : NFS, S1, S3
        - 30 : M2, S2, S3
    ],
    strong("test2")
  )
)

= Partie II : STP et RSTP

= Partie III : Redondance de Liens

#slide[
]

#focus-slide[
]

= Partie IV Redondance de Switch

#ending-slide(
  title: [Thank you for your attention!],
  subtitle: [Any questions?],
  contact: ([Thony LENG & Paul VEROT], "github.com/PaulVerot03/ASRA-Cumulus"),
)
