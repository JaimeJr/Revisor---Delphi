unit UAnomaliaParse;

{
  UAnomaliaParse.pas
  ─────────────────────────────────────────────────────────────
  Entidades que representam o resultado do parse do .docx:
  anomalias detectadas e o resumo do que foi extraído.

  Decisão travada:
    • O parser NUNCA falha. Ele processa o que consegue e
      registra anomalias tipadas. Quem decide o que fazer com
      elas é a UI ou o UseCase.
    • O parse.log é gravado sempre, mesmo quando não há
      anomalias (resumo sozinho já é útil).

  Regras:
    • VOs puros. Nenhuma lógica de I/O, HTTP, VCL ou JSON.
    • Severidade classifica o impacto:
        info  → esperado, vale registrar
        aviso → fora do padrão, mas recuperável
        erro  → impede processamento correto
    • Localização é uma string livre (ex: "cap-5", "global",
      "inicio") — o parser decide o formato conforme o tipo.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores;

type
  // ────────────────────────────────────────────────────────────
  // Anomalia
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Uma anomalia detectada pelo parser do manuscrito.
  /// </summary>
  TAnomaliaParse = class
  private
    FSeveridade: TSeveridadeAnomalia;
    FTipo: TTipoAnomalia;
    FLocalizacao: string;
    FDetalhe: string;
    FTimestamp: TDateTime;
  public
    constructor Create;
    constructor CreateDe(const ASeveridade: TSeveridadeAnomalia;
      const ATipo: TTipoAnomalia; const ALocalizacao, ADetalhe: string);

    property Severidade: TSeveridadeAnomalia
      read FSeveridade write FSeveridade;
    property Tipo: TTipoAnomalia read FTipo write FTipo;
    property Localizacao: string read FLocalizacao write FLocalizacao;
    property Detalhe: string read FDetalhe write FDetalhe;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;

    /// <summary>True se Severidade = saErro.</summary>
    function EhErro: Boolean;

    /// <summary>True se Severidade = saAviso.</summary>
    function EhAviso: Boolean;

    /// <summary>True se Severidade = saInfo.</summary>
    function EhInfo: Boolean;
  end;

  // ────────────────────────────────────────────────────────────
  // Resumo do parse
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Contagens agregadas do que foi extraído. Serve para
  ///   sanity check e para a UI mostrar panorama.
  /// </summary>
  TResumoParse = class
  private
    FAtos: Integer;
    FCapitulos: Integer;
    FCenas: Integer;
    FParagrafos: Integer;
    FPalavras: Integer;
    FParagrafosGrandes: Integer;  // num_chunks > 1
  public
    constructor Create;

    property Atos: Integer read FAtos write FAtos;
    property Capitulos: Integer read FCapitulos write FCapitulos;
    property Cenas: Integer read FCenas write FCenas;
    property Paragrafos: Integer read FParagrafos write FParagrafos;
    property Palavras: Integer read FPalavras write FPalavras;
    property ParagrafosGrandes: Integer
      read FParagrafosGrandes write FParagrafosGrandes;

    /// <summary>
    ///   Verifica se as contagens batem com o esperado
    ///   (21 capítulos, 3 atos). Retorna lista de divergências
    ///   em texto curto — não lança.
    /// </summary>
    function DivergenciasDoPadrao: TArray<string>;

    /// <summary>Média de palavras por capítulo (0 se sem capítulos).</summary>
    function MediaPalavrasPorCapitulo: Double;
  end;

  // ────────────────────────────────────────────────────────────
  // Log de parse
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Agregado completo do parse.log. Corresponde ao arquivo
  ///   parse.log gravado ao lado do Antes.JSON.
  /// </summary>
  TParseLog = class
  private
    FVersaoSchema: Integer;
    FArquivo: string;
    FTimestamp: TDateTime;
    FResumo: TResumoParse;
    FAnomalias: TObjectList<TAnomaliaParse>;
  public
    constructor Create;
    destructor Destroy; override;

    property VersaoSchema: Integer read FVersaoSchema write FVersaoSchema;
    property Arquivo: string read FArquivo write FArquivo;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;
    property Resumo: TResumoParse read FResumo;
    property Anomalias: TObjectList<TAnomaliaParse> read FAnomalias;

    /// <summary>
    ///   Adiciona anomalia e retorna a referência para encadeamento.
    /// </summary>
    function AdicionarAnomalia(const AAnomalia: TAnomaliaParse): TParseLog;

    /// <summary>
    ///   Atalho: cria uma anomalia e adiciona em uma chamada.
    /// </summary>
    function Registrar(const ASeveridade: TSeveridadeAnomalia;
      const ATipo: TTipoAnomalia;
      const ALocalizacao, ADetalhe: string): TParseLog;

    /// <summary>True se há pelo menos uma anomalia de severidade erro.</summary>
    function TemErros: Boolean;

    /// <summary>True se há pelo menos uma anomalia de severidade aviso.</summary>
    function TemAvisos: Boolean;

    /// <summary>True se o log está totalmente limpo.</summary>
    function Limpo: Boolean;

    /// <summary>Total de anomalias (todas as severidades).</summary>
    function TotalAnomalias: Integer;

    /// <summary>Anomalias filtradas por severidade.</summary>
    function AnomaliasPorSeveridade(
      const ASeveridade: TSeveridadeAnomalia): TArray<TAnomaliaParse>;

    /// <summary>Anomalias filtradas por tipo.</summary>
    function AnomaliasPorTipo(
      const ATipo: TTipoAnomalia): TArray<TAnomaliaParse>;

    /// <summary>
    ///   Retorna o pior nível de severidade presente. Útil para
    ///   a UI decidir o ícone do badge (verde/amarelo/vermelho).
    /// </summary>
    function SeveridadeMaxima: TSeveridadeAnomalia;

    /// <summary>
    ///   Resumo textual em uma linha, para a barra de status.
    ///   Ex: "3 atos, 21 capítulos, 64 cenas, 892 parágrafos
    ///        (2 avisos, 0 erros)".
    /// </summary>
    function ResumoTextual: string;
  end;

implementation

// ────────────────────────────────────────────────────────────
// TAnomaliaParse
// ────────────────────────────────────────────────────────────

constructor TAnomaliaParse.Create;
begin
  inherited;
  FTimestamp := Now;
  FSeveridade := saInfo;
  FTipo := taArquivoVazio;
end;

constructor TAnomaliaParse.CreateDe(
  const ASeveridade: TSeveridadeAnomalia; const ATipo: TTipoAnomalia;
  const ALocalizacao, ADetalhe: string);
begin
  Create;
  FSeveridade := ASeveridade;
  FTipo := ATipo;
  FLocalizacao := ALocalizacao;
  FDetalhe := ADetalhe;
end;

function TAnomaliaParse.EhErro: Boolean;
begin
  Result := FSeveridade = saErro;
end;

function TAnomaliaParse.EhAviso: Boolean;
begin
  Result := FSeveridade = saAviso;
end;

function TAnomaliaParse.EhInfo: Boolean;
begin
  Result := FSeveridade = saInfo;
end;

// ────────────────────────────────────────────────────────────
// TResumoParse
// ────────────────────────────────────────────────────────────

constructor TResumoParse.Create;
begin
  inherited;
  FAtos := 0;
  FCapitulos := 0;
  FCenas := 0;
  FParagrafos := 0;
  FPalavras := 0;
  FParagrafosGrandes := 0;
end;

function TResumoParse.DivergenciasDoPadrao: TArray<string>;
var
  Lista: TList<string>;
begin
  Lista := TList<string>.Create;
  try
    if FAtos <> 3 then
      Lista.Add(Format('Esperados 3 atos, encontrados %d.', [FAtos]));
    if FCapitulos <> CAPITULOS_TOTAIS then
      Lista.Add(Format('Esperados %d capítulos, encontrados %d.',
        [CAPITULOS_TOTAIS, FCapitulos]));
    if FParagrafos = 0 then
      Lista.Add('Nenhum parágrafo extraído.');
    if FPalavras = 0 then
      Lista.Add('Nenhuma palavra contabilizada.');
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TResumoParse.MediaPalavrasPorCapitulo: Double;
begin
  if FCapitulos = 0 then
    Exit(0);
  Result := FPalavras / FCapitulos;
end;

// ────────────────────────────────────────────────────────────
// TParseLog
// ────────────────────────────────────────────────────────────

constructor TParseLog.Create;
begin
  inherited;
  FVersaoSchema := 1;
  FTimestamp := Now;
  FResumo := TResumoParse.Create;
  FAnomalias := TObjectList<TAnomaliaParse>.Create;
end;

destructor TParseLog.Destroy;
begin
  FAnomalias.Free;
  FResumo.Free;
  inherited;
end;

function TParseLog.AdicionarAnomalia(
  const AAnomalia: TAnomaliaParse): TParseLog;
begin
  if AAnomalia = nil then
    raise EValorInvalido.Create('Anomalia não pode ser nil.');
  FAnomalias.Add(AAnomalia);
  Result := Self;
end;

function TParseLog.Registrar(const ASeveridade: TSeveridadeAnomalia;
  const ATipo: TTipoAnomalia;
  const ALocalizacao, ADetalhe: string): TParseLog;
var
  A: TAnomaliaParse;
begin
  A := TAnomaliaParse.CreateDe(ASeveridade, ATipo, ALocalizacao, ADetalhe);
  FAnomalias.Add(A);
  Result := Self;
end;

function TParseLog.TemErros: Boolean;
var
  A: TAnomaliaParse;
begin
  for A in FAnomalias do
    if A.EhErro then
      Exit(True);
  Result := False;
end;

function TParseLog.TemAvisos: Boolean;
var
  A: TAnomaliaParse;
begin
  for A in FAnomalias do
    if A.EhAviso then
      Exit(True);
  Result := False;
end;

function TParseLog.Limpo: Boolean;
begin
  Result := FAnomalias.Count = 0;
end;

function TParseLog.TotalAnomalias: Integer;
begin
  Result := FAnomalias.Count;
end;

function TParseLog.AnomaliasPorSeveridade(
  const ASeveridade: TSeveridadeAnomalia): TArray<TAnomaliaParse>;
var
  A: TAnomaliaParse;
  Lista: TList<TAnomaliaParse>;
begin
  Lista := TList<TAnomaliaParse>.Create;
  try
    for A in FAnomalias do
      if A.Severidade = ASeveridade then
        Lista.Add(A);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TParseLog.AnomaliasPorTipo(
  const ATipo: TTipoAnomalia): TArray<TAnomaliaParse>;
var
  A: TAnomaliaParse;
  Lista: TList<TAnomaliaParse>;
begin
  Lista := TList<TAnomaliaParse>.Create;
  try
    for A in FAnomalias do
      if A.Tipo = ATipo then
        Lista.Add(A);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TParseLog.SeveridadeMaxima: TSeveridadeAnomalia;
var
  A: TAnomaliaParse;
begin
  Result := saInfo;
  for A in FAnomalias do
  begin
    if A.Severidade = saErro then
      Exit(saErro);
    if A.Severidade = saAviso then
      Result := saAviso;
  end;
end;

function TParseLog.ResumoTextual: string;
var
  QtdAvisos, QtdErros: Integer;
begin
  QtdAvisos := Length(AnomaliasPorSeveridade(saAviso));
  QtdErros := Length(AnomaliasPorSeveridade(saErro));

  Result := Format(
    '%d atos, %d capítulos, %d cenas, %d parágrafos, %d palavras (%d avisos, %d erros)',
    [FResumo.Atos, FResumo.Capitulos, FResumo.Cenas,
     FResumo.Paragrafos, FResumo.Palavras, QtdAvisos, QtdErros]);
end;

end.
