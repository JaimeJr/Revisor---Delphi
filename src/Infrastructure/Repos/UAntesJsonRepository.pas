unit UAntesJsonRepository;

{
  UAntesJsonRepository.pas
  ─────────────────────────────────────────────────────────────
  Persistência do Antes.JSON e do parse.log.

  O Antes.JSON é a fonte da verdade imutável. Depois de gravado,
  nunca é sobrescrito pela aplicação (mas a escrita é idempotente:
  regravar o mesmo conteúdo produz o mesmo arquivo).

  Formato dos arquivos:
    Antes.JSON    → manuscrito completo (sem campos de edição)
    *_parse.log   → log de anomalias + resumo do parse

  Decisões:
    • Datas em ISO 8601 UTC (sufixo "Z").
    • Enums em string minúscula (via helpers de UValores).
    • Escrita atômica (arquivo temporário + rename) para não
      corromper em caso de crash.
    • Codificação UTF-8 sem BOM.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UIAntesRepository,
  UManuscrito,
  UAnomaliaParse;

type
  TAntesJsonRepository = class(TInterfacedObject, IAntesRepository)
  public
    procedure Salvar(const AManuscrito: TManuscrito;
      const ACaminho: string);

    function Carregar(const ACaminho: string): TManuscrito;

    function Existe(const ACaminho: string): Boolean;

    procedure SalvarLog(const ALog: TParseLog;
      const ACaminhoAntes: string);

    function CarregarLog(const ACaminhoAntes: string): TParseLog;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  System.TimeSpan,
  System.JSON,
  UValores;

const
  VERSAO_SCHEMA_ANTES = 1;
  VERSAO_SCHEMA_LOG = 1;

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

function CaminhoLogParaAntes(const ACaminhoAntes: string): string;
begin
  Result := TPath.Combine(
    TPath.GetDirectoryName(ACaminhoAntes),
    TPath.GetFileNameWithoutExtension(ACaminhoAntes) + '_parse.log');
end;

// ────────────────────────────────────────────────────────────
// Serialização: Manuscrito → JSON
// ────────────────────────────────────────────────────────────

function ParagrafoParaJson(const APar: TParagrafo): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', APar.ID);
  Result.AddPair('ordem', TJSONNumber.Create(APar.Ordem));
  Result.AddPair('texto', APar.Texto);
  Result.AddPair('hash', APar.Hash);
  Result.AddPair('num_palavras', TJSONNumber.Create(APar.NumPalavras));
  Result.AddPair('num_chunks', TJSONNumber.Create(APar.NumChunks));
end;

function CenaParaJson(const ACena: TCena): TJSONObject;
var
  ArranjoPar: TJSONArray;
  Par: TParagrafo;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', ACena.ID);
  Result.AddPair('numero', TJSONNumber.Create(ACena.Numero));

  ArranjoPar := TJSONArray.Create;
  for Par in ACena.Paragrafos do
    ArranjoPar.AddElement(ParagrafoParaJson(Par));

  Result.AddPair('paragrafos', ArranjoPar);
end;

function CapituloParaJson(const ACap: TCapitulo): TJSONObject;
var
  ArranjoCena: TJSONArray;
  Cena: TCena;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', ACap.ID);
  Result.AddPair('numero', TJSONNumber.Create(ACap.Numero));
  Result.AddPair('titulo', ACap.Titulo);

  ArranjoCena := TJSONArray.Create;
  for Cena in ACap.Cenas do
    ArranjoCena.AddElement(CenaParaJson(Cena));

  Result.AddPair('cenas', ArranjoCena);
end;

function AtoParaJson(const AAto: TAto): TJSONObject;
var
  ArranjoCap: TJSONArray;
  Cap: TCapitulo;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', AAto.ID);
  Result.AddPair('numero', TJSONNumber.Create(AAto.Numero));

  ArranjoCap := TJSONArray.Create;
  for Cap in AAto.Capitulos do
    ArranjoCap.AddElement(CapituloParaJson(Cap));

  Result.AddPair('capitulos', ArranjoCap);
end;

function ManuscritoParaJson(const AManuscrito: TManuscrito): TJSONObject;
var
  ArranjoAto: TJSONArray;
  Ato: TAto;
begin
  Result := TJSONObject.Create;
  Result.AddPair('versao_schema', TJSONNumber.Create(VERSAO_SCHEMA_ANTES));
  Result.AddPair('gerado_em', DataHoraParaISO(AManuscrito.GeradoEm));
  Result.AddPair('arquivo_origem', AManuscrito.ArquivoOrigem);
  Result.AddPair('hash_arquivo', AManuscrito.HashArquivo);
  Result.AddPair('titulo', AManuscrito.Titulo);

  ArranjoAto := TJSONArray.Create;
  for Ato in AManuscrito.Atos do
    ArranjoAto.AddElement(AtoParaJson(Ato));

  Result.AddPair('atos', ArranjoAto);
end;

// ────────────────────────────────────────────────────────────
// Desserialização: JSON → Manuscrito
// ────────────────────────────────────────────────────────────

function JsonParaParagrafo(const AObj: TJSONObject): TParagrafo;
begin
  Result := TParagrafo.Create;
  try
    Result.ID := AObj.GetValue<string>('id');
    Result.Ordem := AObj.GetValue<Integer>('ordem');
    Result.Texto := AObj.GetValue<string>('texto');
    Result.Hash := AObj.GetValue<string>('hash');
    Result.NumPalavras := AObj.GetValue<Integer>('num_palavras');
    Result.NumChunks := AObj.GetValue<Integer>('num_chunks');
  except
    Result.Free;
    raise;
  end;
end;

function JsonParaCena(const AObj: TJSONObject): TCena;
var
  Arranjo: TJSONArray;
  I: Integer;
begin
  Result := TCena.Create;
  try
    Result.ID := AObj.GetValue<string>('id');
    Result.Numero := AObj.GetValue<Integer>('numero');

    Arranjo := AObj.GetValue<TJSONArray>('paragrafos');
    for I := 0 to Arranjo.Count - 1 do
      Result.Paragrafos.Add(
        JsonParaParagrafo(Arranjo.Items[I] as TJSONObject));
  except
    Result.Free;
    raise;
  end;
end;

function JsonParaCapitulo(const AObj: TJSONObject): TCapitulo;
var
  Arranjo: TJSONArray;
  I: Integer;
begin
  Result := TCapitulo.Create;
  try
    Result.ID := AObj.GetValue<string>('id');
    Result.Numero := AObj.GetValue<Integer>('numero');
    Result.Titulo := AObj.GetValue<string>('titulo');

    Arranjo := AObj.GetValue<TJSONArray>('cenas');
    for I := 0 to Arranjo.Count - 1 do
      Result.Cenas.Add(
        JsonParaCena(Arranjo.Items[I] as TJSONObject));
  except
    Result.Free;
    raise;
  end;
end;

function JsonParaAto(const AObj: TJSONObject): TAto;
var
  Arranjo: TJSONArray;
  I: Integer;
begin
  Result := TAto.Create;
  try
    Result.ID := AObj.GetValue<string>('id');
    Result.Numero := AObj.GetValue<Integer>('numero');

    Arranjo := AObj.GetValue<TJSONArray>('capitulos');
    for I := 0 to Arranjo.Count - 1 do
      Result.Capitulos.Add(
        JsonParaCapitulo(Arranjo.Items[I] as TJSONObject));
  except
    Result.Free;
    raise;
  end;
end;

function JsonParaManuscrito(const AObj: TJSONObject): TManuscrito;
var
  Arranjo: TJSONArray;
  I: Integer;
  Versao: Integer;
begin
  Versao := AObj.GetValue<Integer>('versao_schema');
  if Versao <> VERSAO_SCHEMA_ANTES then
    raise EValorInvalido.CreateFmt(
      'Versão de schema do Antes.JSON não suportada: %d (esperado %d). ' +
      'Aplique a migração apropriada antes de carregar.',
      [Versao, VERSAO_SCHEMA_ANTES]);

  Result := TManuscrito.Create;
  try
    Result.VersaoSchema := Versao;
    Result.GeradoEm := ISOParaDataHora(AObj.GetValue<string>('gerado_em'));
    Result.ArquivoOrigem := AObj.GetValue<string>('arquivo_origem');
    Result.HashArquivo := AObj.GetValue<string>('hash_arquivo');
    Result.Titulo := AObj.GetValue<string>('titulo');

    Arranjo := AObj.GetValue<TJSONArray>('atos');
    for I := 0 to Arranjo.Count - 1 do
      Result.Atos.Add(
        JsonParaAto(Arranjo.Items[I] as TJSONObject));
  except
    Result.Free;
    raise;
  end;
end;

// ────────────────────────────────────────────────────────────
// Serialização: ParseLog → JSON
// ────────────────────────────────────────────────────────────

function ResumoParaJson(const AResumo: TResumoParse): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('atos', TJSONNumber.Create(AResumo.Atos));
  Result.AddPair('capitulos', TJSONNumber.Create(AResumo.Capitulos));
  Result.AddPair('cenas', TJSONNumber.Create(AResumo.Cenas));
  Result.AddPair('paragrafos', TJSONNumber.Create(AResumo.Paragrafos));
  Result.AddPair('palavras', TJSONNumber.Create(AResumo.Palavras));
  Result.AddPair('paragrafos_grandes',
    TJSONNumber.Create(AResumo.ParagrafosGrandes));
end;

function AnomaliaParaJson(const AAnomalia: TAnomaliaParse): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('severidade', AAnomalia.Severidade.ToStr);
  Result.AddPair('tipo', AAnomalia.Tipo.ToStr);
  Result.AddPair('localizacao', AAnomalia.Localizacao);
  Result.AddPair('detalhe', AAnomalia.Detalhe);
  Result.AddPair('timestamp', DataHoraParaISO(AAnomalia.Timestamp));
end;

function ParseLogParaJson(const ALog: TParseLog): TJSONObject;
var
  Arranjo: TJSONArray;
  A: TAnomaliaParse;
begin
  Result := TJSONObject.Create;
  Result.AddPair('versao_schema', TJSONNumber.Create(VERSAO_SCHEMA_LOG));
  Result.AddPair('arquivo', ALog.Arquivo);
  Result.AddPair('timestamp', DataHoraParaISO(ALog.Timestamp));
  Result.AddPair('resumo', ResumoParaJson(ALog.Resumo));

  Arranjo := TJSONArray.Create;
  for A in ALog.Anomalias do
    Arranjo.AddElement(AnomaliaParaJson(A));

  Result.AddPair('anomalias', Arranjo);
end;

// ────────────────────────────────────────────────────────────
// Desserialização: JSON → ParseLog
// ────────────────────────────────────────────────────────────

procedure JsonParaResumo(const AObj: TJSONObject; const AResumo: TResumoParse);
begin
  AResumo.Atos := AObj.GetValue<Integer>('atos');
  AResumo.Capitulos := AObj.GetValue<Integer>('capitulos');
  AResumo.Cenas := AObj.GetValue<Integer>('cenas');
  AResumo.Paragrafos := AObj.GetValue<Integer>('paragrafos');
  AResumo.Palavras := AObj.GetValue<Integer>('palavras');
  AResumo.ParagrafosGrandes := AObj.GetValue<Integer>('paragrafos_grandes');
end;

function JsonParaAnomalia(const AObj: TJSONObject): TAnomaliaParse;
begin
  Result := TAnomaliaParse.Create;
  Result.Severidade := TSeveridadeAnomalia.FromStr(
    AObj.GetValue<string>('severidade'));
  Result.Tipo := TTipoAnomalia.FromStr(
    AObj.GetValue<string>('tipo'));
  Result.Localizacao := AObj.GetValue<string>('localizacao');
  Result.Detalhe := AObj.GetValue<string>('detalhe');
  Result.Timestamp := ISOParaDataHora(
    AObj.GetValue<string>('timestamp'));
end;

function JsonParaParseLog(const AObj: TJSONObject): TParseLog;
var
  Arranjo: TJSONArray;
  I, Versao: Integer;
begin
  Versao := AObj.GetValue<Integer>('versao_schema');
  if Versao <> VERSAO_SCHEMA_LOG then
    raise EValorInvalido.CreateFmt(
      'Versão de schema do parse.log não suportada: %d (esperado %d).',
      [Versao, VERSAO_SCHEMA_LOG]);

  Result := TParseLog.Create;
  try
    Result.VersaoSchema := Versao;
    Result.Arquivo := AObj.GetValue<string>('arquivo');
    Result.Timestamp := ISOParaDataHora(AObj.GetValue<string>('timestamp'));

    JsonParaResumo(AObj.GetValue<TJSONObject>('resumo'), Result.Resumo);

    Arranjo := AObj.GetValue<TJSONArray>('anomalias');
    for I := 0 to Arranjo.Count - 1 do
      Result.Anomalias.Add(
        JsonParaAnomalia(Arranjo.Items[I] as TJSONObject));
  except
    Result.Free;
    raise;
  end;
end;

// ────────────────────────────────────────────────────────────
// TAntesJsonRepository
// ────────────────────────────────────────────────────────────

procedure TAntesJsonRepository.Salvar(const AManuscrito: TManuscrito;
  const ACaminho: string);
var
  Json: TJSONObject;
  Texto: string;
begin
  if AManuscrito = nil then
    raise EValorInvalido.Create('Manuscrito não pode ser nil.');

  Json := ManuscritoParaJson(AManuscrito);
  try
    Texto := Json.Format(2);
  finally
    Json.Free;
  end;

  EscreverArquivoAtomico(Texto, ACaminho);
end;

function TAntesJsonRepository.Carregar(const ACaminho: string): TManuscrito;
var
  Texto: string;
  Valor: TJSONValue;
begin
  Texto := LerArquivoTexto(ACaminho);

  Valor := TJSONObject.ParseJSONValue(Texto);
  if not Assigned(Valor) then
    raise EValorInvalido.CreateFmt(
      'Conteúdo de "%s" não é JSON válido.', [ACaminho]);

  try
    if not (Valor is TJSONObject) then
      raise EValorInvalido.CreateFmt(
        'Esperado objeto JSON em "%s".', [ACaminho]);

    Result := JsonParaManuscrito(Valor as TJSONObject);
  finally
    Valor.Free;
  end;
end;

function TAntesJsonRepository.Existe(const ACaminho: string): Boolean;
begin
  Result := TFile.Exists(ACaminho);
end;

procedure TAntesJsonRepository.SalvarLog(const ALog: TParseLog;
  const ACaminhoAntes: string);
var
  Json: TJSONObject;
  Texto, CaminhoLog: string;
begin
  if ALog = nil then
    raise EValorInvalido.Create('Log não pode ser nil.');

  Json := ParseLogParaJson(ALog);
  try
    Texto := Json.Format(2);
  finally
    Json.Free;
  end;

  CaminhoLog := CaminhoLogParaAntes(ACaminhoAntes);
  EscreverArquivoAtomico(Texto, CaminhoLog);
end;

function TAntesJsonRepository.CarregarLog(
  const ACaminhoAntes: string): TParseLog;
var
  CaminhoLog, Texto: string;
  Valor: TJSONValue;
begin
  CaminhoLog := CaminhoLogParaAntes(ACaminhoAntes);

  if not TFile.Exists(CaminhoLog) then
    raise Exception.CreateFmt('Arquivo de log não encontrado: %s',
      [CaminhoLog]);

  Texto := LerArquivoTexto(CaminhoLog);

  Valor := TJSONObject.ParseJSONValue(Texto);
  if not Assigned(Valor) then
    raise EValorInvalido.CreateFmt(
      'Conteúdo de "%s" não é JSON válido.', [CaminhoLog]);

  try
    if not (Valor is TJSONObject) then
      raise EValorInvalido.CreateFmt(
        'Esperado objeto JSON em "%s".', [CaminhoLog]);

    Result := JsonParaParseLog(Valor as TJSONObject);
  finally
    Valor.Free;
  end;
end;

end.
