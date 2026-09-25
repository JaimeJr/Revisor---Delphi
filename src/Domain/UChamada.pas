unit UChamada;

{
  UChamada.pas
  ─────────────────────────────────────────────────────────────
  Value Objects que representam uma chamada de revisão à IA.

  Adicionado nesta versão:
    • CaminhoNovo, CaminhoEnvio, CaminhoResposta — os caminhos
      da sessão. Antes viviam no constructor do TRevisorDeepSeek,
      mas mudam a cada importação. Agora viajam com a chamada.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Hash,
  UValores;

type
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

    function EhValido: Boolean;
    function Chave: string;
    function EhChunk: Boolean;
  end;

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

    // ─── Caminhos da sessão (novos) ───
    FCaminhoNovo: string;
    FCaminhoEnvio: string;
    FCaminhoResposta: string;
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

    property CaminhoNovo: string read FCaminhoNovo write FCaminhoNovo;
    property CaminhoEnvio: string read FCaminhoEnvio write FCaminhoEnvio;
    property CaminhoResposta: string
      read FCaminhoResposta write FCaminhoResposta;

    procedure AdicionarSelecao(const ASelecao: TParagrafoSelecionado);
    procedure AdicionarVicioInjetado(const AVicioID: string);
    procedure DerivarViciosInjetados;

    function PayloadVazio: Boolean;
    function TotalSelecoes: Integer;
    function ParagrafosDistintos: Integer;
    function VicioDoParagrafo(const AParagrafoID: TID): string;
    function JaSelecionado(const AParagrafoID: TID;
      const AVicioID: string; const AChunkIndex: Integer): Boolean;
    function TodasDaMesmaCena: Boolean;

    function CalcularHashPayload: string;
    procedure EstimarTokensInput;
  private
    function SelecoesOrdenadas: TArray<TParagrafoSelecionado>;
  end;

implementation

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

{ TChamada }

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
  I, J: Integer;
  Tmp: TParagrafoSelecionado;
begin
  Lista := FSelecoes.ToArray;
  for I := 1 to High(Lista) do
  begin
    J := I;
    while (J > 0) and (Lista[J].Chave < Lista[J - 1].Chave) do
    begin
      Tmp := Lista[J];
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
  SelecoesOrd, ViciosOrd: TArray<string>;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('modo=').Append(FModo.ToStr).Append(#10);

    ViciosOrd := FViciosInjetados.ToArray;
    TArray.Sort<string>(ViciosOrd);
    for V in ViciosOrd do
      SB.Append('v=').Append(V).Append(#10);

    SB.Append('prompt=').Append(FPromptVersao).Append(#10);
    SB.Append('vicios_ver=').Append(FViciosVersao).Append(#10);
    SB.Append('obs=').Append(FObservacaoUsuario.Trim).Append(#10);

{    SelecoesOrd := SelecoesOrdenadas;
    for S in SelecoesOrd do
      SB.Append('s=').Append(S.ParagrafoID)
        .Append('|').Append(S.ChunkIndex)
        .Append('|').Append(S.VicioID)
        .Append('|').Append(S.Texto)
        .Append(#10);
 }
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

  FTokensEstimadosInput := (TotalChars div 4) + 1;
  Inc(FTokensEstimadosInput, 300);
end;

end.
