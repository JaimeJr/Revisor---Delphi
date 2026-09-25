unit UCompositionRoot;

{
  UCompositionRoot.pas
  ─────────────────────────────────────────────────────────────
  Raiz de composição da aplicação.

  Monta TODAS as dependências na ordem correta, injeta nos
  Presenters e expõe Iniciar / Finalizar.

  Ownership:
    • O CompositionRoot é dono de tudo que cria (UseCases,
      CommandStack, Presenter, Mediador).
    • As interfaces (repos, cache, prompt factory, parser,
      revisor) são reference-counted — basta manter referências.
    • O TConfigApp é singleton, não é liberado aqui.
    • O frmPrincipal é do Application, não é liberado aqui.

  Ordem de destruição (em Finalizar):
    1. Presenter  (referencia View + UseCases)
    2. Mediador   (referencia UseCases + repos)
    3. UseCases   (referenciam repos via interface)
    4. CommandStack
    5. Interfaces saem de escopo por ref count
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
    // ─── Interfaces (ref-counted, não liberadas manualmente) ───
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

    // ─── Classes com ownership explícito ───
    FCommandStack: TCommandStack;
    FImportarUC: TImportarManuscritoUseCase;
    FExportarUC: TExportarManuscritoUseCase;
    FRevisarUC: TRevisarCenaUseCase;
    FAceitarUC: TAceitarEdicaoUseCase;
    FRecusarUC: TRecusarEdicaoUseCase;
    FMarcarRevisadoUC: TMarcarRevisadoManualUseCase;
    FManterVicioUC: TManterVicioUseCase;
    FMediador: TMediadorApp;
    FPresenter: TPrincipalPresenter;

    function CaminhoViciosPadrao: string;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Amarra a View ao Presenter e chama Iniciar. Deve ser
    ///   chamado depois de Application.CreateForm.
    /// </summary>
    procedure Iniciar(const AView: TfrmPrincipal);

    /// <summary>
    ///   Libera Presenter e Mediador. Chamado no finally do
    ///   Application.Run.
    /// </summary>
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

  // ─── 1. Config (singleton, carrega chave do disco) ───
  Config := TConfigApp.Instancia;

  // ─── 2. Adaptadores de .docx ───
  FDocxReader := TDocxReaderOfficeXML4D.Create;
  FDocxWriter := TDocxWriterOfficeXML4D.Create;

  // ─── 3. Parser de manuscrito ───
  FParser := TParserManuscrito.Create(FDocxReader,
    Config.LimiteParagrafoPalavras);

  // ─── 4. Repositórios ───
  FAntesRepo := TAntesJsonRepository.Create;
  FNovoRepo := TNovoJsonRepository.Create;
  FEnvioRepo := TEnvioJsonRepository.Create;
  FRespostaRepo := TRespostaJsonRepository.Create;
  FViciosRepo := TViciosJsonRepository.Create;

  // ─── 5. Cache de chamadas ───
  FCache := TCacheMemoria.Create;

  // ─── 6. Construtores de prompt ───
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
    '',
    '',
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

function TCompositionRoot.CaminhoViciosPadrao: string;
begin
  Result := TConfigApp.Instancia.CaminhoViciosJSON;
end;

procedure TCompositionRoot.Iniciar(const AView: TfrmPrincipal);
begin
  if not Assigned(AView) then
    raise Exception.Create('TfrmPrincipal não pode ser nil.');

  // O Presenter recebe a View como IPrincipalView. Como o
  // frmPrincipal implementa essa interface, é só passar.
  FPresenter := TPrincipalPresenter.Create(
    AView,
    FMediador,
    FImportarUC,
    FExportarUC,
    FRevisarUC,
    FManterVicioUC,
    FMarcarRevisadoUC,
    FNovoRepo,
    FRespostaRepo,
    FViciosRepo,
    FCommandStack);

  FPresenter.Iniciar;
end;

procedure TCompositionRoot.Finalizar;
begin
  FreeAndNil(FPresenter);
  FreeAndNil(FMediador);
  FreeAndNil(FManterVicioUC);
  FreeAndNil(FMarcarRevisadoUC);
  FreeAndNil(FRecusarUC);
  FreeAndNil(FAceitarUC);
  FreeAndNil(FRevisarUC);
  FreeAndNil(FExportarUC);
  FreeAndNil(FImportarUC);
  FreeAndNil(FCommandStack);

  // As interfaces saem de escopo por ref count quando o
  // CompositionRoot é liberado. Não é preciso nil nelas.
end;

end.
