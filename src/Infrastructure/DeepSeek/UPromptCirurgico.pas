unit UPromptCirurgico;

{
  UPromptCirurgico.pas
  ─────────────────────────────────────────────────────────────
  Construtor de prompt no modo cirúrgico.

  Nesta versão:
    • Campo "motivo" restrito a "Ok" ou "Corrigido".
      Reduz tokens de saída sem perder informação útil
      (se houve ou não correção).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  UIConstrutorPrompt,
  UChamada,
  UVicio,
  UValores;

type
  TPromptCirurgico = class(TInterfacedObject, IConstrutorPrompt)
  private
    function MontarSystem(const AChamada: TChamada;
      const ACatalogo: TCatalogoVicios): string;
    function MontarUser(const AChamada: TChamada): string;
    function MontarBlocoVicios(const AViciosIDs: TArray<string>;
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
  VERSAO_PROMPT = 'v1';

  FORMATO_RESPOSTA_JSON =
    '{' + sLineBreak +
    '  "vicio_geral": "resumo curto ou null",' + sLineBreak +
    '  "edicoes": [' + sLineBreak +
    '    {' + sLineBreak +
    '      "paragrafo_id": "cap-N-cena-M-pXX",' + sLineBreak +
    '      "chunk_index": 1,' + sLineBreak +
    '      "id_vicio": "id_do_vicio_listado",' + sLineBreak +
    '      "sugerido": "parágrafo COMPLETO revisado",' + sLineBreak +
    '      "motivo": "Ok ou Corrigido"' + sLineBreak +
    '    }' + sLineBreak +
    '  ]' + sLineBreak +
    '}';

{ TPromptCirurgico }

function TPromptCirurgico.Versao: string;
begin
  Result := VERSAO_PROMPT;
end;

function TPromptCirurgico.Montar(const AChamada: TChamada;
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

function TPromptCirurgico.MontarSystem(const AChamada: TChamada;
  const ACatalogo: TCatalogoVicios): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('Você é um editor literário de ficção em português brasileiro.');
    SB.AppendLine('Analise os parágrafos enviados e aplique APENAS os vícios');
    SB.AppendLine('listados em [VÍCIOS]. Não invente categorias novas.');
    SB.AppendLine;
    SB.AppendLine('Regras:');
    SB.AppendLine('- Faça edições cirúrgicas: mude só o trecho afetado.');
    SB.AppendLine('- Devolva no campo "sugerido" o PARÁGRAFO INTEIRO revisado,');
    SB.AppendLine('  não apenas o trecho alterado.');
    SB.AppendLine('- Se NÃO houver correção a fazer, devolva o parágrafo');
    SB.AppendLine('  inalterado e use "motivo": "Ok".');
    SB.AppendLine('- Se houver correção aplicada, use "motivo": "Corrigido".');
    SB.AppendLine('- NÃO escreva explicações no campo "motivo".');
    SB.AppendLine('- Preserve sentido e tom do original.');
    SB.AppendLine('- Não invente informação nova no texto sugerido.');
    SB.AppendLine('- Se não houver vício no parágrafo, não o inclua na resposta.');
    SB.AppendLine;
    SB.AppendLine('Responda SOMENTE com JSON no formato abaixo, sem markdown,');
    SB.AppendLine('sem texto antes ou depois:');
    SB.AppendLine(FORMATO_RESPOSTA_JSON);
    SB.AppendLine;
    SB.AppendLine('Se não encontrar nenhum vício:');
    SB.AppendLine('{"vicio_geral": null, "edicoes": []}');
    SB.AppendLine;
    SB.AppendLine('[VÍCIOS]');
    SB.Append(MontarBlocoVicios(AChamada.ViciosInjetados.ToArray, ACatalogo));

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TPromptCirurgico.MontarBlocoVicios(const AViciosIDs: TArray<string>;
  const ACatalogo: TCatalogoVicios): string;
var
  SB: TStringBuilder;
  ID: string;
  V: TVicio;
  Dica: string;
begin
  SB := TStringBuilder.Create;
  try
    for ID in AViciosIDs do
    begin
      V := ACatalogo.VicioPorID(ID);
      if Assigned(V) then
        Dica := V.DicaCorrecao
      else
        Dica := '(sem dica disponível)';

      SB.Append('- ').Append(ID).Append(': ').AppendLine(Dica);
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TPromptCirurgico.MontarUser(const AChamada: TChamada): string;
var
  SB: TStringBuilder;
  Obs: string;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('[PARÁGRAFOS]');
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

function TPromptCirurgico.MontarBlocoParagrafos(
  const AChamada: TChamada): string;
var
  SB: TStringBuilder;
  Sel: TParagrafoSelecionado;
  Cabecalho: string;
begin
  SB := TStringBuilder.Create;
  try
    for Sel in AChamada.Selecoes do
    begin
      Cabecalho := Format('[%s | chunk %d/%d | vicio: %s]',
        [Sel.ParagrafoID, Sel.ChunkIndex, Sel.ChunksTotais, Sel.VicioID]);
      SB.AppendLine(Cabecalho);
      SB.AppendLine(Sel.Texto);
      SB.AppendLine;
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TPromptCirurgico.MontarBlocoObservacao(
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
