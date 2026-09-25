unit UPromptVarredura;

{
  UPromptVarredura.pas
  ─────────────────────────────────────────────────────────────
  Construtor de prompt no modo varredura.

  Nesta versão:
    • Campo "motivo" restrito a "Ok" ou "Corrigido".
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  UIConstrutorPrompt,
  UChamada,
  UVicio,
  UValores;

type
  TPromptVarredura = class(TInterfacedObject, IConstrutorPrompt)
  private
    function MontarSystem(const AChamada: TChamada;
      const ACatalogo: TCatalogoVicios): string;
    function MontarUser(const AChamada: TChamada): string;
    function MontarBlocoCatalogo(
      const ACatalogo: TCatalogoVicios): string;
    function MontarBlocoParagrafos(const AChamada: TChamada): string;
    function MontarBlocoObservacao(const AObs: string): string;
  public
    function Versao: string;
    function Montar(const AChamada: TChamada;
      const ACatalogo: TCatalogoVicios): TPayload;
  end;

implementation

const
  VERSAO_PROMPT = 'v2';

  FORMATO_RESPOSTA_JSON =
    '{' + sLineBreak +
    '  "vicio_geral": "resumo curto ou null",' + sLineBreak +
    '  "edicoes": [' + sLineBreak +
    '    {' + sLineBreak +
    '      "paragrafo_id": "cap-N-cena-M-pXX",' + sLineBreak +
    '      "chunk_index": 1,' + sLineBreak +
    '      "id_vicio": "id_do_catalogo",' + sLineBreak +
    '      "sugerido": "parágrafo COMPLETO revisado",' + sLineBreak +
    '      "motivo": "Ok ou Corrigido"' + sLineBreak +
    '    }' + sLineBreak +
    '  ]' + sLineBreak +
    '}';

{ TPromptVarredura }

function TPromptVarredura.Versao: string;
begin
  Result := VERSAO_PROMPT;
end;

function TPromptVarredura.Montar(const AChamada: TChamada;
  const ACatalogo: TCatalogoVicios): TPayload;
begin
  if AChamada = nil then
    raise EValorInvalido.Create('Chamada não pode ser nil.');
  if ACatalogo = nil then
    raise EValorInvalido.Create('Catálogo não pode ser nil.');

  Result.System := MontarSystem(AChamada, ACatalogo);
  Result.User := MontarUser(AChamada);
  Result.Modelo := AChamada.Modelo;
  Result.Temperature := AChamada.Temperature;
  Result.MaxTokens := AChamada.MaxTokens;
  Result.ResponseFormat := 'json_object';
  Result.Versao := VERSAO_PROMPT;
end;

function TPromptVarredura.MontarSystem(const AChamada: TChamada;
  const ACatalogo: TCatalogoVicios): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('Você é um editor literário de ficção em português brasileiro.');
    SB.AppendLine('Sua tarefa é IDENTIFICAR e CORRIGIR vícios editoriais na cena');
    SB.AppendLine('enviada. Percorra o texto com atenção e aponte apenas os');
    SB.AppendLine('problemas que realmente existem.');
    SB.AppendLine;
    SB.AppendLine('Regras:');
    SB.AppendLine('- Use APENAS os vícios listados em [CATÁLOGO].');
    SB.AppendLine('- Não invente categorias novas nem reformule por preferência');
    SB.AppendLine('  pessoal: só aponte o que se encaixa em um vício do catálogo.');
    SB.AppendLine('- Faça edições cirúrgicas: mude só o trecho afetado.');
    SB.AppendLine('- Devolva no campo "sugerido" o PARÁGRAFO INTEIRO revisado,');
    SB.AppendLine('  não apenas o trecho alterado.');
    SB.AppendLine('- Se NÃO houver correção, use "motivo": "Ok".');
    SB.AppendLine('- Se houver correção aplicada, use "motivo": "Corrigido".');
    SB.AppendLine('- NÃO escreva explicações no campo "motivo".');
    SB.AppendLine('- Preserve sentido e tom do original.');
    SB.AppendLine('- Não invente informação nova no texto sugerido.');
    SB.AppendLine('- Se um parágrafo não tiver vício, não o inclua na resposta.');
    SB.AppendLine('- Se a cena inteira estiver limpa, devolva lista vazia.');
    SB.AppendLine;
    SB.AppendLine('Responda SOMENTE com JSON no formato abaixo, sem markdown,');
    SB.AppendLine('sem texto antes ou depois:');
    SB.AppendLine(FORMATO_RESPOSTA_JSON);
    SB.AppendLine;
    SB.AppendLine('Se não encontrar nenhum vício:');
    SB.AppendLine('{"vicio_geral": null, "edicoes": []}');
    SB.AppendLine;
    SB.AppendLine('[CATÁLOGO]');
    SB.Append(MontarBlocoCatalogo(ACatalogo));

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TPromptVarredura.MontarBlocoCatalogo(
  const ACatalogo: TCatalogoVicios): string;
var
  SB: TStringBuilder;
  V: TVicio;
  Ordenados: TArray<TVicio>;
begin
  SB := TStringBuilder.Create;
  try
    Ordenados := ACatalogo.Categorias.ToArray;

    TArray.Sort<TVicio>(Ordenados,
      TComparer<TVicio>.Construct(
        function(const A, B: TVicio): Integer
        begin
          Result := CompareStr(A.ID, B.ID);
        end));

    for V in Ordenados do
      SB.Append('- ').Append(V.ID).Append(': ')
        .AppendLine(V.DicaCorrecao);

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TPromptVarredura.MontarUser(const AChamada: TChamada): string;
var
  SB: TStringBuilder;
  Obs: string;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('[CENA]');
    SB.Append(MontarBlocoParagrafos(AChamada));

    Obs := AChamada.ObservacaoUsuario.Trim;
    if Obs <> '' then
    begin
      SB.AppendLine;
      SB.Append(MontarBlocoObservacao(Obs));
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TPromptVarredura.MontarBlocoParagrafos(
  const AChamada: TChamada): string;
var
  SB: TStringBuilder;
  Sel: TParagrafoSelecionado;
begin
  SB := TStringBuilder.Create;
  try
    for Sel in AChamada.Selecoes do
    begin
      SB.Append('[').Append(Sel.ParagrafoID).AppendLine(']');
      SB.AppendLine(Sel.Texto);
      SB.AppendLine;
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TPromptVarredura.MontarBlocoObservacao(
  const AObs: string): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('[OBSERVAÇÃO DO AUTOR]');
    SB.AppendLine('Considere as instruções abaixo ao revisar. Elas têm');
    SB.AppendLine('prioridade sobre as regras gerais quando houver conflito:');
    SB.AppendLine(AObs);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
