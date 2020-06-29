# Lace2: From OCR to TEI

Designed for the large-scale scholarly digitization of primary texts, Lace is a GUI-based OCR editing suite with a difference: it outputs structured, citable [TEI Simple](https://teic.github.io/TEI-Simple/), bridging the gap between OCR’s page-based layout and a publication-ready document without the proofreader/editor ever confronting XML data.

Lace’s in-browser editing environment, comprising a page image and a facing OCR transcription, makes possible three operations. A proofreader may verify the OCR text, aided by an adjacent popup image of the word image. Secondly, she may draw rectangular zones on the page image. These correspond to the functional regions of the page such as ‘translation’, ‘commentary’ and ‘primary text’ and also indicate proper reading order. Finally, a GUI widget allows her to place a citation within the text of these zones. Internally, citations are [CTS-URNs](https://www.homermultitext.org/hmt-doc/cite/cts-urn-overview.html) but the widget’s type-ahead form field allows the proofreader to search by author and title.

Combining these data through powerful Xquery scripts, Lace generates a TEI Simple document which, for each of these zones, collects all text across every page. It transforms the citations into nested div elements which reflect the hierarchy of the citation system. Because all zones of the pages can have citations applied, the correlations between, for instance, primary text and translation are indicated in the output document. Furthermore, in every zone, page break (&lt;pb/&gt;) milestones are retained, and a *line mode* is offered, whereby line break (&lt;lb/&gt;) milestones are offered and OCR dehyphenation processes are not applied. In this way, the proofreader converts page-based OCR data into a publication-ready TEI document without any understanding of XML required.

Lace is more than a TEI-generating program, though. It produces zip files of OCR training data from verified words. With this, an operator can bootstrap the OCR of a previously intractable script or font, editing, say, five pages of poorly OCR’d text, then re-processing the entire volume with a classifier generated from these pages. Lace will retain those five corrected pages, allowing proofreaders to continue with the rest of the text. Lace also provides a Lucene-based search function which refers to its results with references where possible.

Lace is built upon the well-established [eXist-db](http://exist-db.org/exist/apps/homepage/index.html) XML database: it and its OCR data are installed as easily-managed packages through eXist’s drag-and-drop interface. An open-source project, Lace’s source code and compiled modules are stored in an active github [repository](https://github.com/brobertson/Lace2), and a site for exploring its functions is offered at [http://trylace.org](http://trylace.org) Lace is a well-established platform: the majority of the 24 million words in the Open Greek and Latin’s First Thousand Years of Greek project were edited with Lace.

Further Documentation

Modularization: [*Lace 0.4*](https://docs.google.com/document/d/1eGfseeNOPe1FNbEZ-F5UOozAqbaPdquIu14iEhFYVOI/edit?usp=sharing)

Zoning: [*Lace 0.5*](https://docs.google.com/document/d/1WV72eKqTkg-hugXO5jY4SERA8yQHp3B0LSS1f5tCa-E/edit?usp=sharing)

Search: [*Lace 0.5.5*](https://docs.google.com/document/d/1HRzFKwhO4nyeXLdQvPEbChELO39SV2lh_xl0K09g9-Y/edit?usp=sharing)

Bruce Robertson

2020-04-29

