unit UNovoJsonRepository;

{
  UNovoJsonRepository.pas
  ─────────────────────────────────────────────────────────────
  Persistência do Novo.JSON — estado de trabalho da sessão.

  Nesta versão:
    • Cada parágrafo carrega gatilhos_disparados[], uma lista
      de disparos de gatilhos locais.
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
  System.JSON,
  UValores;

const
  VERSAO_SCHEMA_NOVO = 1;

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
// Serialização: RevisaoParagrafo
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
// Serialização: DisparoGatilho
// ────────────────────────────────────────────────────────────

function DisparoParaJson(const ADisp: TDisparoGatilho): TJSONObject;
var
  ArranjoTrechos: TJSONArray;
  T: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('gatilho_id', ADisp.GatilhoID);
  Result.AddPair('versao_gatilho', ADisp.VersaoGatilho);
  Result.AddPair('confianca', TJSONNumber.Create(ADisp.Confianca));

  ArranjoTrechos := TJSONArray.Create;
  for T in ADisp.Trechos do
    ArranjoTrechos.Add(T);
  Result.AddPair('trechos', ArranjoTrechos);

  Result.AddPair('hash_paragrafo_no_disparo',
    ADisp.HashParagrafoNoDisparo);
  Result.AddPair('quando', DataHoraParaISO(ADisp.Quando));
end;

function JsonParaDisparo(const AObj: TJSONObject): TDisparoGatilho;
var
  Arranjo: TJSONArray;
  I: Integer;
  Trechos: TArray<string>;
begin
  Result := TDisparoGatilho.Create;
  try
    Result.GatilhoID := AObj.GetValue<string>('gatilho_id');
    Result.VersaoGatilho := AObj.GetValue<string>('versao_gatilho');
    Result.Confianca := AObj.GetValue<Double>('confianca');

    if AObj.TryGetValue<TJSONArray>('trechos', Arranjo) then
    begin
      SetLength(Trechos, Arranjo.Count);
      for I := 0 to Arranjo.Count - 1 do
        Trechos[I] := Arranjo.Items[I].Value;
      Result.Trechos := Trechos;
    end;

    Result.HashParagrafoNoDisparo :=
      AObj.GetValue<string>('hash_paragrafo_no_disparo');
    Result.Quando := ISOParaDataHora(AObj.GetValue<string>('quando'));
  except
    Result.Free;
    raise;
  end;
end;

// ────────────────────────────────────────────────────────────
// Serialização: Manuscrito
// ────────────────────────────────────────────────────────────

function ParagrafoParaJson(const APar: TParagrafo): TJSONObject;
var
  ArranjoRev, ArranjoDisp: TJSONArray;
  Rev: TRevisaoParagrafo;
  Disp: TDisparoGatilho;
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

  ArranjoDisp := TJSONArray.Create;
  for Disp in APar.GatilhosDisparados do
    ArranjoDisp.AddElement(DisparoParaJson(Disp));
  Result.AddPair('gatilhos_disparados', ArranjoDisp);
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
// Desserialização
// ────────────────────────────────────────────────────────────

function JsonParaParagrafo(const AObj: TJSONObject): TParagrafo;
var
  ArranjoRev, ArranjoDisp: TJSONArray;
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

    if AObj.TryGetValue<TJSONArray>('revisoes', ArranjoRev) then
      for I := 0 to ArranjoRev.Count - 1 do
        Result.Revisoes.Add(
          JsonParaRevisao(ArranjoRev.Items[I] as TJSONObject));

    if AObj.TryGetValue<TJSONArray>('gatilhos_disparados', ArranjoDisp) then
      for I := 0 to ArranjoDisp.Count - 1 do
        Result.GatilhosDisparados.Add(
          JsonParaDisparo(ArranjoDisp.Items[I] as TJSONObject));
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
