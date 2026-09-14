  // `003`, H1: the controls of wireframe 03 and the chart they draw. The two parenthesised notes
  // carry the misspellings of the brief -- `opcion` and `segun`, with no accent -- and these two
  // rows are what stops somebody from "correcting" them on the way to the screen.
  //
  // `Cabecera (izquierda)` is deliberately **not** here, and it is the one row of the table this
  // list cannot ask for: its cell carries two literals, the pattern `{símbolo} - {nombre} -
  // {moneda}` and the example `TSLA - Tesla Inc - USD`, and the second is an example of what the
  // screen shows for one action -- never a string a source file contains. Requiring it would ask
  // for a literal that cannot exist. What it stands for is checked where it can be: the header of
  // the detail is read off the screen in `ActionDetail.test.tsx` (RF-01).
  //
  // `Usuario (cabecera, derecha)` and `Cierre de sesión (cabecera, derecha)` are not here either:
  // they belong to `001`, `003` leaves them out of scope, and this list already asks for both from
  // their own sections -- requiring the same literal twice fails two tests for one missing word.
  { section: 'Detalle de Acción', element: 'Radio 1' },
  { section: 'Detalle de Acción', element: 'Aclaración del radio 1' },
  { section: 'Detalle de Acción', element: 'Radio 2' },
  { section: 'Detalle de Acción', element: 'Etiqueta intervalo' },
  { section: 'Detalle de Acción', element: 'Aclaración del intervalo' },
  { section: 'Detalle de Acción', element: 'Botón' },
  { section: 'Detalle de Acción', element: 'Eje Y' },
  { section: 'Detalle de Acción', element: 'Eje X' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Volver a la lista' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Aclaración de horarios' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Intervalo sin elegir' },
  // `003`, H3: the two date fields the `Histórico` row draws, and the two range failures the
  // client wrote for it. Both of those are templates, and `fragmentsOf` is what splits them at the
  // edges of `{intervalo}` and `{N}`: what is required of a source file is the fixed parts, never
  // the placeholder. `Completá este campo.` is not added here -- the detail shows the same text
  // the login already shows, and `REQUIRED` has asked for it from *Sesión y validación* since
  // `001`.
  { section: 'Detalle de Acción', element: 'Placeholder desde' },
  { section: 'Detalle de Acción', element: 'Placeholder hasta' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Fechas al revés' },
  { section: 'Detalle: navegación, horarios y validación', element: 'Rango excedido' },
  // `003`, H4: the three notices that explain what the chart is showing. The names carry their
  // backticks because that is how the copy writes the first cell of that table -- the state, as an
  // identifier -- and this list asks for a row exactly as it is written.
  //
  // Three and not four: the fourth row of the table is `ok`, whose text is *(sin aviso)* and
  // carries no literal at all. The reader above drops rows with no literal, so asking for that one
  // would raise for a row that, to this suite, does not exist. That `ok` draws no notice is
  // checked on the screen, in `ActionDetail.test.tsx` (RF-32), which is where it can be checked.
  { section: 'Avisos de estado', element: '`stale`' },
  { section: 'Avisos de estado', element: '`market_closed`' },
  { section: 'Avisos de estado', element: '`no_data`' },
