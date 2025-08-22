---@brief
---
--- https://github.com/clojure-lsp/clojure-lsp
---
--- Clojure Language Server

---@type vim.lsp.Config
return {
  cmd = nixCmd('clojure-lsp'),
  filetypes = { 'clojure', 'edn' },
  root_markers = { 'project.clj', 'deps.edn', 'build.boot', 'shadow-cljs.edn', '.git', 'bb.edn' },
}
