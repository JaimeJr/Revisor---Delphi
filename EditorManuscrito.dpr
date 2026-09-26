program EditorManuscrito;

uses
  Vcl.Forms,
  UValores in 'src\Domain\UValores.pas',
  UAnomaliaParser in 'src\Domain\UAnomaliaParser.pas',
  UServicosDominio in 'src\Domain\UServicosDominio.pas',
  UAnomaliaParse in 'src\Domain\UAnomaliaParse.pas',
  UChamada in 'src\Domain\UChamada.pas',
  UIParserManuscrito in 'src\Domain\Contratos\UIParserManuscrito.pas',
  UIDocxWriter in 'src\Domain\Contratos\UIDocxWriter.pas',
  UIDocxReader in 'src\Domain\Contratos\UIDocxReader.pas',
  UIAntesRepository in 'src\Domain\Contratos\UIAntesRepository.pas',
  UINovoRepository in 'src\Domain\Contratos\UINovoRepository.pas',
  UConfigApp in 'src\Infrastructure\Config\UConfigApp.pas',
  UKeyLoader in 'src\Infrastructure\Config\UKeyLoader.pas',
  UAntesJsonRepository in 'src\Infrastructure\Repos\UAntesJsonRepository.pas',
  UNovoJsonRepository in 'src\Infrastructure\Repos\UNovoJsonRepository.pas',
  UEnvioJsonRepository in 'src\Infrastructure\Repos\UEnvioJsonRepository.pas',
  UVicio in 'src\Domain\UVicio.pas',
  UViciosJsonRepository in 'src\Infrastructure\Repos\UViciosJsonRepository.pas',
  UImportarManuscritoUseCase in 'src\Application\UImportarManuscritoUseCase.pas',
  UExportarManuscritoUseCase in 'src\Application\UExportarManuscritoUseCase.pas',
  UNormalizadorTexto in 'src\Infrastructure\Text\UNormalizadorTexto.pas',
  URespostaJsonRepository in 'src\Infrastructure\Repos\URespostaJsonRepository.pas',
  UEdicaoSugerida in 'src\Domain\UEdicaoSugerida.pas',
  UPromptCirurgico in 'src\Infrastructure\DeepSeek\UPromptCirurgico.pas',
  UIConstrutorPrompt in 'src\Domain\Contratos\UIConstrutorPrompt.pas',
  UPromptVarredura in 'src\Infrastructure\DeepSeek\UPromptVarredura.pas',
  UPromptFactory in 'src\Infrastructure\DeepSeek\UPromptFactory.pas',
  UIRevisorIA in 'src\Domain\Contratos\UIRevisorIA.pas',
  UICacheChamadas in 'src\Domain\Contratos\UICacheChamadas.pas',
  URevisorDeepSeek in 'src\Infrastructure\DeepSeek\URevisorDeepSeek.pas',
  UIViciosRepository in 'src\Domain\Contratos\UIViciosRepository.pas',
  URevisarCenaUseCase in 'src\Application\URevisarCenaUseCase.pas',
  UAceitarEdicaoCommand in 'src\Application\Commands\UAceitarEdicaoCommand.pas',
  UAceitarEdicaoUseCase in 'src\Application\UAceitarEdicaoUseCase.pas',
  UCommandStack in 'src\Application\Commands\UCommandStack.pas',
  UIComandoEditorial in 'src\Domain\Contratos\UIComandoEditorial.pas',
  URecusarEdicaoUseCase in 'src\Application\URecusarEdicaoUseCase.pas',
  URecusarEdicaoCommand in 'src\Application\Commands\URecusarEdicaoCommand.pas',
  UManterVicioUseCase in 'src\Application\UManterVicioUseCase.pas',
  UIPrincipalView in 'src\Presentation\Interfaces\UIPrincipalView.pas',
  UTiposUI in 'src\Domain\UTiposUI.pas',
  frmPrincipal in 'src\Presentation\Forms\frmPrincipal.pas' {frmPrincipal},
  UIMediadorApp in 'src\Domain\Contratos\UIMediadorApp.pas',
  UMarcarRevisadoManualCommand in 'src\Application\Commands\UMarcarRevisadoManualCommand.pas',
  UMarcarRevisadoManualUseCase in 'src\Application\UMarcarRevisadoManualUseCase.pas',
  UManuscrito in 'src\Domain\UManuscrito.pas',
  UIViciosView in 'src\Presentation\Interfaces\UIViciosView.pas' {$R *.res},
  URevisaoPresenter in 'src\Presentation\Presenters\URevisaoPresenter.pas',
  UIRevisaoView in 'src\Presentation\Interfaces\UIRevisaoView.pas' {$R *.res},
  frmReenvio in 'src\Presentation\Forms\frmReenvio.pas' {frmReenvio},
  frmRevisao in 'src\Presentation\Forms\frmRevisao.pas' {frmRevisao},
  UViciosPresenter in 'src\Presentation\Presenters\UViciosPresenter.pas',
  frmVicios in 'src\Presentation\Forms\frmVicios.pas' {frmVicios},
  UMediadorApp in 'src\Presentation\UMediadorApp.pas',
  UCompositionRoot in 'src\UCompositionRoot.pas',
  UDocxReaderOfficeXML4D in 'src\Infrastructure\Docx\UDocxReaderOfficeXML4D.pas',
  UDocxWriterOfficeXML4D in 'src\Infrastructure\Docx\UDocxWriterOfficeXML4D.pas',
  UParserManuscrito in 'src\Infrastructure\Docx\UParserManuscrito.pas',
  UCacheMemoria in 'src\Infrastructure\Cache\UCacheMemoria.pas',
  UIEnvioRepository in 'src\Domain\Contratos\UIEnvioRepository.pas',
  UIRespostaRepository in 'src\Domain\Contratos\UIRespostaRepository.pas',
  UPrincipalPresenter in 'src\Presentation\Presenters\UPrincipalPresenter.pas',
  frmLoading in 'src\Presentation\Forms\frmLoading.pas' {frmLoading},
  UIGatilhoLocal in 'src\Domain\Contratos\UIGatilhoLocal.pas',
  UAvaliarGatilhosUseCase in 'src\Infrastructure\Gatilhos\UAvaliarGatilhosUseCase.pas',
  UGatilhoRegistry in 'src\Infrastructure\Gatilhos\UGatilhoRegistry.pas',
  UGatilhoAnafora in 'src\Infrastructure\Gatilhos\UGatilhoAnafora.pas';

{$R *.res}

begin
  var
    Root: TCompositionRoot;
  begin
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.Title := 'Editor de Manuscrito';
    Root := TCompositionRoot.Create;
    try
      Application.CreateForm(TfrmPrincipal, FormPrincipal);
      Root.Iniciar(FormPrincipal);
      Application.Run;
    finally
      Root.Finalizar;
      Root.Free;
    end;
  end;
end.
