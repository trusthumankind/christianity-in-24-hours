// Christianity Reconstructed in 24 Hours — Print template for pandoc + typst
// Trim: 5.06 x 7.81 in — KDP paperback

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

#set table(
  inset: 6pt,
  stroke: none,
)

// State: which H1 are we on
#let h1-count = state("h1-count", 0)
// H1 indices that should NOT show page numbers:
// 1=title, 2=copyright, 3=preface, 4=toc, 5=Part I, 12=Part II,
// 19=Part III, 26=Part IV, 33=epilogue, 34=about-authors
#let no-pagenum-headings = (0, 1, 2, 3, 4, 5, 12, 19, 26, 33, 34)

#let conf(
  title: none,
  subtitle: none,
  authors: (),
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  margin: (:),
  paper: "",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  mathfont: (),
  codefont: (),
  linestretch: 1em,
  sectionnumbering: none,
  pagenumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  doc,
) = {

  // Page setup — KDP 5.06 x 7.81 in
  set page(
    width: $if(paperwidth)$$paperwidth$$else$5.06in$endif$,
    height: $if(paperheight)$$paperheight$$else$7.81in$endif$,
    margin: (
      inside: 0.625in,
      outside: 0.5in,
      top: 0.625in,
      bottom: 0.75in,
    ),
    numbering: "1",
    number-align: center + bottom,
    footer: context {
      let n = h1-count.get()
      if n not in no-pagenum-headings {
        align(center, counter(page).display("1"))
      }
    },
  )

  // Font setup
  set text(
    font: if font != () { font } else { ("Crimson Text",) },
    size: fontsize,
    lang: lang,
    region: region,
    hyphenate: true,
    fill: black,
  )

  // Paragraph spacing
  set par(
    leading: 0.7em,
    first-line-indent: 0em,
    justify: true,
    spacing: 1.2em,
  )

  // Links — black in print
  show link: set text(fill: black)

  // Counter for H1 headings
  // Order: 1=title, 2=copyright, 3=preface, 4=toc,
  //        5=Part I, 6-11=Ch1-6,
  //        12=Part II, 13-18=Ch7-12,
  //        19=Part III, 20-25=Ch13-18,
  //        26=Part IV, 27-32=Ch19-24,
  //        33=epilogue, 34=about-authors
  show heading.where(level: 1): it => {
    h1-count.update(n => n + 1)

    context {
      let n = h1-count.get()

      // Title page (1st H1) — vertically centered, no page number
      if n == 1 {

        align(center + horizon)[
          #text(size: 22pt, weight: "bold", fill: black)[Christianity Reconstructed in 24 Hours]
          #v(0.5em)
          #text(size: 13pt, style: "italic", fill: black)[One story. One decision.]
          #v(1em)
          #text(size: 12pt, fill: black)[Marty Chang & Coraline Chang]
        ]
        pagebreak(to: "odd")
        return
      }

      // Copyright page (2nd H1) — suppress heading, small text follows
      if n == 2 {

        pagebreak(weak: true)
        v(0pt)
        return
      }

      // Preface (3rd H1) — no page number
      if n == 3 {

        pagebreak(to: "odd")
        v(2em)
        set text(size: 18pt, weight: "bold")
        set align(center)
        block(it.body)
        v(1.5em)
        return
      }

      // Table of Contents (4th H1) — separator page + auto-generated TOC
      if n == 4 {

        pagebreak(to: "odd")
        align(center + horizon, text(size: 20pt, weight: "bold", fill: black)[Contents])
        pagebreak(to: "odd")
        {
          set text(size: 10.5pt)
          outline(title: none, depth: 1)
        }
        return
      }

      // Part pages — centered on page, no page number
      if n == 5 or n == 12 or n == 19 or n == 26 {

        pagebreak(to: "odd")
        align(center + horizon)[
          #text(size: 20pt, weight: "bold", fill: black)[#it.body]
        ]
        pagebreak(to: "odd")
        return
      }

      // Epilogue (33rd) and About the Authors (34th) — no page number
      if n >= 33 {

        pagebreak(to: "odd")
        v(2em)
        set text(size: 18pt, weight: "bold")
        set align(center)
        block(it.body)
        v(1.5em)
        return
      }

      // Regular chapters — page numbers on

      pagebreak(weak: true)
      v(2em)
      set text(size: 18pt, weight: "bold")
      set align(center)
      block(it.body)
      v(1.5em)
    }
  }

  // H2 — section headings within chapters
  show heading.where(level: 2): it => {
    v(1.2em)
    set text(size: 13pt, weight: "bold")
    block(it.body)
    v(0.6em)
  }

  // H3 — sub-sections
  show heading.where(level: 3): it => {
    v(0.8em)
    set text(size: 11pt, weight: "bold")
    block(it.body)
    v(0.4em)
  }

  // Filter title + copyright from TOC; indent chapter entries
  show outline.entry.where(level: 1): it => context {
    let all-h1s = query(heading.where(level: 1))
    let idx = all-h1s.position(h => h.location() == it.element.location())
    if idx == none or idx < 4 { return }
    let section-headings = (4, 11, 18, 25, 32, 33)
    if idx in section-headings { it } else { pad(left: 1.5em, text(weight: "regular", it)) }
  }

  // Blockquotes — indented, for Scripture
  show quote.where(block: true): it => {
    set par(first-line-indent: 0em)
    block(
      inset: (left: 1.5em, right: 1em, top: 0.4em, bottom: 0.4em),
      it.body,
    )
  }

  // Render content
  doc
}

$for(header-includes)$
$header-includes$

$endfor$
#show: doc => conf(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(author)$
  authors: (
$for(author)$
$if(author.name)$
    ( name: [$author.name$],
      affiliation: [$author.affiliation$],
      email: [$author.email$] ),
$else$
    ( name: [$author$],
      affiliation: "",
      email: "" ),
$endif$
$endfor$
    ),
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
  cols: $if(columns)$$columns$$else$1$endif$,
  doc,
)

$body$
