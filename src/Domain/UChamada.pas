unit UChamada;

{
  UChamada.pas
  ─────────────────────────────────────────────────────────────
  Value Objects que representam uma chamada de revisão à IA:
  o que o usuário selecionou (TParagrafoSelecionado) e o
  agregado da requisição (TChamada).

  Decisão travada:
    • Um vício por parágrafo. Cada TParagrafoSelecionado liga
      exatamente um ParagrafoID a um VicioID.
    • Um envio = uma cena. Nenhuma TChamada pode referenciar
      parágrafos de cenas diferentes.
    • Sempre em modo cirúrgico ou varredura. Cirúrgico é padrão.

  Regras:
    • VOs puros. Nenhuma lógica de HTTP, VCL ou JSON.
    • O hash do payload é calculado por composição determinística
      das partes (texto + vícios + modo + versões + observação).
      Mudou qualquer parte → hash muda → cache invalida.
    • A classe não calcula hash sozinha no construtor — o UseCase
      chama CalcularHashPayload() quando o payload estiver montado.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Hash,
  UValores;

type
  // ────────────────────────────────────────────────────────────
  // Parágrafo selecionado
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Um item da seleção do usuário: um parágrafo com UM vício
  ///   específico a ser analisado. Coerente com a regra de
  ///   "um vício por parágrafo" definida no fluxo.
  /// </summary>
  /// <remarks>
  ///   Texto carrega o conteúdo efetivamente enviado (pode ser
  ///   um chunk específico, se o parágrafo foi dividido).
  ///   ChunkIndex = 1 e ChunksTotais = 1 para parágrafos normais.
  /// </remarks>
  TParagrafoSelecionado = class
  private
    FParagrafoID: TID;
    FVicioID: string;
    FHashParagrafo: string;
    FTexto: string;
    FChunkIndex: Integer;
    FChunksTotais: Integer;
  public
    constructor Create;

    property ParagrafoID: TID read FParagrafoID write FParagrafoID;
    property VicioID: string read FVicioID write FVicioID;
    property HashParagrafo: string
      read FHashParagrafo write FHashParagrafo;
    property Texto: string read FTexto write FTexto;
    property ChunkIndex: Integer read FChunkIndex write FChunkIndex;
    property ChunksTotais: Integer read FChunksTotais write FChunksTotais;

    /// <summary>
    ///   True se o item está bem-formado: tem parágrafo, vício
    ///   e texto não vazio.
    /// </summary>
    function EhValido: Boolean;

    /// <summary>
    ///   Chave estável: paragrafo + chunk + vício. Usada para
    ///   ordenação determinística antes do cálculo de hash.
    /// </summary>
    function Chave: string;

    /// <summary>
    ///   True se este item é um chunk de um parágrafo grande
    ///   (ChunksTotais > 1).
    /// </summary>
    function EhChunk: Boolean;
  end;

  // ────────────────────────────────────────────────────────────
  // Chamada
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Agregado completo de uma chamada à IA. Corresponde a uma
  ///   entrada de Envio.JSON.
  /// </summary>
  /// <remarks>
  ///   IDChamada é atribuído pelo repositório no momento do
  ///   append em Envio.JSON (ex: "req-0007"). Antes disso, fica
  ///   vazio — a TChamada só é persistida quando estiver pronta.
  /// </remarks>
  TChamada = class
  private
    FIDChamada: string;
    FTimestamp: TDateTime;
    FCenaID: TID;
    FModo: TModoEnvio;
    FSelecoes: TObjectList<TParagrafoSelecionado>;
    FObservacaoUsuario: string;
    FViciosInjetados: TList<string>;
    FPromptVersao: string;
    FViciosVersao: Integer;
    FModelo: string;
    FTemperature: Double;
    FMaxTokens: Integer;
    FHashPayload: string;
    FTokensEstimadosInput: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property IDChamada: string read FIDChamada write FIDChamada;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;
    property CenaID: TID read FCenaID write FCenaID;
    property Modo: TModoEnvio read FModo write FModo;
    property Selecoes: TObjectList<TParagrafoSelecionado> read FSelecoes;
    property ObservacaoUsuario: string
      read FObservacaoUsuario write FObservacaoUsuario;
    property ViciosInjetados: TList<string> read FViciosInjetados;
    property PromptVersao: string
      read FPromptVersao write FPromptVersao;
    property ViciosVersao: Integer
      read FViciosVersao write FViciosVersao;
    property Modelo: string read FModelo write FModelo;
    property Temperature: Double read FTemperature write FTemperature;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens;
    property HashPayload: string read FHashPayload write FHashPayload;
    property TokensEstimadosInput: Integer
      read FTokensEstimadosInput write FTokensEstimadosInput;

    // ─── Construção ───

    /// <summary>
    ///   Adiciona uma seleção (parágrafo + vício). Lança se já
    ///   existir a mesma combinação (paragrafo + chunk + vício).
    /// </summary>
    procedure AdicionarSelecao(const ASelecao: TParagrafoSelecionado);

    /// <summary>
    ///   Adiciona uma lista de vícios como "injetados" no prompt.
    ///   Ignora duplicatas.
    /// </summary>
    procedure AdicionarVicioInjetado(const AVicioID: string);

    /// <summary>
    ///   Preenche ViciosInjetados a partir das seleções únicas
    ///   em modo cirúrgico. Não faz nada em modo varredura
    ///   (o UseCase preenche manualmente com o catálogo todo).
    /// </summary>
    procedure DerivarViciosInjetados;

    // ─── Consultas ───

    /// <summary>True se não há seleções válidas.</summary>
    function PayloadVazio: Boolean;

    /// <summary>Total de seleções válidas.</summary>
    function TotalSelecoes: Integer;

    /// <summary>Parágrafos distintos (únicos por ID).</summary>
    function ParagrafosDistintos: Integer;

    /// <summary>
    ///   Retorna o VicioID associado a um parágrafo. Como a
    ///   regra é "um vício por parágrafo", retorna string vazia
    ///   se não houver seleção para esse parágrafo.
    /// </summary>
    function VicioDoParagrafo(const AParagrafoID: TID): string;

    /// <summary>
    ///   True se já existe seleção para esse par (paragrafo, vicio),
    ///   considerando o chunk. Usado para alertar "já revisado".
    /// </summary>
    function JaSelecionado(const AParagrafoID: TID;
      const AVicioID: string; const AChunkIndex: Integer): Boolean;

    /// <summary>
    ///   True se todas as seleções apontam para a mesma cena
    ///   que FCenaID. Invariante do domínio.
    /// </summary>
    function TodasDaMesmaCena: Boolean;

    // ─── Hash de payload ───

    /// <summary>
    ///   Calcula o hash determinístico do payload. Deve ser
    ///   chamado pelo UseCase quando tudo estiver preenchido.
    ///   Composição: texto dos chunks + vícios + modo + versões
    ///   + observação do usuário.
    /// </summary>
    function CalcularHashPayload: string;

    // ─── Estimativa ───

    /// <summary>
    ///   Estima tokens de input por heurística (~4 chars/token
    ///   para PT-BR). Preenche TokensEstimadosInput.
    /// </summary>
    procedure EstimarTokensInput;

  private
    /// <summary>
    ///   Ordena as seleções por chave estável antes do hash.
    ///   Necessário para que a mesma seleção produza o mesmo
    ///   hash independentemente da ordem de inserção.
    /// </summary>
    function SelecoesOrdenadas: TArray<TParagrafoSelecionado>;
  end;

implementation

// ────────────────────────────────────────────────────────────
// TParagrafoSelecionado
// ────────────────────────────────────────────────────────────

constructor TParagrafoSelecionado.Create;
begin
  inherited;
  FChunkIndex := 1;
  FChunksTotais := 1;
end;

function TParagrafoSelecionado.EhValido: Boolean;
begin
  Result := (FParagrafoID <> '') and
            (FVicioID <> '') and
            (FTexto <> '');
end;

function TParagrafoSelecionado.Chave: string;
begin
  Result := Format('%s|%d|%s',
    [FParagrafoID, FChunkIndex, FVicioID]);
end;

function TParagrafoSelecionado.EhChunk: Boolean;
begin
  Result := FChunksTotais > 1;
end;

// ────────────────────────────────────────────────────────────
// TChamada
// ────────────────────────────────────────────────────────────

constructor TChamada.Create;
begin
  inherited;
  FTimestamp := Now;
  FModo := meCirurgico;
  FModelo := 'deepseek-chat';
  FTemperature := 0.3;
  FMaxTokens := 1500;
  FPromptVersao := 'v1';
  FViciosVersao := 1;
  FSelecoes := TObjectList<TParagrafoSelecionado>.Create;
  FViciosInjetados := TList<string>.Create;
end;

destructor TChamada.Destroy;
begin
  FViciosInjetados.Free;
  FSelecoes.Free;
  inherited;
end;

procedure TChamada.AdicionarSelecao(const ASelecao: TParagrafoSelecionado);
begin
  if ASelecao = nil then
    raise EValorInvalido.Create('Seleção não pode ser nil.');
  if not ASelecao.EhValido then
    raise EValorInvalido.Create(
      'Seleção precisa ter parágrafo, vício e texto.');
  if JaSelecionado(ASelecao.ParagrafoID, ASelecao.VicioID,
    ASelecao.ChunkIndex) then
    raise EOperacaoInvalida.CreateFmt(
      'Seleção duplicada para "%s" + "%s" (chunk %d).',
      [ASelecao.ParagrafoID, ASelecao.VicioID, ASelecao.ChunkIndex]);
  FSelecoes.Add(ASelecao);
end;

procedure TChamada.AdicionarVicioInjetado(const AVicioID: string);
begin
  if AVicioID = '' then
    Exit;
  if not FViciosInjetados.Contains(AVicioID) then
    FViciosInjetados.Add(AVicioID);
end;

procedure TChamada.DerivarViciosInjetados;
var
  S: TParagrafoSelecionado;
begin
  if FModo <> meCirurgico then
    Exit;
  FViciosInjetados.Clear;
  for S in FSelecoes do
    if not FViciosInjetados.Contains(S.VicioID) then
      FViciosInjetados.Add(S.VicioID);
end;

function TChamada.PayloadVazio: Boolean;
begin
  Result := TotalSelecoes = 0;
end;

function TChamada.TotalSelecoes: Integer;
var
  S: TParagrafoSelecionado;
begin
  Result := 0;
  for S in FSelecoes do
    if S.EhValido then
      Inc(Result);
end;

function TChamada.ParagrafosDistintos: Integer;
var
  IDs: TDictionary<string, Boolean>;
  S: TParagrafoSelecionado;
begin
  IDs := TDictionary<string, Boolean>.Create;
  try
    for S in FSelecoes do
      if S.EhValido then
        IDs.AddOrSetValue(S.ParagrafoID, True);
    Result := IDs.Count;
  finally
    IDs.Free;
  end;
end;

function TChamada.VicioDoParagrafo(const AParagrafoID: TID): string;
var
  S: TParagrafoSelecionado;
begin
  for S in FSelecoes do
    if S.ParagrafoID = AParagrafoID then
      Exit(S.VicioID);
  Result := '';
end;

function TChamada.JaSelecionado(const AParagrafoID: TID;
  const AVicioID: string; const AChunkIndex: Integer): Boolean;
var
  S: TParagrafoSelecionado;
begin
  for S in FSelecoes do
    if (S.ParagrafoID = AParagrafoID) and
       SameText(S.VicioID, AVicioID) and
       (S.ChunkIndex = AChunkIndex) then
      Exit(True);
  Result := False;
end;

function TChamada.TodasDaMesmaCena: Boolean;
var
  S: TParagrafoSelecionado;
  CenaExtraida: string;
begin
  if FCenaID = '' then
    Exit(False);

  for S in FSelecoes do
  begin
    // Extrai o prefixo "cap-N-cena-M" do paragrafo_id
    // Formato: "cap-N-cena-M-pXX" → "cap-N-cena-M"
    CenaExtraida := S.ParagrafoID;
    if Pos('-p', CenaExtraida) > 0 then
      CenaExtraida := Copy(CenaExtraida, 1, Pos('-p', CenaExtraida) - 1);
    if CenaExtraida <> FCenaID then
      Exit(False);
  end;
  Result := True;
end;

function TChamada.SelecoesOrdenadas: TArray<TParagrafoSelecionado>;
var
  Lista: TArray<TParagrafoSelecionado>;
  I: Integer;
begin
  Lista := FSelecoes.ToArray;
  // Ordenação por Chave via insertion sort simples — N é pequeno.
  for I := 1 to High(Lista) do
  begin
    var J := I;
    while (J > 0) and (Lista[J].Chave < Lista[J - 1].Chave) do
    begin
      var Tmp := Lista[J];
      Lista[J] := Lista[J - 1];
      Lista[J - 1] := Tmp;
      Dec(J);
    end;
  end;
  Result := Lista;
end;

function TChamada.CalcularHashPayload: string;
var
  SB: TStringBuilder;
  S: TParagrafoSelecionado;
  V: string;
  SelecoesOrd: TArray<TParagrafoSelecionado>;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('modo=').Append(FModo.ToStr).Append(#10);

    // Vícios injetados em ordem alfabética (determinístico).
    var ViciosOrd := FViciosInjetados.ToArray;
    TArray.Sort<string>(ViciosOrd);
    for V in ViciosOrd do
      SB.Append('v=').Append(V).Append(#10);

    SB.Append('prompt=').Append(FPromptVersao).Append(#10);
    SB.Append('vicios_ver=').Append(FViciosVersao).Append(#10);
    SB.Append('obs=').Append(FObservacaoUsuario.Trim).Append(#10);

    // Seleções em ordem estável.
    SelecoesOrd := SelecoesOrdenadas;
    for S in SelecoesOrd do
    begin
      SB.Append('s=').Append(S.ParagrafoID)
        .Append('|').Append(S.ChunkIndex)
        .Append('|').Append(S.VicioID)
        .Append('|').Append(S.Texto)
        .Append(#10);
    end;

    Result := THashSHA1.GetHashString(SB.ToString);
  finally
    SB.Free;
  end;
end;

procedure TChamada.EstimarTokensInput;
var
  TotalChars: Integer;
  S: TParagrafoSelecionado;
begin
  TotalChars := 0;
  for S in FSelecoes do
    Inc(TotalChars, Length(S.Texto));

  // ~4 chars/token para PT-BR (aproximação conservadora).
  FTokensEstimadosInput := (TotalChars div 4) + 1;

  // Adiciona overhead estimado do prompt (~300 tokens).
  Inc(FTokensEstimadosInput, 300);
end;

end.
