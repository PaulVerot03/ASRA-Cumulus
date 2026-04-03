#import "classic-evry-report/lib.typ": (
  appendix,
  backmatter,
  chapters,
  mainmatter,
  project,
  smallprint,
)

#import "classic-evry-report/template/setup/macros.typ": *
#let blue(body) = {
  set text(fill: rgb("#003b69") )
  body
}
#show heading : smallcaps

#show: project.with(
  meta: (
    project-group: "Master I CNS-SR",
    participants: (
      "Tony LENG, 20221861",
      "Paul VEROT, 20212888"
      
    ),
    email: (
      "lengtony91@gmail.com", "20221861@etud.univ-evry.fr",
      "paul@paulverot.fr", "20212888@etud.univ-evry.fr"

    ),
    supervisors: "Mehdi Denou",
    //field-of-study: "CS",
    project-type: "Semestre 2"
  ),

  fr: (
    title: "Projet d'Administration des Systèmes et des Réseaux II",
    theme: "Architecture de réseaux avec Cumulus et Debian",
    abstract: "Ce projet porte sur la mise en place de quatre architectures et sur l'étude des protocoles associés. Nous utiliserons Cumulus Linux et Debian 13 pour les switch et client respectivement. Notamment, le projet porte sur la redondance des liens et des switchs ainsi que sur Spanning Tree.",
  ),

)
#show: mainmatter.with(skip-double: false)
#set outline.entry(fill: line(length: 100% , stroke:(thickness:1pt, dash:"loosely-dashed", paint:rgb("#003b69"))) )



#outline(title: "Chapitres")
#include("chapters/chapitre1.typ")
#include("chapters/chapitre2.typ")
#include("chapters/chapitre3.typ")
#include("chapters/chapitre4.typ")

//#show: appendix
//#include "appendices/appendix.typ"