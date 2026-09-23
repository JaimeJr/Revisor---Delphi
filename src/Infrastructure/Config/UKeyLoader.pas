unit UKeyLoader;

{
  UKeyLoader.pas
  ─────────────────────────────────────────────────────────────
  Carrega a chave da API DeepSeek de um arquivo de texto em
  /keys/deepseek.key, evitando que a chave entre no código-fonte
  ou no controle de versão.

  Estratégia de busca (em cascata):
    1. <pasta do executável>/keys/deepseek.key
    2. <pasta do executável>/../../keys/deepseek.key
       (cenário de desenvolvimento: bin/Win64/Debug → raiz do projeto)
    3. <diretório atual>/keys/deepseek.key

  Formato do arquivo:
    • Uma chave por linha.
    • Linhas em branco são ignoradas.
    • Linhas iniciadas com '#' são comentários.
    • A primeira linha válida é usada.

  Falhas:
    • Pasta /keys não encontrada       → EKeyNaoEncontrada
    • Arquivo deepseek.key não existe  → EKeyNaoEncontrada
    • Arquivo só com vazios/comentários → EKeyVazia
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

type
  /// <summary>Pasta ou arquivo de chave não encontrado.</summary>
  EKeyNaoEncontrada = class(Exception);

  /// <summary>Arquivo existe mas não contém uma chave válida.</summary>
  EKeyVazia = class(Exception);

  TKeyLoader = class
  public
    const
      NOME_PASTA_KEYS = 'keys';
      NOME_ARQUIVO_KEY = 'deepseek.key';
      NOME_ARQUIVO_EXEMPLO = 'deepseek.key.example';

    /// <summary>
    ///   Lê a chave do disco. Lança EKeyNaoEncontrada ou
    ///   EKeyVazia em caso de falha.
    /// </summary>
    class function CarregarDeepSeekKey: string;

    /// <summary>
    ///   Caminho absoluto do arquivo de chave, se encontrado.
    ///   Retorna string vazia se nenhuma pasta /keys foi localizada.
    ///   Útil para mensagens de erro da UI ("coloque sua chave em X").
    /// </summary>
    class function CaminhoArquivoKey: string;

    /// <summary>
    ///   Localiza a pasta /keys na cascata. Retorna vazio se
    ///   não encontrar nenhuma.
    /// </summary>
    class function LocalizarPastaKeys: string;
  end;

implementation

class function TKeyLoader.LocalizarPastaKeys: string;
var
  Candidatos: TArray<string>;
  Candidato: string;
  Caminho: string;
  Arquivo: string;
begin
  Candidatos := [
    // 1) Ao lado do executável (distribuição).
    TPath.Combine(ExtractFilePath(ParamStr(0)), NOME_PASTA_KEYS),

    // 2) Dois níveis acima do executável (desenvolvimento:
    //    bin/Win64/Debug → raiz do projeto).
    TPath.Combine(ExtractFilePath(ParamStr(0)),
      TPath.Combine('..', TPath.Combine('..', NOME_PASTA_KEYS))),

    // 3) Diretório de trabalho atual (IDE, scripts, etc.).
    TPath.Combine(GetCurrentDir, NOME_PASTA_KEYS)
  ];

  for Candidato in Candidatos do
  begin
    // Normaliza o caminho (resolve "..", barras etc.).
    Caminho := TPath.GetFullPath(Candidato);

    if not TDirectory.Exists(Caminho) then
      Continue;

    Arquivo := TPath.Combine(Caminho, NOME_ARQUIVO_KEY);
    if TFile.Exists(Arquivo) then
      Exit(Caminho);
  end;

  Result := '';
end;

class function TKeyLoader.CaminhoArquivoKey: string;
var
  Pasta: string;
begin
  Pasta := LocalizarPastaKeys;
  if Pasta = '' then
    Exit('');
  Result := TPath.Combine(Pasta, NOME_ARQUIVO_KEY);
end;

class function TKeyLoader.CarregarDeepSeekKey: string;
var
  Arquivo, Linha: string;
  Linhas: TStringList;
begin
  Arquivo := CaminhoArquivoKey;

  if Arquivo = '' then
    raise EKeyNaoEncontrada.CreateFmt(
      'Arquivo de chave não encontrado.' + sLineBreak +
      'Esperado em uma destas pastas: /%s' + sLineBreak +
      'Crie a pasta "/%s" e coloque o arquivo "%s" com sua chave.',
      [NOME_PASTA_KEYS, NOME_PASTA_KEYS, NOME_ARQUIVO_KEY]);

  Linhas := TStringList.Create;
  try
    try
      Linhas.LoadFromFile(Arquivo);
    except
      on E: Exception do
        raise EKeyNaoEncontrada.CreateFmt(
          'Não foi possível ler o arquivo de chave "%s": %s',
          [Arquivo, E.Message]);
    end;

    for Linha in Linhas do
    begin
      // ⚠ Linha do for-in também é read-only. Copia para uma
      // variável local antes de modificar.
      var Limpa := Linha.Trim;

      if (Limpa = '') or Limpa.StartsWith('#') then
        Continue;

      Exit(Limpa);
    end;
  finally
    Linhas.Free;
  end;

  raise EKeyVazia.CreateFmt(
    'Arquivo "%s" não contém nenhuma chave válida ' +
    '(linhas em branco e comentários iniciados com "#" são ignorados).',
    [Arquivo]);
end;

end.
