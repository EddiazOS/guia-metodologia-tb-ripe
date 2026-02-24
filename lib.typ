// Plantilla Frontiers para Typst
// Adaptación no oficial basada en FrontiersinHarvard.cls y FrontiersinVancouver.cls
// Versión: 1.0 - Diciembre 2025

#let frontiers(
  // Metadatos del artículo
  title: "Article Title",
  running-title: "Running Title",
  authors: (),
  affiliations: (),
  corresponding-author: (
    name: "Corresponding Author",
    email: "email@uni.edu",
  ),
  extra-auth: none,
  keywords: (),
  abstract: none,
  
  // Opciones de estilo
  citation-style: "harvard", // "harvard" o "vancouver"
  line-numbers: false,
  
  // Contenido del documento
  body,
) = {
  // Configuración de página
  set page(
    paper: "us-letter",
    margin: (
      top: 3.6cm,
      bottom: 2.5cm,
      left: 4.5cm,
      right: 3cm,
    ),
    header: context {
      if counter(page).get().first() > 1 [
        #set text(size: 10pt, font: "Helvetica", weight: "bold")
        #smallcaps[#running-title]
        #h(1fr)
        #counter(page).display()
        #line(length: 100%, stroke: 0.5pt)
      ]
    },
    footer: context [
      #line(length: 100%, stroke: 0.5pt)
      #v(2pt)
      #set text(size: 9pt, font: "Helvetica", weight: "bold")
      #h(1fr)
      Frontiers
      #h(1fr)
      #counter(page).display()
    ],
  )
  
  // Configuración tipográfica general
  set text(
    font: "Times New Roman",
    size: 12pt,
    lang: "en",
  )
  
  set par(
    justify: true,
    leading: 0.55em,
    spacing: 1em,
  )
  
  // Títulos y secciones
  show heading.where(level: 1): it => {
    set text(font: "Helvetica", size: 13pt, weight: "bold")
    v(10pt)
    upper(it.body)
    v(3pt)
  }
  
  show heading.where(level: 2): it => {
    set text(font: "Helvetica", size: 11.5pt, weight: "bold")
    v(4pt)
    it.body
    v(2pt)
  }
  
  show heading.where(level: 3): it => {
    set text(font: "Helvetica", size: 11.5pt, weight: "regular")
    v(2pt)
    it.body
    v(1pt)
  }
  
  show heading.where(level: 4): it => {
    set text(font: "Helvetica", size: 11.5pt, weight: "bold", style: "italic")
    v(2pt)
    it.body
    v(1pt)
  }
  
  show heading.where(level: 5): it => {
    set text(font: "Helvetica", size: 11.5pt, style: "italic")
    v(2pt)
    it.body
    v(1pt)
  }
  
  // Configuración de numeración de líneas
  if line-numbers {
    set par(hanging-indent: 2em)
  }
  
  // Configuración de figuras y tablas
  show figure.caption: it => {
    set text(size: 10pt)
    strong(it.supplement)
    [ ]
    it.body
  }
  
  // Página de título
  [
    #set align(left)
    #v(-1cm)
    
    // Logo placeholder (requeriría imagen logo1.eps convertida)
    #box(
      width: 12cm,
      height: 3cm,
      fill: rgb("#f0f0f0"),
      [
        #set align(center + horizon)
        #text(size: 18pt, weight: "bold", fill: rgb("#666666"))[
          FRONTIERS LOGO
        ]
        #v(0.3cm)
        #text(size: 8pt, fill: rgb("#999999"))[
          (Colocar logo1.pdf aquí)
        ]
      ]
    )
    
    #v(0.5cm)
    #line(length: 100%, stroke: 1pt)
    #v(0.5cm)
    
    // Título
    #text(
      size: 20pt,
      font: "Helvetica",
      weight: "bold",
      fill: black,
    )[#title]
    
    #v(1em)
    
    // Autores
    #text(
      size: 12pt,
      font: "Helvetica",
      weight: "bold",
    )[
      #authors.map(author => [
        #author.name#super[#author.affiliations.join(",")]
      ]).join(", ")
    ]
    
    #v(0.5em)
    
    // Afiliaciones
    #text(
      size: 12pt,
      font: "Helvetica",
      style: "italic",
    )[
      #affiliations.enumerate(start: 1).map(((i, affiliation)) => [
        #super[#i]#affiliation
      ]).join(linebreak())
    ]
    
    #v(1em)
    
    // Autor correspondiente
    #text(
      size: 12pt,
      font: "Helvetica",
    )[
      *Correspondence*:\\
      #corresponding-author.name\\
      #corresponding-author.email
    ]
    
    #if extra-auth != none [
      #v(0.5em)
      #text(
        size: 12pt,
        font: "Helvetica",
      )[#extra-auth]
    ]
    
    #v(1.5em)
  ]
  
  // Abstract
  #if abstract != none [
    #set text(font: "Helvetica", size: 12pt)
    #strong[ABSTRACT]
    #v(0.5em)
    #abstract
    #v(0.5em)
  ]
  
  // Keywords
  #if keywords.len() > 0 [
    #set text(font: "Helvetica", size: 8pt, weight: "bold")
    *Keywords:* #keywords.join(", ")
    #v(1.5em)
  ]
  
  // Inicio del documento en dos columnas
  show: columns.with(2, gutter: 1.5em)
  
  // Contenido principal
  body
}

// Función auxiliar para referencias bibliográficas estilo Harvard
#let cite-harvard(..args) = {
  // Implementación básica, extender según necesidades
  cite(..args)
}

// Función auxiliar para referencias bibliográficas estilo Vancouver
#let cite-vancouver(..args) = {
  // Implementación básica, extender según necesidades
  cite(..args, form: "numeric")
}
