unit UImportarManuscritoUseCase;

{
  UImportarManuscritoUseCase.pas
  ─────────────────────────────────────────────────────────────
  Orquestra a importação de um manuscrito .docx:

    1. Parseia o .docx via IParserManuscrito.
    2. Salva o Antes.JSON (sobrescreve se já existir).
    3. Salva o parse.log.
    4. Cria o Novo.JSON inicial a partir do Antes.
    5. Salva o Novo.JSON.
    6. Garante que o Vicios.JSON existe (cria semente se preciso).

  Ownership:
    • O UseCase devolve um TImportacao.
    • TImportacao possui o TParseResultado (que possui o
      Manuscrito e o Log). Quem chama libera o TImportacao.
    • Nenhum caminho é hard-coded: pasta destino e caminho do
      Vicios.JSON vêm por parâmetro — testável sem TConfigApp.

  Decisão: reimportar sobrescreve o Antes.JSON. O Antes é
  imutável durante uma sessão, mas pode ser regerado quando o
  parser muda ou o autor reedita o .docx original.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.IOUtils,
  UIParserManuscrito,
  UIAntesRepository,
  UINovoRepository,
  UIViciosRepository,
  UManuscrito,
  UAnomaliaParse,
  UValores;

type
  /// <summary>
  ///   Resultado completo de uma importação. Ownership de
  ///   TParseResultado (e, por consequência, do Manuscrito e
  ///   do Log) pertence a este objeto.
  /// </summary>
  TImportacao = class
  private
    FResultadoParse: TParseResultado;
    FCaminhoAntes: string;
    FCaminhoNovo: string;
    FCaminhoParseLog: string;
    FCaminhoVicios: string;
  public
    constructor Create(const AResultadoParse: TParseResultado;
      const ACaminhoAntes, ACaminhoNovo, ACaminhoParseLog,
      ACaminhoVicios: string);

    destructor Destroy; override;

    property ResultadoParse: TParseResultado read FResultadoParse;
    property CaminhoAntes: string read FCaminhoAntes;
    property CaminhoNovo: string read FCaminhoNovo;
    property CaminhoParseLog: string read FCaminhoParseLog;
    property CaminhoVicios: string read FCaminhoVicios;

    /// <summary>Atalho para o log de parse.</summary>
    function LogParse: TParseLog;

    /// <summary>Atalho para o manuscrito original.</summary>
    function ManuscritoOriginal: TManuscrito;

    /// <summary>Resumo textual para barra de status.</summary>
    function ResumoTextual: string;
  end;

  TImportarManuscritoUseCase = class
  private
    FParser: IParserManuscrito;
    FAntesRepo: IAntesRepository;
    FNovoRepo: INovoRepository;
    FViciosRepo: IViciosRepository;

    function DerivarCaminhos(const ADocxPath, APastaDestino: string;
      out ACaminhoAntes, ACaminhoNovo, ACaminhoParseLog: string): string;
  public
    constructor Create(const AParser: IParserManuscrito;
      const AAntesRepo: IAntesRepository;
      const ANovoRepo: INovoRepository;
      const AViciosRepo: IViciosRepository);

    function Executar(const ADocxPath, APastaDestino,
      ACaminhoVicios: string): TImportacao;
  end;

implementation

{ TImportacao }

constructor TImportacao.Create(const AResultadoParse: TParseResultado;
  const ACaminhoAntes, ACaminhoNovo, ACaminhoParseLog,
  ACaminhoVicios: string);
begin
  inherited Create;
  if not Assigned(AResultadoParse) then
    raise EValorInvalido.Create('TParseResultado não pode ser nil.');

  FResultadoParse := AResultadoParse;
  FCaminhoAntes := ACaminhoAntes;
  FCaminhoNovo := ACaminhoNovo;
  FCaminhoParseLog := ACaminhoParseLog;
  FCaminhoVicios := ACaminhoVicios;
end;

destructor TImportacao.Destroy;
begin
  FResultadoParse.Free;
  inherited;
end;

function TImportacao.LogParse: TParseLog;
begin
  Result := FResultadoParse.Log;
end;

function TImportacao.ManuscritoOriginal: TManuscrito;
begin
  Result := FResultadoParse.Manuscrito;
end;

function TImportacao.ResumoTextual: string;
begin
  Result := FResultadoParse.Log.ResumoTextual;
end;

{ TImportarManuscritoUseCase }

constructor TImportarManuscritoUseCase.Create(
  const AParser: IParserManuscrito;
  const AAntesRepo: IAntesRepository;
  const ANovoRepo: INovoRepository;
  const AViciosRepo: IViciosRepository);
begin
  inherited Create;

  if not Assigned(AParser) then
    raise EValorInvalido.Create('IParserManuscrito não pode ser nil.');
  if not Assigned(AAntesRepo) then
    raise EValorInvalido.Create('IAntesRepository não pode ser nil.');
  if not Assigned(ANovoRepo) then
    raise EValorInvalido.Create('INovoRepository não pode ser nil.');
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');

  FParser := AParser;
  FAntesRepo := AAntesRepo;
  FNovoRepo := ANovoRepo;
  FViciosRepo := AViciosRepo;
end;

function TImportarManuscritoUseCase.DerivarCaminhos(
  const ADocxPath, APastaDestino: string;
  out ACaminhoAntes, ACaminhoNovo, ACaminhoParseLog: string): string;
var
  NomeBase: string;
begin
  if ADocxPath = '' then
    raise EValorInvalido.Create('ADocxPath não pode ser vazio.');
  if APastaDestino = '' then
    raise EValorInvalido.Create('APastaDestino não pode ser vazia.');

  NomeBase := TPath.GetFileNameWithoutExtension(ADocxPath);

  ACaminhoAntes := TPath.Combine(APastaDestino,
    NomeBase + '_antes.json');
  ACaminhoNovo := TPath.Combine(APastaDestino,
    NomeBase + '_novo.json');
  ACaminhoParseLog := TPath.Combine(APastaDestino,
    NomeBase + '_parse.log');

  Result := NomeBase;
end;

function TImportarManuscritoUseCase.Executar(
  const ADocxPath, APastaDestino,
  ACaminhoVicios: string): TImportacao;
var
  CaminhoAntes, CaminhoNovo, CaminhoParseLog: string;
  ResultadoParse: TParseResultado;
  NovoManuscrito: TManuscrito;
  Importacao: TImportacao;
  Sucesso: Boolean;
begin
  if not TFile.Exists(ADocxPath) then
    raise EOperacaoInvalida.CreateFmt(
      'Arquivo .docx não encontrado: %s', [ADocxPath]);

  if not TDirectory.Exists(APastaDestino) then
    TDirectory.CreateDirectory(APastaDestino);

  if ACaminhoVicios = '' then
    raise EValorInvalido.Create('ACaminhoVicios não pode ser vazio.');

  DerivarCaminhos(ADocxPath, APastaDestino,
    CaminhoAntes, CaminhoNovo, CaminhoParseLog);

  // ─── 1. Parseia o .docx ───
  ResultadoParse := FParser.Parsear(ADocxPath);

  Sucesso := False;
  NovoManuscrito := nil;
  try
    try
      // ─── 2. Salva Antes.JSON (sobrescreve se existir) ───
      FAntesRepo.Salvar(ResultadoParse.Manuscrito, CaminhoAntes);

      // ─── 3. Salva parse.log ───
      FAntesRepo.SalvarLog(ResultadoParse.Log, CaminhoAntes);

      // ─── 4. Cria Novo.JSON inicial a partir do Antes ───
      NovoManuscrito := TManuscrito.NovoAPartirDe(
        ResultadoParse.Manuscrito);

      // ─── 5. Salva Novo.JSON (sobrescreve se existir) ───
      FNovoRepo.SalvarAuto(NovoManuscrito, CaminhoNovo);

      // ─── 6. Garante Vicios.JSON ───
      FViciosRepo.GarantirSemente(ACaminhoVicios);

      // ─── Monta o resultado ───
      Importacao := TImportacao.Create(
        ResultadoParse,
        CaminhoAntes,
        CaminhoNovo,
        CaminhoParseLog,
        ACaminhoVicios);
      ResultadoParse := nil;  // ownership transferido

      Result := Importacao;
      Sucesso := True;
    finally
      if not Sucesso then
      begin
        NovoManuscrito.Free;
        ResultadoParse.Free;
      end;
    end;
  except
    raise;
  end;
end;

end.
