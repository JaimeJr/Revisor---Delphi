unit UEdicaoSugerida;

{
  UEdicaoSugerida.pas
  ─────────────────────────────────────────────────────────────
  Value Objects que representam a resposta da IA a uma chamada
  de revisão: uma edição individual (TEdicaoSugerida) e o
  agregado da resposta completa (TResposta).

  Decisão travada:
    • TEdicaoSugerida NÃO guarda o texto original. O original
      vem sempre do Envio.JSON, resolvido por ParagrafoID +
      ChunkIndex. Isso elimina duplicação e mantém uma única
      fonte da verdade.

  Regras:
    • Apenas VOs. Nenhuma lógica de I/O, HTTP, VCL ou JSON.
    • TResposta é imutável do ponto de vista de "resposta da IA"
      — mas permite mutação do estado de aceitação por edição,
      que vive aqui apenas durante a sessão da tela de revisão.
    • StatusParse classifica o resultado bruto para a UI decidir
      o que mostrar (edição normal, erro de parse, vazio, etc.).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores;

type
  // ────────────────────────────────────────────────────────────
  // Edição sugerida
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Uma edição cirúrgica proposta pela IA para um parágrafo.
  /// </summary>
  /// <remarks>
  ///   O texto original correspondente é resolvido pelo chamador
  ///   consultando o Envio.JSON pelo par (ParagrafoID, ChunkIndex).
  ///   Não é armazenado aqui — decisão de arquitetura.
  /// </remarks>
  TEdicaoSugerida = class
  private
    FParagrafoID: TID;
    FChunkIndex: Integer;
    FVicioID: string;
    FSugerido: string;
    FMotivo: string;

    // Estado de sessão (não persiste em Resposta.JSON)
    FSelecionada: Boolean;   // usuário marcou para aceitar
    FAplicada: Boolean;      // já foi aceita em alguma rodada
  public
    constructor Create;

    property ParagrafoID: TID read FParagrafoID write FParagrafoID;
    property ChunkIndex: Integer read FChunkIndex write FChunkIndex;
    property VicioID: string read FVicioID write FVicioID;
    property Sugerido: string read FSugerido write FSugerido;
    property Motivo: string read FMotivo write FMotivo;

    property Selecionada: Boolean read FSelecionada write FSelecionada;
    property Aplicada: Boolean read FAplicada write FAplicada;

    /// <summary>
    ///   True se a edição é válida (tem parágrafo, vício e texto).
    ///   Usado para filtrar respostas incompletas da IA.
    /// </summary>
    function EhValida: Boolean;

    /// <summary>
    ///   Chave estável para busca e cache: paragrafo + chunk + vício.
    /// </summary>
    function Chave: string;
  end;

  // ────────────────────────────────────────────────────────────
  // Resposta da IA
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Agregado completo da resposta da IA a uma chamada.
  ///   Corresponde a uma entrada de Resposta.JSON.
  /// </summary>
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

    // IDs permitidos (preenchidos pelo UseCase a partir do Envio)
    // para classificar edições como dentro/fora de escopo.
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

    // ─── Escopo (definido pelo UseCase antes de classificar) ───

    /// <summary>
    ///   Define o conjunto de parágrafos que estavam na chamada.
    ///   Usado para classificar edições como dentro/fora de escopo.
    /// </summary>
    procedure DefinirParagrafosPermitidos(const AIDs: TArray<TID>);

    /// <summary>Define o conjunto de vícios que estavam na chamada.</summary>
    procedure DefinirViciosPermitidos(const AIDs: TArray<string>);

    // ─── Consultas ───

    /// <summary>True se há pelo menos uma edição válida.</summary>
    function TemEdicoes: Boolean;

    /// <summary>Total de tokens consumidos (prompt + resposta).</summary>
    function TokensTotais: Integer;

    /// <summary>
    ///   Edições aplicáveis: válidas E dentro do escopo enviado.
    /// </summary>
    function EdicoesAplicaveis: TArray<TEdicaoSugerida>;

    /// <summary>
    ///   Edições fora do escopo: parágrafo ou vício que não
    ///   estavam no envio. UI mostra, mas desabilita aceitar.
    /// </summary>
    function EdicoesForaEscopo: TArray<TEdicaoSugerida>;

    /// <summary>Edições aplicáveis de um parágrafo específico.</summary>
    function EdicoesDeParagrafo(const AParagrafoID: TID): TArray<TEdicaoSugerida>;

    /// <summary>
    ///   Classifica e ajusta StatusParse com base nas edições e
    ///   nos conjuntos de permissão. Deve ser chamado pelo
    ///   UseCase após popular as edições e os permitidos.
    /// </summary>
    procedure ReclassificarStatus;

    /// <summary>
    ///   True se a edição está dentro do escopo enviado
    ///   (parágrafo permitido E vício permitido).
    /// </summary>
    function EdicaoDentroDoEscopo(const AEdicao: TEdicaoSugerida): Boolean;

    /// <summary>Limpa o estado de seleção de todas as edições.</summary>
    procedure LimparSelecao;

    /// <summary>Marca todas as edições aplicáveis como selecionadas.</summary>
    procedure SelecionarTodasAplicaveis;

    /// <summary>Edições selecionadas (para aceite em lote).</summary>
    function EdicoesSelecionadas: TArray<TEdicaoSugerida>;
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
  // Se já foi classificado como parse_error, não sobrescreve.
  if FStatusParse = spParseError then
    Exit;

  // Sem edições → vazio (IA não encontrou nada).
  if not TemEdicoes then
  begin
    FStatusParse := spVazio;
    Exit;
  end;

  // Há edições fora do escopo? Marca como fora_escopo, mas
  // as aplicáveis continuam válidas (a UI mostra ambas).
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

end.
