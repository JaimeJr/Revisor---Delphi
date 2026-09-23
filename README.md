# EditorManuscrito

Aplicacao Delphi VCL para importar, revisar e exportar manuscritos.

## Estrutura

- `src/Domain`: entidades, valores e contratos do dominio.
- `src/Application`: casos de uso e comandos editoriais.
- `src/Infrastructure`: DOCX, DeepSeek, persistencia JSON, gatilhos e cache.
- `src/Presentation`: formularios, presenters e composicao da aplicacao.
- `tests`: testes e fixtures.
- `data`: dados de trabalho locais, ignorados pelo Git.
- `keys`: credenciais locais, nunca versionadas.

## Desenvolvimento

Abra `EditorManuscrito.dproj` no Delphi. A chave da API deve ser colocada em
`keys/deepseek.key` somente no ambiente local.
