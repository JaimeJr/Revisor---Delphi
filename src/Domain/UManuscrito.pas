unit UManuscrito;

{
  UManuscrito.pas
  ─────────────────────────────────────────────────────────────
  Entidades do domínio que representam a estrutura de um
  manuscrito.

  Nesta versão:
    • TDisparoGatilho (VO) — registro de um gatilho local
      que disparou sobre um parágrafo.
    • TParagrafo ganha uma lista de disparos, persistida
      apenas no Novo.JSON.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores;

type
  TDisparoGatilho = class;
  TRevisaoParagrafo = class;

  // ────────────────────────────────────────────────────────────
  // Disparo de gatilho (VO)
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Registro de um disparo de gatilho local sobre um parágrafo.
  ///   Persistido em Novo.JSON por par (parágrafo, gatilho).
  /// </summary>
  TDisparoGatilho = class
  private
    FGatilhoID: string;
    FVersaoGatilho: string;
    FConfianca: Double;
    FTrechos: TArray<string>;
    FHashParagrafoNoDisparo: string;
    FQuando: TDateTime;
  public
    property GatilhoID: string read FGatilhoID write FGatilhoID;
    property VersaoGatilho: string
      read FVersaoGatilho write FVersaoGatilho;
    property Confianca: Double read FConfianca write FConfianca;
    property Trechos: TArray<string> read FTrechos write FTrechos;
    property HashParagrafoNoDisparo: string
      read FHashParagrafoNoDisparo write FHashParagrafoNoDisparo;
    property Quando: TDateTime read FQuando write FQuando;
  end;

  // ────────────────────────────────────────────────────────────
  // Revisão de parágrafo (VO) — já existia
  // ────────────────────────────────────────────────────────────

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
  // Parágrafo
  // ────────────────────────────────────────────────────────────

  TParagrafo = class
  private
    FID: TID;
    FOrdem: Integer;
    FTexto: string;
    FHash: string;
    FNumPalavras: Integer;
    FNumChunks: Integer;

    FTextoOriginal: string;
    FStatus: TStatusParagrafo;
    FRevisoes: TObjectList<TRevisaoParagrafo>;
    FGatilhosDisparados: TObjectList<TDisparoGatilho>;
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
    property GatilhosDisparados: TObjectList<TDisparoGatilho>
      read FGatilhosDisparados;

    function EhGrande: Boolean;

    procedure AdicionarRevisao(const ARevisao: TRevisaoParagrafo);
    function JaRevisado(const AVicioID, AHashParagrafo: string): Boolean;
    procedure MarcarRevisadoManual;

    // ─── Gatilhos ───

    /// <summary>
    ///   True se existe pelo menos um gatilho disparado.
    /// </summary>
    function TemDisparo: Boolean;

    /// <summary>
    ///   True se o gatilho indicado já disparou sobre este
    ///   parágrafo. Não considera versão nem hash — só presença.
    /// </summary>
    function TemDisparoDe(const AGatilhoID: string): Boolean;

    /// <summary>
    ///   Devolve o disparo do gatilho indicado, ou nil.
    /// </summary>
    function DisparoDe(const AGatilhoID: string): TDisparoGatilho;

    /// <summary>
    ///   Registra um disparo. Se já existia um disparo do mesmo
    ///   gatilho, ele é substituído. Assume ownership do objeto.
    /// </summary>
    procedure RegistrarDisparo(const ADisparo: TDisparoGatilho);

    /// <summary>
    ///   Remove o disparo do gatilho indicado, se existir.
    ///   Retorna True se removeu.
    /// </summary>
    function RemoverDisparo(const AGatilhoID: string): Boolean;

    /// <summary>Remove todos os disparos (usado na reanálise).</summary>
    procedure LimparDisparos;
  end;

  // ────────────────────────────────────────────────────────────
  // Cena / Capítulo / Ato / Manuscrito (iguais)
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

    function AtoPorNumero(const ANumero: Integer): TAto;
    function AtoDoCapitulo(const ANumeroCapitulo: Integer): TAto;
    function CapituloPorID(const AID: TID): TCapitulo;
    function CenaPorID(const AID: TID): TCena;
    function ParagrafoPorID(const AID: TID): TParagrafo;

    function TotalPalavras: Integer;
    function TotalCapitulos: Integer;
    function TotalCenas: Integer;
    function TotalParagrafos: Integer;

    class function NovoAPartirDe(const AAntes: TManuscrito): TManuscrito;
  end;

// ────────────────────────────────────────────────────────────
// Utilidades de texto
// ────────────────────────────────────────────────────────────

function ContarPalavras(const ATexto: string): Integer;
function GerarIDAto(const ANumero: Integer): TID;
function GerarIDCapitulo(const ANumero: Integer): TID;
function GerarIDCena(const ANumeroCapitulo, ANumeroCena: Integer): TID;
function GerarIDParagrafo(const ANumeroCapitulo, ANumeroCena,
  ANumeroParagrafo: Integer): TID;

implementation

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

{ TParagrafo }

constructor TParagrafo.Create;
begin
  inherited;
  FStatus := spPendente;
  FNumChunks := 1;
  FRevisoes := TObjectList<TRevisaoParagrafo>.Create;
  FGatilhosDisparados := TObjectList<TDisparoGatilho>.Create;
end;

destructor TParagrafo.Destroy;
begin
  FGatilhosDisparados.Free;
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

function TParagrafo.TemDisparo: Boolean;
begin
  Result := FGatilhosDisparados.Count > 0;
end;

function TParagrafo.TemDisparoDe(const AGatilhoID: string): Boolean;
begin
  Result := Assigned(DisparoDe(AGatilhoID));
end;

function TParagrafo.DisparoDe(const AGatilhoID: string): TDisparoGatilho;
var
  D: TDisparoGatilho;
begin
  for D in FGatilhosDisparados do
    if D.GatilhoID = AGatilhoID then
      Exit(D);
  Result := nil;
end;

procedure TParagrafo.RegistrarDisparo(const ADisparo: TDisparoGatilho);
var
  Idx: Integer;
  D: TDisparoGatilho;
begin
  if ADisparo = nil then
    raise EValorInvalido.Create('Disparo não pode ser nil.');
  if ADisparo.GatilhoID = '' then
    raise EValorInvalido.Create('Disparo precisa de GatilhoID.');

  Idx := -1;
  for D in FGatilhosDisparados do
    if D.GatilhoID = ADisparo.GatilhoID then
    begin
      Idx := FGatilhosDisparados.IndexOf(D);
      Break;
    end;

  if Idx >= 0 then
    FGatilhosDisparados[Idx] := ADisparo  // substitui (libera o antigo)
  else
    FGatilhosDisparados.Add(ADisparo);
end;

function TParagrafo.RemoverDisparo(const AGatilhoID: string): Boolean;
var
  D: TDisparoGatilho;
  Idx: Integer;
begin
  Idx := -1;
  for D in FGatilhosDisparados do
    if D.GatilhoID = AGatilhoID then
    begin
      Idx := FGatilhosDisparados.IndexOf(D);
      Break;
    end;

  if Idx < 0 then
    Exit(False);

  FGatilhosDisparados.Delete(Idx);
  Result := True;
end;

procedure TParagrafo.LimparDisparos;
begin
  FGatilhosDisparados.Clear;
end;

{ TCena }

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

{ TCapitulo }

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

{ TAto }

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

{ TManuscrito }

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
            ParNovo.TextoOriginal := ParAntes.Texto;
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
