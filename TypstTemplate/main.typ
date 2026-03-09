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


#show: init-glossary.with(
  (
    PBL: "Problem Based Learning",
    web: (
      short: "WWW",
      long: "World Wide Web",
    ),
    LTS: (
      short: "LTS",
      long: "Labelled Transition System",
      plural: "LTSs", 
    ),
  ),
  term-links: true,
) 

#show: project.with(
  meta: (
    project-group: "Master 1 CNS-SR",
    participants: (
      "Paul VEROT, 20212888",
      "Tony LENG, 20221861"
    ),
    email: (
      "paul@paulverot.fr", "20212888@etud.univ-evry.fr",
      "lengtony91@gmail.com", "20221861@etud.univ-evry.fr"

    ),
    supervisors: "Mehdi Denou",
    //field-of-study: "CS",
    project-type: "Administration avec Cumulus et Ansible"
  ),

  fr: (
    title: "Projet ADMINSYRES2-2026",
    theme: "",
    abstract: "",
  ),

)
#show: mainmatter.with(skip-double: false)
#set outline.entry(fill: line(length: 100%))
#outline(title: "Chapitres")
#include("chapters/chapitre1.typ")
#include("chapters/chapitre2.typ")
#include("chapters/chapitre3.typ")
#include("chapters/chapitre4.typ")

