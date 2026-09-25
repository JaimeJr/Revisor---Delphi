unit UExportarManuscritoUseCase;

{
  UExportarManuscritoUseCase.pas
  ─────────────────────────────────────────────────────────────
  Orquestra a exportação do Novo.JSON para .docx.

    1. Carrega o Novo.JSON.
    2. Aplica a regra de mesclagem por parágrafo:
         • status ∈ {aceito, editado_manual → usa Texto
         • status ∈ {pendente, recusado, revisado_manual → usa TextoOriginal
    3. Escreve o .docx resultante via IDocxWriter.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.IOUtils,
  UINovoRepository,
  UIDocxWriter,
  UManuscrito,
  UValores;

type
  TExportacao = class
  private
    FCaminhoSaida: string;
    FParagrafosTotal: Integer;
    FParagrafosAceitos: Integer;
    FParagrafosRevertidos: Integer;
    FParagrafosEditadosManual: Integer;
    FParagrafosPendentes: Integer;
  public
    property CaminhoSaida: string read FCaminhoSaida write FCaminhoSaida;
    property ParagrafosTotal: Integer
      read FParagrafosTotal write FParagrafosTotal;
    property ParagrafosAceitos: Integer
      read FParagrafosAceitos write FParagrafosAceitos;
    property ParagrafosRevertidos: Integer
      read FParagrafosRevertidos write FParagrafosRevertidos;
    property ParagrafosEditadosManual: Integer
      read FParagrafosEditadosManual write FParagrafosEditadosManual;
    property ParagrafosPendentes: Integer
      read FParagrafosPendentes write FParagrafosPendentes;

    function ResumoTextual: string;
  end;

  TExportarManuscritoUseCase = class
  private
    FNovoRepo: INovoRepository;
    FWriter: IDocxWriter;

    function MesclarParaSaida(const AOriginal: TManuscrito): TManuscrito;
    function TextoParaSaida(const APar: TParagrafo): string;

    /// <summary>
    ///   Preenche as contagens do TExportacao percorrendo o
    ///   manuscrito. AExportacao NÃO é const — é mutada.
    /// </summary>
    procedure Contabilizar(const AManuscrito: TManuscrito;
      AExportacao: TExportacao);
  public
    constructor Create(const ANovoRepo: INovoRepository;
      const AWriter: IDocxWriter);

    function Executar(const ACaminhoNovo,
      ACaminhoDocxSaida: string): TExportacao;
  end;

implementation

{ TExportacao }

function TExportacao.ResumoTextual: string;
begin
  Result := Format(
    'Exportado para "%s": %d parágrafos no total ' +
    '(%d aceitos, %d editados manualmente, %d revertidos, %d pendentes).',
    [ExtractFileName(FCaminhoSaida), FParagrafosTotal,
     FParagrafosAceitos, FParagrafosEditadosManual,
     FParagrafosRevertidos, FParagrafosPendentes]);
end;

{ TExportarManuscritoUseCase }

constructor TExportarManuscritoUseCase.Create(
  const ANovoRepo: INovoRepository; const AWriter: IDocxWriter);
begin
  inherited Create;

  if not Assigned(ANovoRepo) then
    raise EValorInvalido.Create('INovoRepository não pode ser nil.');
  if not Assigned(AWriter) then
    raise EValorInvalido.Create('IDocxWriter não pode ser nil.');

  FNovoRepo := ANovoRepo;
  FWriter := AWriter;
end;

function TExportarManuscritoUseCase.TextoParaSaida(
  const APar: TParagrafo): string;
begin
  case APar.Status of
    spAceito, spEditadoManual:
      Result := APar.Texto;
    spPendente, spRecusado, spRevisadoManual:
      Result := APar.TextoOriginal;
  else
    Result := APar.TextoOriginal;
  end;
end;

function TExportarManuscritoUseCase.MesclarParaSaida(
  const AOriginal: TManuscrito): TManuscrito;
var
  Ato: TAto;
  Cap: TCapitulo;
  Cena: TCena;
  Par: TParagrafo;
  ParOriginal: TParagrafo;
begin
  Result := TManuscrito.NovoAPartirDe(AOriginal);

  for Ato in Result.Atos do
    for Cap in Ato.Capitulos do
      for Cena in Cap.Cenas do
        for Par in Cena.Paragrafos do
        begin
          ParOriginal := AOriginal.ParagrafoPorID(Par.ID);
          if Assigned(ParOriginal) then
            Par.Texto := TextoParaSaida(ParOriginal);
        end;
end;

procedure TExportarManuscritoUseCase.Contabilizar(
  const AManuscrito: TManuscrito; AExportacao: TExportacao);
var
  Ato: TAto;
  Cap: TCapitulo;
  Cena: TCena;
  Par: TParagrafo;
begin
  AExportacao.ParagrafosTotal := 0;
  AExportacao.ParagrafosAceitos := 0;
  AExportacao.ParagrafosRevertidos := 0;
  AExportacao.ParagrafosEditadosManual := 0;
  AExportacao.ParagrafosPendentes := 0;

  for Ato in AManuscrito.Atos do
    for Cap in Ato.Capitulos do
      for Cena in Cap.Cenas do
        for Par in Cena.Paragrafos do
        begin
          Inc(AExportacao.FParagrafosTotal);
          case Par.Status of
            spAceito:
              Inc(AExportacao.FParagrafosTotal);
            spEditadoManual:
              Inc(AExportacao.FParagrafosEditadosManual);
            spRecusado, spRevisadoManual:
              Inc(AExportacao.FParagrafosRevertidos);
            spPendente:
              Inc(AExportacao.FParagrafosPendentes);
          end;
        end;
end;

function TExportarManuscritoUseCase.Executar(const ACaminhoNovo,
  ACaminhoDocxSaida: string): TExportacao;
var
  Original: TManuscrito;
  Saida: TManuscrito;
begin
  if ACaminhoNovo = '' then
    raise EValorInvalido.Create('ACaminhoNovo não pode ser vazio.');
  if ACaminhoDocxSaida = '' then
    raise EValorInvalido.Create('ACaminhoDocxSaida não pode ser vazio.');

  if not FNovoRepo.Existe(ACaminhoNovo) then
    raise EOperacaoInvalida.CreateFmt(
      'Novo.JSON não encontrado em "%s".', [ACaminhoNovo]);

  Original := FNovoRepo.Carregar(ACaminhoNovo);
  if Original = nil then
    raise EOperacaoInvalida.CreateFmt(
      'Falha ao carregar Novo.JSON de "%s".', [ACaminhoNovo]);

  try
    Result := TExportacao.Create;
    try
      Contabilizar(Original, Result);
      Result.CaminhoSaida := ACaminhoDocxSaida;

      Saida := MesclarParaSaida(Original);
      try
        FWriter.Escrever(Saida, ACaminhoDocxSaida);
      finally
        Saida.Free;
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Original.Free;
  end;
end;

end.
