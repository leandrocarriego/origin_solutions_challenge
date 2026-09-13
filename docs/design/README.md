# Interfaz

No hay design system, ni librería de componentes, ni framework de estilos. El enunciado dice que
**no se evalúa el diseño ni el conocimiento de UI**, y a la vez trae tres wireframes: eso hace que
la interfaz sea un requisito a cumplir, no un espacio a diseñar.

- **`wireframes/`** — los tres mockups recortados del PDF original, sin retoque. Son la
  especificación de layout: orden de los elementos, etiquetas, columnas y controles
  (`CONVENTIONS.md` → `UI-01`).
- **`COPY.md`** — los textos visibles, verbatim del enunciado, faltas incluidas (`UI-02`).

Lo que el wireframe no define —espaciados, tipografía, el detalle del aviso de estado— se resuelve
con CSS plano y una paleta neutra tomada del propio mockup: grises para superficie, borde y cabecera
de tabla, y azul de enlace sólo donde hay un enlace.

**La regla de oro:** ante la duda entre reproducir el wireframe y mejorarlo, se reproduce. Una
pantalla que se aparta del mockup es un hallazgo de review, no una mejora.
