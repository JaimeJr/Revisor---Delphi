unit UEdicaoSugerida;

{
  UEdicaoSugerida.pas
  ─────────────────────────────────────────────────────────────
  Value Objects que representam a resposta da IA:
    • TEdicaoSugerida — uma edição cirúrgica individual.
    • TResposta      — o agregado completo da resposta.

  ORDEM DE DECLARAÇÃO IMPORTA:
    TEdicaoSugerida vem ANTES de TResposta porque TResposta a
    referencia (FEdicoes: TObjectList<TEdicaoSugerida>). Se a
    ordem for invertida, o compilador acusa "undeclared
    identifier".

  Decisão travada:
    • TEdicaoSugerida NÃO guarda o texto original. O original
      vive em Envio.JSON, resolvido por ParagrafoID + ChunkIndex.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores;

type
  // ═══════════════════════════════════════════════════════════
  // TEdicaoSugerida (declarada primeiro)
  // ═══════════════════════════════════════════════════════════

  TEdicaoSugerida = class
  private
    FParagrafoID: TID;
    FChunkIndex: Integer;
    FVicioID: string;
    FSugerido: string;
    FMotivo: string;
    FSelecionada: Boolean;
    FAplicada: Boolean;
  public
    constructor Create;

    property ParagrafoID: TID read FParagrafoID write FParagrafoID;
    property ChunkIndex: Integer read FChunkIndex write FChunkIndex;
    property VicioID: string read FVicioID write FVicioID;
    property Sugerido: string read FSugerido write FSugerido;
    property Motivo: string read FMotivo write FMotivo;

    property Selecionada: Boolean read FSelecionada write FSelecionada;
    property Aplicada: Boolean read FAplicada write FAplicada;

    function EhValida: Boolean;
    function Chave: string;
  end;

  // ═══════════════════════════════════════════════════════════
  // TResposta (declarada depois — referencia TEdicaoSugerida)
  // ═══════════════════════════════════════════════════════════

  TResposta = class
  private
    FIDChamada: string;
    FTimestamp: TDateTime;
    FTokensPrompt: Integer;
    FTokensResposta: Integer;
    FCustoEstimado: Double;
    FRespostaBruta: string;
    FStatusParse: TStatusParse;
    FVicioGeral: string;
    FEdicoes: TObjectList<TEdicaoSugerida>;
    FErroParse: string;
    FParagrafosPermitidos: TList<TID>;
    FViciosPermitidos: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;

    property IDChamada: string read FIDChamada write FIDChamada;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;
    property TokensPrompt: Integer read FTokensPrompt write FTokensPrompt;
    property TokensResposta: Integer
      read FTokensResposta write FTokensResposta;
    property CustoEstimado: Double
      read FCustoEstimado write FCustoEstimado;
    property RespostaBruta: string
      read FRespostaBruta write FRespostaBruta;
    property StatusParse: TStatusParse
      read FStatusParse write FStatusParse;
    property VicioGeral: string read FVicioGeral write FVicioGeral;
    property Edicoes: TObjectList<TEdicaoSugerida> read FEdicoes;
    property ErroParse: string read FErroParse write FErroParse;

    procedure DefinirParagrafosPermitidos(const AIDs: TArray<TID>);
    procedure DefinirViciosPermitidos(const AIDs: TArray<string>);

    function TemEdicoes: Boolean;
    function TokensTotais: Integer;
    function EdicoesAplicaveis: TArray<TEdicaoSugerida>;
    function EdicoesForaEscopo: TArray<TEdicaoSugerida>;
    function EdicoesDeParagrafo(
      const AParagrafoID: TID): TArray<TEdicaoSugerida>;

    procedure ReclassificarStatus;
    function EdicaoDentroDoEscopo(
      const AEdicao: TEdicaoSugerida): Boolean;

    procedure LimparSelecao;
    procedure SelecionarTodasAplicaveis;
    function EdicoesSelecionadas: TArray<TEdicaoSugerida>;

    /// <summary>
    ///   Cópia profunda. Usada pelo cache para não compartilhar
    ///   estado com o chamador. Copia edições, escopo e todos
    ///   os campos primitivos.
    /// </summary>
    function Clonar: TResposta;
  end;

implementation

// ────────────────────────────────────────────────────────────
// TEdicaoSugerida
// ────────────────────────────────────────────────────────────

constructor TEdicaoSugerida.Create;
begin
  inherited;
  FChunkIndex := 1;
  FSelecionada := False;
  FAplicada := False;
end;

function TEdicaoSugerida.EhValida: Boolean;
begin
  Result := (FParagrafoID <> '') and
            (FVicioID <> '') and
            (FSugerido <> '');
end;

function TEdicaoSugerida.Chave: string;
begin
  Result := Format('%s|%d|%s',
    [FParagrafoID, FChunkIndex, FVicioID]);
end;

// ────────────────────────────────────────────────────────────
// TResposta
// ────────────────────────────────────────────────────────────

constructor TResposta.Create;
begin
  inherited;
  FTimestamp := Now;
  FStatusParse := spOK;
  FEdicoes := TObjectList<TEdicaoSugerida>.Create;
  FParagrafosPermitidos := TList<TID>.Create;
  FViciosPermitidos := TList<string>.Create;
end;

destructor TResposta.Destroy;
begin
  FViciosPermitidos.Free;
  FParagrafosPermitidos.Free;
  FEdicoes.Free;
  inherited;
end;

procedure TResposta.DefinirParagrafosPermitidos(const AIDs: TArray<TID>);
var
  ID: TID;
begin
  FParagrafosPermitidos.Clear;
  for ID in AIDs do
    FParagrafosPermitidos.Add(ID);
end;

procedure TResposta.DefinirViciosPermitidos(const AIDs: TArray<string>);
var
  ID: string;
begin
  FViciosPermitidos.Clear;
  for ID in AIDs do
    FViciosPermitidos.Add(ID);
end;

function TResposta.TemEdicoes: Boolean;
begin
  Result := FEdicoes.Count > 0;
end;

function TResposta.TokensTotais: Integer;
begin
  Result := FTokensPrompt + FTokensResposta;
end;

function TResposta.EdicaoDentroDoEscopo(
  const AEdicao: TEdicaoSugerida): Boolean;
begin
  if not Assigned(AEdicao) then
    Exit(False);
  Result := FParagrafosPermitidos.Contains(AEdicao.ParagrafoID) and
            FViciosPermitidos.Contains(AEdicao.VicioID);
end;

function TResposta.EdicoesAplicaveis: TArray<TEdicaoSugerida>;
var
  E: TEdicaoSugerida;
  Lista: TList<TEdicaoSugerida>;
begin
  Lista := TList<TEdicaoSugerida>.Create;
  try
    for E in FEdicoes do
      if E.EhValida and EdicaoDentroDoEscopo(E) then
        Lista.Add(E);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TResposta.EdicoesForaEscopo: TArray<TEdicaoSugerida>;
var
  E: TEdicaoSugerida;
  Lista: TList<TEdicaoSugerida>;
begin
  Lista := TList<TEdicaoSugerida>.Create;
  try
    for E in FEdicoes do
      if E.EhValida and not EdicaoDentroDoEscopo(E) then
        Lista.Add(E);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TResposta.EdicoesDeParagrafo(
  const AParagrafoID: TID): TArray<TEdicaoSugerida>;
var
  E: TEdicaoSugerida;
  Lista: TList<TEdicaoSugerida>;
begin
  Lista := TList<TEdicaoSugerida>.Create;
  try
    for E in FEdicoes do
      if E.ParagrafoID = AParagrafoID then
        Lista.Add(E);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

procedure TResposta.ReclassificarStatus;
var
  TemForaEscopo: Boolean;
begin
  if FStatusParse = spParseError then
    Exit;

  if not TemEdicoes then
  begin
    FStatusParse := spVazio;
    Exit;
  end;

  TemForaEscopo := Length(EdicoesForaEscopo) > 0;
  if TemForaEscopo and (Length(EdicoesAplicaveis) = 0) then
    FStatusParse := spForaEscopo
  else
    FStatusParse := spOK;
end;

procedure TResposta.LimparSelecao;
var
  E: TEdicaoSugerida;
begin
  for E in FEdicoes do
    E.Selecionada := False;
end;

procedure TResposta.SelecionarTodasAplicaveis;
var
  E: TEdicaoSugerida;
begin
  for E in FEdicoes do
    if E.EhValida and EdicaoDentroDoEscopo(E) then
      E.Selecionada := True;
end;

function TResposta.EdicoesSelecionadas: TArray<TEdicaoSugerida>;
var
  E: TEdicaoSugerida;
  Lista: TList<TEdicaoSugerida>;
begin
  Lista := TList<TEdicaoSugerida>.Create;
  try
    for E in FEdicoes do
      if E.Selecionada and E.EhValida then
        Lista.Add(E);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TResposta.Clonar: TResposta;
var
  E, NovaE: TEdicaoSugerida;
  ID: TID;
  V: string;
begin
  Result := TResposta.Create;
  try
    Result.FIDChamada := FIDChamada;
    Result.FTimestamp := FTimestamp;
    Result.FTokensPrompt := FTokensPrompt;
    Result.FTokensResposta := FTokensResposta;
    Result.FCustoEstimado := FCustoEstimado;
    Result.FRespostaBruta := FRespostaBruta;
    Result.FStatusParse := FStatusParse;
    Result.FVicioGeral := FVicioGeral;
    Result.FErroParse := FErroParse;

    for E in FEdicoes do
    begin
      NovaE := TEdicaoSugerida.Create;
      NovaE.ParagrafoID := E.ParagrafoID;
      NovaE.ChunkIndex := E.ChunkIndex;
      NovaE.VicioID := E.VicioID;
      NovaE.Sugerido := E.Sugerido;
      NovaE.Motivo := E.Motivo;
      NovaE.Selecionada := E.Selecionada;
      NovaE.Aplicada := E.Aplicada;
      Result.FEdicoes.Add(NovaE);
    end;

    for ID in FParagrafosPermitidos do
      Result.FParagrafosPermitidos.Add(ID);

    for V in FViciosPermitidos do
      Result.FViciosPermitidos.Add(V);
  except
    Result.Free;
    raise;
  end;
end;

end.
