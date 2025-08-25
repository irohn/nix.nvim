---@brief
---
--- Language Server for the Prisma JavaScript and TypeScript ORM
---
--- `@prisma/language-server` can be installed via npm
--- ```sh
--- npm install -g @prisma/language-server
--- ```

---@type vim.lsp.Config
return {
  cmd = NixShellCmd('nodejs_24', {'npx', 'prisma-language-server', '--stdio' }),
  filetypes = { 'prisma' },
  settings = {
    prisma = {
      prismaFmtBinPath = '',
    },
  },
  root_markers = { '.git', 'package.json' },
}
