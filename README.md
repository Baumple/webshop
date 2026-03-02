# pokeshop

Das gesamte Projekt ist in `gleam` geschrieben und benutzt Server Side
Rendering via der Library `lustre`, die als HTML-DSL dient. Der Server selbst
basiert auf dem `wisp` Framework, dass das abhandeln von Requests mittels
`middlewares` erleichtert und vereinfacht.

Ich habe mich für `gleam` entschieden, da es zu `erlang` compiled und damit
auch auf der "BEAM-VM" läuft. Diese wiederum wurde extra für
Telekommunikationsservices entwickelt und zeichnet sich deswegen durch ihre hohe
Fähigkeit zu Concurrency und Fault-Tollerance aus, weshalb es möglich ist,
Programme zu schreiben, die nahezu niemals abstürzen bzw. sich sogar selbst
"wiederbeleben" können.

`gleam` fügt ergänzend zu `erlangs` funktionalem Paradigma zusätzlich noch ein
starkes Typensystem hinzu, das bei der Entwicklung und Validierung des
Programmes zusätzliche Sicherheit gibt.

`lustre` ist das Framework im gleam-ecosystem für Frontend-Developement.
`gleam` kann neben `erlang` auch zu `javascript` compiled werden, was es
ermöglicht, dieselbe Sprache für Frontend und Backend zu verwenden bzw. auch
gemeinsamen Code zwischen Frontend und Backend austauschen kann. In diesem
Projekt aber verzichte ich auf `javascript` im Frontend und nutze jediglich die
HTML-Generationsfunktionen, die `lustre` zur Verfügung stellt. Um trotzdem eine
responsive Website zu ermöglichen, verwende ich `htmx`, dass es erlaubt anderen
HTML-Elementen außer <form> und <a> AJAX-Requests zu erstellen bzw. auszulösen.
`htmx` lässt sich mittels einer einzigen Zeile einbinden und kann so
beispielsweise beim Drücken eines <button>-Elementes eine Request an den Server
schicken, welcher dann ein HTML-Snippet zurücksendet, welches wiederum den
gedrückten <button> oder ein anderes `target` ersetzt. So muss ich keine Zeile
Javascript schreiben. Da alles auf dem Server gerendert wird, muss der User
ebenfalls keinerlei große javascript Bibliotheken herunterladen, was die
Website deutlich kleiner macht und somit schneller Laden lässt.

Am besten funktionert HTMX dabei mit einer Templatingsprache wie etwa die
`template` library für `golang` oder `templates` des `DJANGO`-Webframeworks für
`python`. Gleam ist noch eine relativ junge Sprache, daher hatte ich noch keine
Bibliothek für Templating gefunden, die mich angesprochen hatte. Aus diesem
Grund nutze ich dafür `lustre` als DSL.

Für die Persistenz der Daten benutzte ich eine simple SQLite Datenbank, da es
einfach aufzusetzen ist und für die meisten Projekte durchaus mehr als
ausreichend ist. Ergänzend dazu nutze ich die Libraries `sqlight`, `cake` sowie
`cake_sqlite`, welche das nutzen der SQLite Datenbank ermöglichen. `cake`
erlaubt dabei das aufbauen und sanitizen von SQL-Queries, sodass eine
SQL-Injektion ausgeschlossen werden kann.

Die Daten für die Items beziehe ich dabei von der open-source api
"https://pokeapi.co".

Passwörter werden durch einen argon2-Algorithmus verschlüsselt, da es dafür
die bequeme Library `argus` gibt.


# TODO:
- duplicate username
- form can be sent with invalid data
- register confirmation
