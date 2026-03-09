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

// revision to use for add, rmv and change

// it is also possible to apply show rules to the entire project
// it is more or less a search and replace when applying it to a string.
// see https://typst.app/docs/reference/styling/#show-rules
// #show "naive": "naïve"
// #show "Dijkstra's": smallcaps

// Initialize acronyms / glossary
// See https://typst.app/universe/package/glossy for additional details.

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
      "pauljeanlouisverot@protonmail.com", "20212888@etud.univ-evry.fr",

    ),
    supervisors: "",
    //field-of-study: "CS",
    project-type: ""
  ),

  fr: (
    title: "",
    theme: "",
    abstract: "",
  ),

  // clear-double-page: false,

)
= Partage Réseau NFS 
```bash 
```
// = Preface
// #lorem(100)

//#outline(depth: 2)

//#note-outline()

// use `show: mainmatter.with(skip-double: false)` to omit double page skips
// the same syntax appylies to 'chapters', 'backmatter' and 'appendix'.
//#show: mainmatter
//#include "chapters/introduction.typ"
// include : #import "../classic-evry-report/template/setup/macros.typ": * at the top of the files in the subdirs
//#show: chapters
//#include "chapters/problem-analysis.typ"
//#include "chapters/custom-macros.typ"

// in the backmatter, the chapter numbers are removed again
// show the references here, along with other backmatter content, like a list of acronyms
//#show: backmatter
//#include "chapters/conclusion.typ"

// the documentation for this package includes a few different themes
// or even allows you to use your own custom one
//#glossary(title: "List of Acronyms")
//#bibliography("references.bib", title: "References")

//#show: appendix
//#include "appendices/scripting.typ"

