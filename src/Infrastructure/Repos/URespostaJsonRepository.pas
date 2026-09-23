unit URespostaJsonRepository;

{
  URespostaJsonRepository.pas
  ─────────────────────────────────────────────────────────────
  Implementação de IRespostaRepository gravando em JSON.

  Estratégia: mesmo padrão do Envio. O arquivo inteiro é
  carregado, a nova entrada é anexada em memória, o arquivo é
  regravado.

  Particularidade: TResposta contém TEdicaoSugerida. Cada
  edição serializada com paragrafo_id, chunk_index, id_vicio,
  sugerido, motivo. Sem campo "original" (decisão travada —
  original vem do Envio.JSON).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UIRespostaRepository;

type
  TRespostaJsonRepository = class(TInterfacedObject, IRespostaRepository)
  public
    procedure Append(const AResposta: TResposta; const ACaminho: string);

    function BuscarPorChamada(const AIDChamada,
      ACaminho: string): TResposta;

    function TodasDaChamada(const AIDChamada,
      ACaminho: string): TArray<TResposta>;

    function TotalRespostas(const ACaminho: string): Integer;

    function CustoAcumulado(const ACaminho: string): Double;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  System.TimeZone,
  System.JSON,
  System.Generics.Collections,
  UEdicaoSugerida,
  UValores;

const
  VERSAO_SCHEMA_RESPOSTA = 1;

// ────────────────────────────────────────────────────────────
// Utilitários internos
// ────────────────────────────────────────────────────────────

function DataHoraParaISO(const AData: TDateTime): string;
var
  UTC: TDateTime;
begin
  UTC := TTimeZone.Local.ToUniversalTime(AData);
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"', UTC);
end;

function ISOParaDataHora(const ATexto: string): TDateTime;
var
  UTC: TDateTime;
begin
  if Length(ATexto) < 19 then
    raise EValorInvalido.CreateFmt(
      'Data/hora em formato inválido: "%s".', [ATexto]);

  try
    UTC := EncodeDateTime(
      StrToInt(Copy(ATexto, 1, 4)),
      StrToInt(Copy(ATexto, 6, 2)),
      StrToInt(Copy(ATexto, 9, 2)),
      StrToInt(Copy(ATexto, 12, 2)),
      StrToInt(Copy(ATexto, 15, 2)),
      StrToInt(Copy(ATexto, 18, 2)),
      0);
  except
    on E: Exception do
      raise EValorInvalido.CreateFmt(
        'Falha ao interpretar data/hora "%s": %s', [ATexto, E.Message]);
  end;

  Result := TTimeZone.Local.ToLocalTime(UTC);
end;

procedure EscreverArquivoAtomico(const AConteudo, ACaminho: string);
var
  Temp: string;
begin
  Temp := ACaminho + '.tmp';

  TFile.WriteAllText(Temp, AConteudo, TEncoding.UTF8);

  if TFile.Exists(ACaminho) then
    TFile.Delete(ACaminho);

  TFile.Move(Temp, ACaminho);
end;

function LerArquivoTexto(const ACaminho: string): string;
begin
  if not TFile.Exists(ACaminho) then
    raise Exception.CreateFmt('Arquivo não encontrado: %s', [ACaminho]);
  Result := TFile.ReadAllText(ACaminho, TEncoding.UTF8);
end;

// ────────────────────────────────────────────────────────────
// Serialização: EdicaoSugerida
// ────────────────────────────────────────────────────────────

function EdicaoParaJson(const AEdicao: TEdicaoSugerida): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('paragrafo_id', AEdicao.ParagrafoID);
  Result.AddPair('chunk_index', TJSONNumber.Create(AEdicao.ChunkIndex));
  Result.AddPair('id_vicio', AEdicao.VicioID);
  Result.AddPair('sugerido', AEdicao.Sugerido);
  Result.AddPair('motivo', AEdicao.Motivo);
  // Sem "original" — decisão travada.
end;

function JsonParaEdicao(const AObj: TJSONObject): TEdicaoSugerida;
begin
  Result := TEdicaoSugerida.Create;
  Result.ParagrafoID := AObj.GetValue<string>('paragrafo_id');
  Result.ChunkIndex := AObj.GetValue<Integer>('chunk_index');
  Result.VicioID := AObj.GetValue<string>('id_vicio');
  Result.Sugerido := AObj.GetValue<string>('sugerido');
  Result.Motivo := AObj.GetValue<string>('motivo');
end;

// ────────────────────────────────────────────────────────────
// Serialização: Resposta
// ────────────────────────────────────────────────────────────

function RespostaParaJson(const AResposta: TResposta): TJSONObject;
var
  Arranjo: TJSONArray;
  E: TEdicaoSugerida;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_chamada', AResposta.IDChamada);
  Result.AddPair('timestamp', DataHoraParaISO(AResposta.Timestamp));
  Result.AddPair('tokens_prompt',
    TJSONNumber.Create(AResposta.TokensPrompt));
  Result.AddPair('tokens_resposta',
    TJSONNumber.Create(AResposta.TokensResposta));
  Result.AddPair('custo_estimado',
    TJSONNumber.Create(AResposta.CustoEstimado));
  Result.AddPair('resposta_bruta', AResposta.RespostaBruta);
  Result.AddPair('status_parse', AResposta.StatusParse.ToStr);
  Result.AddPair('vicio_geral', AResposta.VicioGeral);

  Arranjo := TJSONArray.Create;
  for E in AResposta.Edicoes do
    Arranjo.AddElement(EdicaoParaJson(E));
  Result.AddPair('edicoes', Arranjo);

  if AResposta.ErroParse <> '' then
    Result.AddPair('erro_parse', AResposta.ErroParse);
end;

function JsonParaResposta(const AObj: TJSONObject): TResposta;
var
  Arranjo: TJSONArray;
  I: Integer;
  ErroParse: string;
begin
  Result := TResposta.Create;
  try
    Result.IDChamada := AObj.GetValue<string>('id_chamada');
    Result.Timestamp := ISOParaDataHora(AObj.GetValue<string>('timestamp'));
    Result.TokensPrompt := AObj.GetValue<Integer>('tokens_prompt');
    Result.TokensResposta := AObj.GetValue<Integer>('tokens_resposta');
    Result.CustoEstimado := AObj.GetValue<Double>('custo_estimado');
    Result.RespostaBruta := AObj.GetValue<string>('resposta_bruta');
    Result.StatusParse := TStatusParse.FromStr(
      AObj.GetValue<string>('status_parse'));
    Result.VicioGeral := AObj.GetValue<string>('vicio_geral');

    Arranjo := AObj.GetValue<TJSONArray>('edicoes');
    for I := 0 to Arranjo.Count - 1 do
      Result.Edicoes.Add(
        JsonParaEdicao(Arranjo.Items[I] as TJSONObject));

    if AObj.TryGetValue<string>('erro_parse', ErroParse) then
      Result.ErroParse := ErroParse;
  except
    Result.Free;
    raise;
  end;
end;

// ────────────────────────────────────────────────────────────
// Leitura / escrita do arquivo inteiro
// ────────────────────────────────────────────────────────────

function CarregarTodas(const ACaminho: string): TObjectList<TResposta>;
var
  Texto: string;
  Valor: TJSONValue;
  Raiz: TJSONObject;
  Arranjo: TJSONArray;
  I, Versao: Integer;
begin
  Result := TObjectList<TResposta>.Create;

  if not TFile.Exists(ACaminho) then
    Exit;

  Texto := LerArquivoTexto(ACaminho);

  Valor := TJSONObject.ParseJSONValue(Texto);
  if not Assigned(Valor) then
  begin
    Result.Free;
    raise EValorInvalido.CreateFmt(
      'Conteúdo de "%s" não é JSON válido.', [ACaminho]);
  end;

  try
    if not (Valor is TJSONObject) then
    begin
      Result.Free;
      raise EValorInvalido.CreateFmt(
        'Esperado objeto JSON em "%s".', [ACaminho]);
    end;

    Raiz := Valor as TJSONObject;
    Versao := Raiz.GetValue<Integer>('versao_schema');
    if Versao <> VERSAO_SCHEMA_RESPOSTA then
    begin
      Result.Free;
      raise EValorInvalido.CreateFmt(
        'Versão de schema do Resposta.JSON não suportada: %d (esperado %d).',
        [Versao, VERSAO_SCHEMA_RESPOSTA]);
    end;

    Arranjo := Raiz.GetValue<TJSONArray>('respostas');
    for I := 0 to Arranjo.Count - 1 do
    begin
      try
        Result.Add(JsonParaResposta(Arranjo.Items[I] as TJSONObject));
      except
        Result.Free;
        raise;
      end;
    end;
  finally
    Valor.Free;
  end;
end;

procedure GravarTodas(const ARespostas: TObjectList<TResposta>;
  const ACaminho: string);
var
  Raiz: TJSONObject;
  Arranjo: TJSONArray;
  R: TResposta;
  Texto: string;
begin
  Raiz := TJSONObject.Create;
  try
    Raiz.AddPair('versao_schema', TJSONNumber.Create(VERSAO_SCHEMA_RESPOSTA));

    Arranjo := TJSONArray.Create;
    for R in ARespostas do
      Arranjo.AddElement(RespostaParaJson(R));
    Raiz.AddPair('respostas', Arranjo);

    Texto := Raiz.Format(2);
  finally
    Raiz.Free;
  end;

  EscreverArquivoAtomico(Texto, ACaminho);
end;

// ────────────────────────────────────────────────────────────
// TRespostaJsonRepository
// ────────────────────────────────────────────────────────────

procedure TRespostaJsonRepository.Append(const AResposta: TResposta;
  const ACaminho: string);
var
  Respostas: TObjectList<TResposta>;
begin
  if AResposta = nil then
    raise EValorInvalido.Create('Resposta não pode ser nil.');

  Respostas := CarregarTodas(ACaminho);
  try
    Respostas.Add(AResposta);
    GravarTodas(Respostas, ACaminho);
  finally
    Respostas.Free;
  end;
end;

function TRespostaJsonRepository.BuscarPorChamada(const AIDChamada,
  ACaminho: string): TResposta;
var
  Respostas: TObjectList<TResposta>;
  R: TResposta;
begin
  Respostas := CarregarTodas(ACaminho);
  try
    // Mais recente primeiro.
    for var I := Respostas.Count - 1 downto 0 do
    begin
      R := Respostas[I];
      if R.IDChamada = AIDChamada then
        Exit(R);
    end;
    Result := nil;
  finally
    if Assigned(Result) then
      Respostas.Extract(Result);
    Respostas.Free;
  end;
end;

function TRespostaJsonRepository.TodasDaChamada(const AIDChamada,
  ACaminho: string): TArray<TResposta>;
var
  Respostas: TObjectList<TResposta>;
  Resultado: TList<TResposta>;
  R: TResposta;
begin
  Respostas := CarregarTodas(ACaminho);
  Resultado := TList<TResposta>.Create;
  try
    for R in Respostas do
      if R.IDChamada = AIDChamada then
      begin
        Resultado.Add(R);
        Respostas.Extract(R);  // desvincula para não destruir
      end;

    Result := Resultado.ToArray;
  finally
    Resultado.Free;
    Respostas.Free;  // as extraídas já foram desvinculadas
  end;
end;

function TRespostaJsonRepository.TotalRespostas(
  const ACaminho: string): Integer;
var
  Respostas: TObjectList<TResposta>;
begin
  Respostas := CarregarTodas(ACaminho);
  try
    Result := Respostas.Count;
  finally
    Respostas.Free;
  end;
end;

function TRespostaJsonRepository.CustoAcumulado(
  const ACaminho: string): Double;
var
  Respostas: TObjectList<TResposta>;
  R: TResposta;
begin
  Result := 0;
  Respostas := CarregarTodas(ACaminho);
  try
    for R in Respostas do
      Result := Result + R.CustoEstimado;
  finally
    Respostas.Free;
  end;
end;

end.
