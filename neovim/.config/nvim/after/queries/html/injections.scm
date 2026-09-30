; extends
;
; MJML injections layered on top of the bundled HTML treesitter queries.
;
; `.mjml` files use the `mjml` filetype, which is registered to the `html`
; parser in `lua/plugins/mjml.lua`. The stock `html_tags` injections only inject
; CSS/JS into `<style>`/`<script>`, so MJML's own `<mj-style>` element is handled
; here to highlight its contents as CSS.
;
; Files under `after/queries/html/` are merged on top of the queries shipped by
; nvim-treesitter, and the `#eq? @_tag "mj-style"` predicate keeps this rule
; inert for ordinary HTML buffers.

((element
  (start_tag
    (tag_name) @_tag)
  (text) @injection.content)
  (#eq? @_tag "mj-style")
  (#set! injection.language "css"))
