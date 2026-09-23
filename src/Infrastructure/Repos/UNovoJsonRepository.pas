unit UNovoJsonRepository;

{
  UNovoJsonRepository.pas
  ─────────────────────────────────────────────────────────────
  Persistência do Novo.JSON — estado de trabalho da sessão.

  Diferenças em relação ao Antes.JSON:
    • Cada parágrafo carrega campos de edição:
        texto_original, status, revisoes[]
    • Não guarda arquivo_origem nem hash_arquivo (esses vivem
      só no Antes). Guarda baseado_em_hash_arquivo para
      detectar se o Antes original foi substituído.
    • Carregar retorna nil se o arquivo não existir — o Novo
      pode começar vazio numa sessão nova.
    • SalvarAuto é a operação principal (autosave a cada
      operação). Sobrescreve sempre.
    • Apagar descarta a sessão de trabalho.

  Decisões (iguais ao Antes):
    • Datas em ISO 8601 UTC.
    • Enums em string minúscula.
    • Escrita atômica.
    • UTF-8 sem BOM.
    • Duplicação controlada dos helpers de serialização
      (não compartilhados com o Antes, para permitir evolução
      independente).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UINovoRepository,
  UManuscrito;

type
  TNovoJsonRepository = class(TInterfacedObject, INovoRepository)
  public
    procedure SalvarAuto(const AManuscrito: TManuscrito;
      const ACaminho: string);

    function Carregar(const ACaminho: string): TManuscrito;

    function Existe(const ACaminho: string): Boolean;

    procedure Apagar(const ACaminho: string);
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
  VERSAO_SCHEMA_NOVO = 1;

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
// Serialização: RevisaoParagrafo → JSON
// ────────────────────────────────────────────────────────────

function RevisaoParaJson(const ARev: TRevisaoParagrafo): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_chamada', ARev.IDChamada);
  Result.AddPair('id_vicio', ARev.VicioID);
  Result.AddPair('hash_paragrafo_antes', ARev.HashParagrafoAntes);
  Result.AddPair('aceita', TJSONBool.Create(ARev.Aceita));
  Result.AddPair('timestamp', DataHoraParaISO(ARev.Timestamp));
end;

function JsonParaRevisao(const AObj: TJSONObject): TRevisaoParagrafo;
begin
  Result := TRevisaoParagrafo.Create;
  Result.IDChamada := AObj.GetValue<string>('id_chamada');
  Result.VicioID := AObj.GetValue<string>('id_vicio');
  Result.HashParagrafoAntes := AObj.GetValue<string>('hash_paragrafo_antes');
  Result.Aceita := AObj.GetValue<Boolean>('aceita');
  Result.Timestamp := ISOParaDataHora(AObj.GetValue<string>('timestamp'));
end;

// ────────────────────────────────────────────────────────────
// Serialização: Manuscrito → JSON (com campos de edição)
// ────────────────────────────────────────────────────────────

function ParagrafoParaJson(const APar: TParagrafo): TJSONObject;
var
  ArranjoRev: TJSONArray;
  Rev: TRevisaoParagrafo;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', APar.ID);
  Result.AddPair('ordem', TJSONNumber.Create(APar.Ordem));
  Result.AddPair('texto', APar.Texto);
  Result.AddPair('texto_original', APar.TextoOriginal);
  Result.AddPair('hash', APar.Hash);
  Result.AddPair('num_palavras', TJSONNumber.Create(APar.NumPalavras));
  Result.AddPair('num_chunks', TJSONNumber.Create(APar.NumChunks));
  Result.AddPair('status', APar.Status.ToStr);

  ArranjoRev := TJSONArray.Create;
  for Rev in APar.Revisoes do
    ArranjoRev.AddElement(RevisaoParaJson(Rev));

  Result.AddPair('revisoes', ArranjoRev);
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
  Result.AddPair('versao_schema', TJSONNumber.Create(VERSAO_SCHEMA_NOVO));
  Result.AddPair('atualizado_em', DataHoraParaISO(AManuscrito.GeradoEm));
  Result.AddPair('baseado_em_hash_arquivo', AManuscrito.HashArquivo);
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
var
  Arranjo: TJSONArray;
  I: Integer;
begin
  Result := TParagrafo.Create;
  try
    Result.ID := AObj.GetValue<string>('id');
    Result.Ordem := AObj.GetValue<Integer>('ordem');
    Result.Texto := AObj.GetValue<string>('texto');
    Result.TextoOriginal := AObj.GetValue<string>('texto_original');
    Result.Hash := AObj.GetValue<string>('hash');
    Result.NumPalavras := AObj.GetValue<Integer>('num_palavras');
    Result.NumChunks := AObj.GetValue<Integer>('num_chunks');
    Result.Status := TStatusParagrafo.FromStr(
      AObj.GetValue<string>('status'));

    Arranjo := AObj.GetValue<TJSONArray>('revisoes');
    for I := 0 to Arranjo.Count - 1 do
      Result.Revisoes.Add(
        JsonParaRevisao(Arranjo.Items[I] as TJSONObject));
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
  I, Versao: Integer;
begin
  Versao := AObj.GetValue<Integer>('versao_schema');
  if Versao <> VERSAO_SCHEMA_NOVO then
    raise EValorInvalido.CreateFmt(
      'Versão de schema do Novo.JSON não suportada: %d (esperado %d). ' +
      'Aplique a migração apropriada antes de carregar.',
      [Versao, VERSAO_SCHEMA_NOVO]);

  Result := TManuscrito.Create;
  try
    Result.VersaoSchema := Versao;
    Result.GeradoEm := ISOParaDataHora(AObj.GetValue<string>('atualizado_em'));
    Result.HashArquivo := AObj.GetValue<string>('baseado_em_hash_arquivo');
    Result.Titulo := AObj.GetValue<string>('titulo');
    // ArquivoOrigem não existe no Novo — fica vazio de propósito.

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
// TNovoJsonRepository
// ────────────────────────────────────────────────────────────

procedure TNovoJsonRepository.SalvarAuto(const AManuscrito: TManuscrito;
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

function TNovoJsonRepository.Carregar(const ACaminho: string): TManuscrito;
var
  Texto: string;
  Valor: TJSONValue;
begin
  // Diferença em relação ao Antes: Novo pode não existir.
  if not TFile.Exists(ACaminho) then
    Exit(nil);

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

function TNovoJsonRepository.Existe(const ACaminho: string): Boolean;
begin
  Result := TFile.Exists(ACaminho);
end;

procedure TNovoJsonRepository.Apagar(const ACaminho: string);
begin
  if TFile.Exists(ACaminho) then
    TFile.Delete(ACaminho);
end;

end.
