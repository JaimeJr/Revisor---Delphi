unit UEnvioJsonRepository;

{
  UEnvioJsonRepository.pas
  ─────────────────────────────────────────────────────────────
  Log append-only das chamadas à IA.

  Correção importante: Append chama Chamadas.Extract(AChamada)
  antes de liberar a lista, para não destruir a TChamada do
  chamador (bug de double-free).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UChamada,
  UIEnvioRepository;

type
  TEnvioJsonRepository = class(TInterfacedObject, IEnvioRepository)
  public
    procedure Append(const AChamada: TChamada; const ACaminho: string);

    function Buscar(const AIDChamada, ACaminho: string): TChamada;

    function ExisteComHash(const AHashPayload,
      ACaminho: string): Boolean;

    function BuscarPorHash(const AHashPayload,
      ACaminho: string): TChamada;

    function TotalChamadas(const ACaminho: string): Integer;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  System.JSON,
  System.Generics.Collections,
  UValores;

const
  VERSAO_SCHEMA_ENVIO = 1;
  PREFIXO_ID_CHAMADA = 'req-';
  DIGITOS_ID_CHAMADA = 4;

// ────────────────────────────────────────────────────────────
// Utilitários
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
// Serialização
// ────────────────────────────────────────────────────────────

function SelecaoParaJson(const ASel: TParagrafoSelecionado): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('paragrafo_id', ASel.ParagrafoID);
  Result.AddPair('vicio_id', ASel.VicioID);
  Result.AddPair('hash_paragrafo', ASel.HashParagrafo);
  Result.AddPair('texto', ASel.Texto);
  Result.AddPair('chunk_index', TJSONNumber.Create(ASel.ChunkIndex));
  Result.AddPair('chunks_totais', TJSONNumber.Create(ASel.ChunksTotais));
end;

function JsonParaSelecao(const AObj: TJSONObject): TParagrafoSelecionado;
begin
  Result := TParagrafoSelecionado.Create;
  Result.ParagrafoID := AObj.GetValue<string>('paragrafo_id');
  Result.VicioID := AObj.GetValue<string>('vicio_id');
  Result.HashParagrafo := AObj.GetValue<string>('hash_paragrafo');
  Result.Texto := AObj.GetValue<string>('texto');
  Result.ChunkIndex := AObj.GetValue<Integer>('chunk_index');
  Result.ChunksTotais := AObj.GetValue<Integer>('chunks_totais');
end;

function ChamadaParaJson(const AChamada: TChamada): TJSONObject;
var
  ArranjoSel, ArranjoVic: TJSONArray;
  Sel: TParagrafoSelecionado;
  V: string;
  Params: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_chamada', AChamada.IDChamada);
  Result.AddPair('timestamp', DataHoraParaISO(AChamada.Timestamp));
  Result.AddPair('cena_id', AChamada.CenaID);
  Result.AddPair('modo', AChamada.Modo.ToStr);

  ArranjoSel := TJSONArray.Create;
  for Sel in AChamada.Selecoes do
    ArranjoSel.AddElement(SelecaoParaJson(Sel));
  Result.AddPair('paragrafos', ArranjoSel);

  Result.AddPair('observacao_usuario', AChamada.ObservacaoUsuario);

  ArranjoVic := TJSONArray.Create;
  for V in AChamada.ViciosInjetados do
    ArranjoVic.Add(V);
  Result.AddPair('vicios_injetados', ArranjoVic);

  Result.AddPair('prompt_versao', AChamada.PromptVersao);
  Result.AddPair('vicios_versao', TJSONNumber.Create(AChamada.ViciosVersao));
  Result.AddPair('modelo', AChamada.Modelo);

  Params := TJSONObject.Create;
  Params.AddPair('temperature', TJSONNumber.Create(AChamada.Temperature));
  Params.AddPair('max_tokens', TJSONNumber.Create(AChamada.MaxTokens));
  Params.AddPair('response_format', 'json_object');
  Result.AddPair('params', Params);

  Result.AddPair('hash_payload', AChamada.HashPayload);
  Result.AddPair('tokens_estimados_input',
    TJSONNumber.Create(AChamada.TokensEstimadosInput));
end;

function JsonParaChamada(const AObj: TJSONObject): TChamada;
var
  Arranjo, ArranjoVic: TJSONArray;
  I: Integer;
  Params: TJSONObject;
begin
  Result := TChamada.Create;
  try
    Result.IDChamada := AObj.GetValue<string>('id_chamada');
    Result.Timestamp := ISOParaDataHora(AObj.GetValue<string>('timestamp'));
    Result.CenaID := AObj.GetValue<string>('cena_id');
    Result.Modo := TModoEnvio.FromStr(AObj.GetValue<string>('modo'));

    Arranjo := AObj.GetValue<TJSONArray>('paragrafos');
    for I := 0 to Arranjo.Count - 1 do
      Result.Selecoes.Add(
        JsonParaSelecao(Arranjo.Items[I] as TJSONObject));

    Result.ObservacaoUsuario :=
      AObj.GetValue<string>('observacao_usuario');

    ArranjoVic := AObj.GetValue<TJSONArray>('vicios_injetados');
    for I := 0 to ArranjoVic.Count - 1 do
      Result.ViciosInjetados.Add(ArranjoVic.Items[I].Value);

    Result.PromptVersao := AObj.GetValue<string>('prompt_versao');
    Result.ViciosVersao := AObj.GetValue<Integer>('vicios_versao');
    Result.Modelo := AObj.GetValue<string>('modelo');

    Params := AObj.GetValue<TJSONObject>('params');
    Result.Temperature := Params.GetValue<Double>('temperature');
    Result.MaxTokens := Params.GetValue<Integer>('max_tokens');

    Result.HashPayload := AObj.GetValue<string>('hash_payload');
    Result.TokensEstimadosInput :=
      AObj.GetValue<Integer>('tokens_estimados_input');
  except
    Result.Free;
    raise;
  end;
end;

// ────────────────────────────────────────────────────────────
// Leitura / escrita
// ────────────────────────────────────────────────────────────

function CarregarTodas(const ACaminho: string): TObjectList<TChamada>;
var
  Texto: string;
  Valor: TJSONValue;
  Raiz: TJSONObject;
  Arranjo: TJSONArray;
  I, Versao: Integer;
begin
  Result := TObjectList<TChamada>.Create;

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
    if Versao <> VERSAO_SCHEMA_ENVIO then
    begin
      Result.Free;
      raise EValorInvalido.CreateFmt(
        'Versão de schema do Envio.JSON não suportada: %d (esperado %d).',
        [Versao, VERSAO_SCHEMA_ENVIO]);
    end;

    Arranjo := Raiz.GetValue<TJSONArray>('chamadas');
    for I := 0 to Arranjo.Count - 1 do
    begin
      try
        Result.Add(JsonParaChamada(Arranjo.Items[I] as TJSONObject));
      except
        Result.Free;
        raise;
      end;
    end;
  finally
    Valor.Free;
  end;
end;

procedure GravarTodas(const AChamadas: TObjectList<TChamada>;
  const ACaminho: string);
var
  Raiz: TJSONObject;
  Arranjo: TJSONArray;
  C: TChamada;
  Texto: string;
begin
  Raiz := TJSONObject.Create;
  try
    Raiz.AddPair('versao_schema', TJSONNumber.Create(VERSAO_SCHEMA_ENVIO));

    Arranjo := TJSONArray.Create;
    for C in AChamadas do
      Arranjo.AddElement(ChamadaParaJson(C));
    Raiz.AddPair('chamadas', Arranjo);

    Texto := Raiz.Format(2);
  finally
    Raiz.Free;
  end;

  EscreverArquivoAtomico(Texto, ACaminho);
end;

function ProximoIDChamada(const AChamadas: TObjectList<TChamada>): string;
var
  Maior, Atual: Integer;
  C: TChamada;
  NumeroStr: string;
begin
  Maior := 0;
  for C in AChamadas do
  begin
    NumeroStr := C.IDChamada;
    if NumeroStr.StartsWith(PREFIXO_ID_CHAMADA) then
    begin
      NumeroStr := Copy(NumeroStr,
        Length(PREFIXO_ID_CHAMADA) + 1, MaxInt);
      if TryStrToInt(NumeroStr, Atual) and (Atual > Maior) then
        Maior := Atual;
    end;
  end;

  Result := Format('%s%.*d',
    [PREFIXO_ID_CHAMADA, DIGITOS_ID_CHAMADA, Maior + 1]);
end;

// ────────────────────────────────────────────────────────────
// TEnvioJsonRepository
// ────────────────────────────────────────────────────────────

procedure TEnvioJsonRepository.Append(const AChamada: TChamada;
  const ACaminho: string);
var
  Chamadas: TObjectList<TChamada>;
begin
  if AChamada = nil then
    raise EValorInvalido.Create('Chamada não pode ser nil.');

  Chamadas := CarregarTodas(ACaminho);
  try
    if AChamada.IDChamada = '' then
      AChamada.IDChamada := ProximoIDChamada(Chamadas);

    Chamadas.Add(AChamada);
    GravarTodas(Chamadas, ACaminho);

    // ⚠ Desvincula antes do Free, para não destruir a AChamada
    // do chamador. Sem isso, Chamadas.Free libera AChamada
    // junto e o chamador segue com memória morta.
    Chamadas.Extract(AChamada);
  finally
    Chamadas.Free;
  end;
end;

function TEnvioJsonRepository.Buscar(const AIDChamada,
  ACaminho: string): TChamada;
var
  Chamadas: TObjectList<TChamada>;
  C: TChamada;
begin
  Chamadas := CarregarTodas(ACaminho);
  try
    for C in Chamadas do
      if C.IDChamada = AIDChamada then
      begin
        Chamadas.Extract(C);
        Exit(C);
      end;
    Result := nil;
  finally
    Chamadas.Free;
  end;
end;

function TEnvioJsonRepository.ExisteComHash(const AHashPayload,
  ACaminho: string): Boolean;
begin
  Result := Assigned(BuscarPorHash(AHashPayload, ACaminho));
end;

function TEnvioJsonRepository.BuscarPorHash(const AHashPayload,
  ACaminho: string): TChamada;
var
  Chamadas: TObjectList<TChamada>;
  C: TChamada;
  I: Integer;
begin
  Chamadas := CarregarTodas(ACaminho);
  try
    for I := Chamadas.Count - 1 downto 0 do
    begin
      C := Chamadas[I];
      if C.HashPayload = AHashPayload then
      begin
        Chamadas.Extract(C);
        Exit(C);
      end;
    end;
    Result := nil;
  finally
    Chamadas.Free;
  end;
end;

function TEnvioJsonRepository.TotalChamadas(const ACaminho: string): Integer;
var
  Chamadas: TObjectList<TChamada>;
begin
  Chamadas := CarregarTodas(ACaminho);
  try
    Result := Chamadas.Count;
  finally
    Chamadas.Free;
  end;
end;

end.
