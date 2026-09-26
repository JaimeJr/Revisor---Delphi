unit UCompositionRoot;

{
  UCompositionRoot.pas
  ─────────────────────────────────────────────────────────────
  Raiz de composição da aplicação.

  Nesta versão:
    • O revisor NÃO recebe mais caminhos de Envio/Resposta —
      eles vêm por TChamada.
    • O revisor recebe apenas CaminhoVicios, que é fixo por
      instalação e necessário para o prompt.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  frmPrincipal,
  UIPrincipalView,
  UIMediadorApp,
  UConfigApp,
  UIDocxReader,
  UIDocxWriter,
  UDocxReaderOfficeXML4D,
  UDocxWriterOfficeXML4D,
  UIParserManuscrito,
  UParserManuscrito,
  UIAntesRepository,
  UINovoRepository,
  UIEnvioRepository,
  UIRespostaRepository,
  UIViciosRepository,
  UAntesJsonRepository,
  UNovoJsonRepository,
  UEnvioJsonRepository,
  URespostaJsonRepository,
  UViciosJsonRepository,
  UICacheChamadas,
  UCacheMemoria,
  UIConstrutorPrompt,
  UPromptFactory,
  UIRevisorIA,
  URevisorDeepSeek,
  UImportarManuscritoUseCase,
  UExportarManuscritoUseCase,
  URevisarCenaUseCase,
  UAceitarEdicaoUseCase,
  URecusarEdicaoUseCase,
  UMarcarRevisadoManualUseCase,
  UManterVicioUseCase,
  UCommandStack,
  UPrincipalPresenter,
  UMediadorApp;

type
  TCompositionRoot = class
  private
    FDocxReader: IDocxReader;
    FDocxWriter: IDocxWriter;
    FParser: IParserManuscrito;
    FAntesRepo: IAntesRepository;
    FNovoRepo: INovoRepository;
    FEnvioRepo: IEnvioRepository;
    FRespostaRepo: IRespostaRepository;
    FViciosRepo: IViciosRepository;
    FCache: ICacheChamadas;
    FPromptFactory: IPromptFactory;
    FRevisor: IRevisorIA;

    FCommandStack: TCommandStack;
    FImportarUC: TImportarManuscritoUseCase;
    FExportarUC: TExportarManuscritoUseCase;
    FRevisarUC: TRevisarCenaUseCase;
    FAceitarUC: TAceitarEdicaoUseCase;
    FRecusarUC: TRecusarEdicaoUseCase;
    FMarcarRevisadoUC: TMarcarRevisadoManualUseCase;
    FManterVicioUC: TManterVicioUseCase;
    FMediador: IMediadorApp;
    FPresenter: TPrincipalPresenter;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Iniciar(const AView: TfrmPrincipal);
    procedure Finalizar;
  end;

implementation

uses
  System.IOUtils;

{ TCompositionRoot }

constructor TCompositionRoot.Create;
var
  Config: TConfigApp;
begin
  inherited Create;

  // ─── 1. Config ───
  Config := TConfigApp.Instancia;

  // ─── 2. Adaptadores .docx ───
  FDocxReader := TDocxReaderOfficeXML4D.Create;
  FDocxWriter := TDocxWriterOfficeXML4D.Create;

  // ─── 3. Parser ───
  FParser := TParserManuscrito.Create(FDocxReader,
    Config.LimiteParagrafoPalavras);

  // ─── 4. Repositórios ───
  FAntesRepo := TAntesJsonRepository.Create;
  FNovoRepo := TNovoJsonRepository.Create;
  FEnvioRepo := TEnvioJsonRepository.Create;
  FRespostaRepo := TRespostaJsonRepository.Create;
  FViciosRepo := TViciosJsonRepository.Create;

  // ─── 5. Cache ───
  FCache := TCacheMemoria.Create;

  // ─── 6. Prompts ───
  FPromptFactory := TPromptFactory.Create;

  // ─── 7. Revisor IA ───
  FRevisor := TRevisorDeepSeek.Create(
    Config.ApiKey,
    Config.Modelo,
    Config.Endpoint,
    60000,
    FPromptFactory,
    FCache,
    FEnvioRepo,
    FRespostaRepo,
    FViciosRepo,
    Config.CaminhoViciosJSON,
    Config.PrecoInputPorMilhao,
    Config.PrecoOutputPorMilhao);

  // ─── 8. Command stack ───
  FCommandStack := TCommandStack.Create;

  // ─── 9. UseCases ───
  FImportarUC := TImportarManuscritoUseCase.Create(
    FParser, FAntesRepo, FNovoRepo, FViciosRepo);

  FExportarUC := TExportarManuscritoUseCase.Create(
    FNovoRepo, FDocxWriter);

  FRevisarUC := TRevisarCenaUseCase.Create(
    FRevisor, FNovoRepo, FViciosRepo);

  FAceitarUC := TAceitarEdicaoUseCase.Create(
    FNovoRepo, FViciosRepo, FCommandStack);

  FRecusarUC := TRecusarEdicaoUseCase.Create(
    FNovoRepo, FCommandStack);

  FMarcarRevisadoUC := TMarcarRevisadoManualUseCase.Create(
    FNovoRepo, FCommandStack);

  FManterVicioUC := TManterVicioUseCase.Create(FViciosRepo);

  // ─── 10. Mediador ───
  FMediador := TMediadorApp.Create(
    FRevisarUC, FAceitarUC, FRecusarUC, FManterVicioUC, FViciosRepo);
end;

destructor TCompositionRoot.Destroy;
begin
  Finalizar;
  inherited;
end;

procedure TCompositionRoot.Iniciar(const AView: TfrmPrincipal);
begin
  if not Assigned(AView) then
    raise Exception.Create('TfrmPrincipal não pode ser nil.');

    FPresenter := TPrincipalPresenter.Create(
    AView,
    FMediador,
    FImportarUC,
    FExportarUC,
    FRevisarUC,
    FManterVicioUC,
    FMarcarRevisadoUC,
    FAntesRepo,
    FNovoRepo,
    FRespostaRepo,
    FViciosRepo,
    FCommandStack);

  FPresenter.Iniciar;
end;

procedure TCompositionRoot.Finalizar;
begin
  FreeAndNil(FPresenter);
  FreeAndNil(FManterVicioUC);
  FreeAndNil(FMarcarRevisadoUC);
  FreeAndNil(FRecusarUC);
  FreeAndNil(FAceitarUC);
  FreeAndNil(FRevisarUC);
  FreeAndNil(FExportarUC);
  FreeAndNil(FImportarUC);
  FreeAndNil(FCommandStack);
end;

end.
