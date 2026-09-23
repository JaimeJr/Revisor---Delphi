unit UManuscrito;

{
  UManuscrito.pas
  ─────────────────────────────────────────────────────────────
  Entidades do domínio que representam a estrutura de um
  manuscrito: Parágrafo, Cena, Capítulo, Ato, Manuscrito.

  Regras:
    • Apenas composição via TObjectList<T> (ownership explícito).
    • Nenhuma lógica de I/O, HTTP, VCL ou JSON.
    • TManuscrito é usado tanto para Antes.JSON quanto para
      Novo.JSON. Os campos de edição (TextoOriginal, Status,
      Revisoes) só são populados no Novo.JSON; no Antes ficam
      com valores default.
    • IDs seguem o formato definido em UValores (TID).
    • Toda navegação é linear — a árvore tem no máximo ~900
      parágrafos, e busca linear é mais que suficiente.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores;

type
  TRevisaoParagrafo = class;

  // ────────────────────────────────────────────────────────────
  // Parágrafo
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Menor unidade do manuscrito. Corresponde a um parágrafo
  ///   de "Texto Normal" no .docx.
  /// </summary>
  TParagrafo = class
  private
    FID: TID;
    FOrdem: Integer;
    FTexto: string;
    FHash: string;
    FNumPalavras: Integer;
    FNumChunks: Integer;

    // Campos de edição — só usados no Novo.JSON
    FTextoOriginal: string;
    FStatus: TStatusParagrafo;
    FRevisoes: TObjectList<TRevisaoParagrafo>;
  public
    constructor Create;
    destructor Destroy; override;

    property ID: TID read FID write FID;
    property Ordem: Integer read FOrdem write FOrdem;
    property Texto: string read FTexto write FTexto;
    property Hash: string read FHash write FHash;
    property NumPalavras: Integer read FNumPalavras write FNumPalavras;
    property NumChunks: Integer read FNumChunks write FNumChunks;

    property TextoOriginal: string read FTextoOriginal write FTextoOriginal;
    property Status: TStatusParagrafo read FStatus write FStatus;
    property Revisoes: TObjectList<TRevisaoParagrafo> read FRevisoes;

    /// <summary>True se o parágrafo excede LIMITE_PARAGRAFO_PALAVRAS.</summary>
    function EhGrande: Boolean;

    /// <summary>Adiciona uma entrada de revisão ao histórico.</summary>
    procedure AdicionarRevisao(const ARevisao: TRevisaoParagrafo);

    /// <summary>
    ///   True se já existe uma revisão registrada para o par
    ///   (texto atual + vício). Usado para alertar "já revisado".
    /// </summary>
    function JaRevisado(const AVicioID, AHashParagrafo: string): Boolean;

    /// <summary>Marca o parágrafo como revisado manualmente pelo usuário.</summary>
    procedure MarcarRevisadoManual;
  end;

  // ────────────────────────────────────────────────────────────
  // Revisão de parágrafo (VO)
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Registro histórico de uma revisão aplicada (ou recusada)
  ///   sobre um parágrafo. Persistido em Novo.JSON.revisoes[].
  /// </summary>
  TRevisaoParagrafo = class
  private
    FIDChamada: string;
    FVicioID: string;
    FHashParagrafoAntes: string;
    FAceita: Boolean;
    FTimestamp: TDateTime;
  public
    property IDChamada: string read FIDChamada write FIDChamada;
    property VicioID: string read FVicioID write FVicioID;
    property HashParagrafoAntes: string
      read FHashParagrafoAntes write FHashParagrafoAntes;
    property Aceita: Boolean read FAceita write FAceita;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;
  end;

  // ────────────────────────────────────────────────────────────
  // Cena
  // ────────────────────────────────────────────────────────────

  TCena = class
  private
    FID: TID;
    FNumero: Integer;
    FParagrafos: TObjectList<TParagrafo>;
  public
    constructor Create;
    destructor Destroy; override;

    property ID: TID read FID write FID;
    property Numero: Integer read FNumero write FNumero;
    property Paragrafos: TObjectList<TParagrafo> read FParagrafos;

    function ParagrafoPorID(const AID: TID): TParagrafo;
    function ParagrafoPorOrdem(const AOrdem: Integer): TParagrafo;
    function TotalPalavras: Integer;
  end;

  // ────────────────────────────────────────────────────────────
  // Capítulo
  // ────────────────────────────────────────────────────────────

  TCapitulo = class
  private
    FID: TID;
    FNumero: Integer;
    FTitulo: string;
    FCenas: TObjectList<TCena>;
  public
    constructor Create;
    destructor Destroy; override;

    property ID: TID read FID write FID;
    property Numero: Integer read FNumero write FNumero;
    property Titulo: string read FTitulo write FTitulo;
    property Cenas: TObjectList<TCena> read FCenas;

    function CenaPorID(const AID: TID): TCena;
    function CenaPorNumero(const ANumero: Integer): TCena;
    function TotalPalavras: Integer;
    function TemConteudo: Boolean;
  end;

  // ────────────────────────────────────────────────────────────
  // Ato
  // ────────────────────────────────────────────────────────────

  TAto = class
  private
    FID: TID;
    FNumero: Integer;
    FCapitulos: TObjectList<TCapitulo>;
  public
    constructor Create;
    destructor Destroy; override;

    property ID: TID read FID write FID;
    property Numero: Integer read FNumero write FNumero;
    property Capitulos: TObjectList<TCapitulo> read FCapitulos;

    function CapituloPorID(const AID: TID): TCapitulo;
    function CapituloPorNumero(const ANumero: Integer): TCapitulo;
    function TotalPalavras: Integer;
  end;

  // ────────────────────────────────────────────────────────────
  // Manuscrito
  // ────────────────────────────────────────────────────────────

  TManuscrito = class
  private
    FVersaoSchema: Integer;
    FTitulo: string;
    FGeradoEm: TDateTime;
    FHashArquivo: string;
    FArquivoOrigem: string;
    FAtos: TObjectList<TAto>;
  public
    constructor Create;
    destructor Destroy; override;

    property VersaoSchema: Integer read FVersaoSchema write FVersaoSchema;
    property Titulo: string read FTitulo write FTitulo;
    property GeradoEm: TDateTime read FGeradoEm write FGeradoEm;
    property HashArquivo: string read FHashArquivo write FHashArquivo;
    property ArquivoOrigem: string read FArquivoOrigem write FArquivoOrigem;
    property Atos: TObjectList<TAto> read FAtos;

    // Navegação
    function AtoPorNumero(const ANumero: Integer): TAto;
    function AtoDoCapitulo(const ANumeroCapitulo: Integer): TAto;
    function CapituloPorID(const AID: TID): TCapitulo;
    function CenaPorID(const AID: TID): TCena;
    function ParagrafoPorID(const AID: TID): TParagrafo;

    // Estatísticas
    function TotalPalavras: Integer;
    function TotalCapitulos: Integer;
    function TotalCenas: Integer;
    function TotalParagrafos: Integer;

    /// <summary>
    ///   Cria um novo manuscrito a partir do Antes, com campos
    ///   de edição inicializados (TextoOriginal := Texto,
    ///   Status := pendente, Revisoes := vazio).
    /// </summary>
    class function NovoAPartirDe(const AAntes: TManuscrito): TManuscrito;
  end;

// ────────────────────────────────────────────────────────────
// Utilidades de texto
// ────────────────────────────────────────────────────────────

/// <summary>
///   Conta palavras separadas por espaço em branco (inclui
///   NBSP). Não trata pontuação como separador — é uma
///   aproximação suficiente para o limite de 600.
/// </summary>
function ContarPalavras(const ATexto: string): Integer;

/// <summary>Gera ID de Ato no formato "act-N".</summary>
function GerarIDAto(const ANumero: Integer): TID;

/// <summary>Gera ID de Capítulo no formato "cap-N".</summary>
function GerarIDCapitulo(const ANumero: Integer): TID;

/// <summary>Gera ID de Cena no formato "cap-N-cena-M".</summary>
function GerarIDCena(const ANumeroCapitulo, ANumeroCena: Integer): TID;

/// <summary>Gera ID de Parágrafo no formato "cap-N-cena-M-pXX".</summary>
function GerarIDParagrafo(const ANumeroCapitulo, ANumeroCena,
  ANumeroParagrafo: Integer): TID;

implementation

// ────────────────────────────────────────────────────────────
// Utilidades
// ────────────────────────────────────────────────────────────

function ContarPalavras(const ATexto: string): Integer;
var
  I: Integer;
  DentroDePalavra: Boolean;
begin
  Result := 0;
  DentroDePalavra := False;
  for I := 1 to Length(ATexto) do
  begin
    if CharInSet(ATexto[I], [' ', #9, #10, #13, #160]) then
      DentroDePalavra := False
    else if not DentroDePalavra then
    begin
      Inc(Result);
      DentroDePalavra := True;
    end;
  end;
end;

function GerarIDAto(const ANumero: Integer): TID;
begin
  Result := Format('act-%d', [ANumero]);
end;

function GerarIDCapitulo(const ANumero: Integer): TID;
begin
  Result := Format('cap-%d', [ANumero]);
end;

function GerarIDCena(const ANumeroCapitulo, ANumeroCena: Integer): TID;
begin
  Result := Format('cap-%d-cena-%d', [ANumeroCapitulo, ANumeroCena]);
end;

function GerarIDParagrafo(const ANumeroCapitulo, ANumeroCena,
  ANumeroParagrafo: Integer): TID;
begin
  Result := Format('cap-%d-cena-%d-p%.2d',
    [ANumeroCapitulo, ANumeroCena, ANumeroParagrafo]);
end;

// ────────────────────────────────────────────────────────────
// TParagrafo
// ────────────────────────────────────────────────────────────

constructor TParagrafo.Create;
begin
  inherited;
  FStatus := spPendente;
  FNumChunks := 1;
  FRevisoes := TObjectList<TRevisaoParagrafo>.Create;
end;

destructor TParagrafo.Destroy;
begin
  FRevisoes.Free;
  inherited;
end;

function TParagrafo.EhGrande: Boolean;
begin
  Result := FNumPalavras > LIMITE_PARAGRAFO_PALAVRAS;
end;

procedure TParagrafo.AdicionarRevisao(const ARevisao: TRevisaoParagrafo);
begin
  if ARevisao = nil then
    raise EValorInvalido.Create('Revisão não pode ser nil.');
  FRevisoes.Add(ARevisao);
end;

function TParagrafo.JaRevisado(const AVicioID, AHashParagrafo: string): Boolean;
var
  Rev: TRevisaoParagrafo;
begin
  for Rev in FRevisoes do
    if SameText(Rev.VicioID, AVicioID) and
       (Rev.HashParagrafoAntes = AHashParagrafo) then
      Exit(True);
  Result := False;
end;

procedure TParagrafo.MarcarRevisadoManual;
begin
  FStatus := spRevisadoManual;
end;

// ────────────────────────────────────────────────────────────
// TCena
// ────────────────────────────────────────────────────────────

constructor TCena.Create;
begin
  inherited;
  FParagrafos := TObjectList<TParagrafo>.Create;
end;

destructor TCena.Destroy;
begin
  FParagrafos.Free;
  inherited;
end;

function TCena.ParagrafoPorID(const AID: TID): TParagrafo;
var
  P: TParagrafo;
begin
  for P in FParagrafos do
    if P.ID = AID then
      Exit(P);
  Result := nil;
end;

function TCena.ParagrafoPorOrdem(const AOrdem: Integer): TParagrafo;
var
  P: TParagrafo;
begin
  for P in FParagrafos do
    if P.Ordem = AOrdem then
      Exit(P);
  Result := nil;
end;

function TCena.TotalPalavras: Integer;
var
  P: TParagrafo;
begin
  Result := 0;
  for P in FParagrafos do
    Inc(Result, P.NumPalavras);
end;

// ────────────────────────────────────────────────────────────
// TCapitulo
// ────────────────────────────────────────────────────────────

constructor TCapitulo.Create;
begin
  inherited;
  FCenas := TObjectList<TCena>.Create;
end;

destructor TCapitulo.Destroy;
begin
  FCenas.Free;
  inherited;
end;

function TCapitulo.CenaPorID(const AID: TID): TCena;
var
  C: TCena;
begin
  for C in FCenas do
    if C.ID = AID then
      Exit(C);
  Result := nil;
end;

function TCapitulo.CenaPorNumero(const ANumero: Integer): TCena;
var
  C: TCena;
begin
  for C in FCenas do
    if C.Numero = ANumero then
      Exit(C);
  Result := nil;
end;

function TCapitulo.TotalPalavras: Integer;
var
  C: TCena;
begin
  Result := 0;
  for C in FCenas do
    Inc(Result, C.TotalPalavras);
end;

function TCapitulo.TemConteudo: Boolean;
begin
  Result := FCenas.Count > 0;
end;

// ────────────────────────────────────────────────────────────
// TAto
// ────────────────────────────────────────────────────────────

constructor TAto.Create;
begin
  inherited;
  FCapitulos := TObjectList<TCapitulo>.Create;
end;

destructor TAto.Destroy;
begin
  FCapitulos.Free;
  inherited;
end;

function TAto.CapituloPorID(const AID: TID): TCapitulo;
var
  C: TCapitulo;
begin
  for C in FCapitulos do
    if C.ID = AID then
      Exit(C);
  Result := nil;
end;

function TAto.CapituloPorNumero(const ANumero: Integer): TCapitulo;
var
  C: TCapitulo;
begin
  for C in FCapitulos do
    if C.Numero = ANumero then
      Exit(C);
  Result := nil;
end;

function TAto.TotalPalavras: Integer;
var
  C: TCapitulo;
begin
  Result := 0;
  for C in FCapitulos do
    Inc(Result, C.TotalPalavras);
end;

// ────────────────────────────────────────────────────────────
// TManuscrito
// ────────────────────────────────────────────────────────────

constructor TManuscrito.Create;
begin
  inherited;
  FVersaoSchema := 1;
  FGeradoEm := Now;
  FAtos := TObjectList<TAto>.Create;
end;

destructor TManuscrito.Destroy;
begin
  FAtos.Free;
  inherited;
end;

function TManuscrito.AtoPorNumero(const ANumero: Integer): TAto;
var
  A: TAto;
begin
  for A in FAtos do
    if A.Numero = ANumero then
      Exit(A);
  Result := nil;
end;

function TManuscrito.AtoDoCapitulo(const ANumeroCapitulo: Integer): TAto;
var
  A: TAto;
begin
  for A in FAtos do
    if Assigned(A.CapituloPorNumero(ANumeroCapitulo)) then
      Exit(A);
  Result := nil;
end;

function TManuscrito.CapituloPorID(const AID: TID): TCapitulo;
var
  A: TAto;
  C: TCapitulo;
begin
  for A in FAtos do
  begin
    C := A.CapituloPorID(AID);
    if Assigned(C) then
      Exit(C);
  end;
  Result := nil;
end;

function TManuscrito.CenaPorID(const AID: TID): TCena;
var
  A: TAto;
  C: TCapitulo;
  Ce: TCena;
begin
  for A in FAtos do
    for C in A.Capitulos do
    begin
      Ce := C.CenaPorID(AID);
      if Assigned(Ce) then
        Exit(Ce);
    end;
  Result := nil;
end;

function TManuscrito.ParagrafoPorID(const AID: TID): TParagrafo;
var
  A: TAto;
  C: TCapitulo;
  Ce: TCena;
  P: TParagrafo;
begin
  for A in FAtos do
    for C in A.Capitulos do
      for Ce in C.Cenas do
      begin
        P := Ce.ParagrafoPorID(AID);
        if Assigned(P) then
          Exit(P);
      end;
  Result := nil;
end;

function TManuscrito.TotalPalavras: Integer;
var
  A: TAto;
begin
  Result := 0;
  for A in FAtos do
    Inc(Result, A.TotalPalavras);
end;

function TManuscrito.TotalCapitulos: Integer;
var
  A: TAto;
begin
  Result := 0;
  for A in FAtos do
    Inc(Result, A.Capitulos.Count);
end;

function TManuscrito.TotalCenas: Integer;
var
  A: TAto;
  C: TCapitulo;
begin
  Result := 0;
  for A in FAtos do
    for C in A.Capitulos do
      Inc(Result, C.Cenas.Count);
end;

function TManuscrito.TotalParagrafos: Integer;
var
  A: TAto;
  C: TCapitulo;
  Ce: TCena;
begin
  Result := 0;
  for A in FAtos do
    for C in A.Capitulos do
      for Ce in C.Cenas do
        Inc(Result, Ce.Paragrafos.Count);
end;

class function TManuscrito.NovoAPartirDe(const AAntes: TManuscrito): TManuscrito;
var
  AtoAntes, AtoNovo: TAto;
  CapAntes, CapNovo: TCapitulo;
  CenaAntes, CenaNovo: TCena;
  ParAntes, ParNovo: TParagrafo;
begin
  if AAntes = nil then
    raise EValorInvalido.Create('Manuscrito de origem não pode ser nil.');

  Result := TManuscrito.Create;
  try
    Result.VersaoSchema := AAntes.VersaoSchema;
    Result.Titulo := AAntes.Titulo;
    Result.GeradoEm := Now;
    Result.HashArquivo := AAntes.HashArquivo;
    Result.ArquivoOrigem := AAntes.ArquivoOrigem;

    for AtoAntes in AAntes.Atos do
    begin
      AtoNovo := TAto.Create;
      AtoNovo.ID := AtoAntes.ID;
      AtoNovo.Numero := AtoAntes.Numero;
      Result.Atos.Add(AtoNovo);

      for CapAntes in AtoAntes.Capitulos do
      begin
        CapNovo := TCapitulo.Create;
        CapNovo.ID := CapAntes.ID;
        CapNovo.Numero := CapAntes.Numero;
        CapNovo.Titulo := CapAntes.Titulo;
        AtoNovo.Capitulos.Add(CapNovo);

        for CenaAntes in CapAntes.Cenas do
        begin
          CenaNovo := TCena.Create;
          CenaNovo.ID := CenaAntes.ID;
          CenaNovo.Numero := CenaAntes.Numero;
          CapNovo.Cenas.Add(CenaNovo);

          for ParAntes in CenaAntes.Paragrafos do
          begin
            ParNovo := TParagrafo.Create;
            ParNovo.ID := ParAntes.ID;
            ParNovo.Ordem := ParAntes.Ordem;
            ParNovo.Texto := ParAntes.Texto;
            ParNovo.TextoOriginal := ParAntes.Texto; // cópia para rollback
            ParNovo.Hash := ParAntes.Hash;
            ParNovo.NumPalavras := ParAntes.NumPalavras;
            ParNovo.NumChunks := ParAntes.NumChunks;
            ParNovo.Status := spPendente;
            CenaNovo.Paragrafos.Add(ParNovo);
          end;
        end;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
