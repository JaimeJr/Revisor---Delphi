unit UMediadorApp;

interface

uses
  System.SysUtils,
  System.UITypes,
  UIMediadorApp,
  UManuscrito,
  UEdicaoSugerida,
  UTiposUI,
  UValores,
  URevisarCenaUseCase,
  UAceitarEdicaoUseCase,
  URecusarEdicaoUseCase,
  UManterVicioUseCase,
  UIViciosRepository;

type
  TMediadorApp = class(TInterfacedObject, IMediadorApp)
  private
    FRevisarUC: TRevisarCenaUseCase;
    FAceitarUC: TAceitarEdicaoUseCase;
    FRecusarUC: TRecusarEdicaoUseCase;
    FManterVicioUC: TManterVicioUseCase;
    FViciosRepo: IViciosRepository;
  public
    constructor Create(const ARevisarUC: TRevisarCenaUseCase;
      const AAceitarUC: TAceitarEdicaoUseCase;
      const ARecusarUC: TRecusarEdicaoUseCase;
      const AManterVicioUC: TManterVicioUseCase;
      const AViciosRepo: IViciosRepository);

    procedure AbrirRevisao(const AContexto: TContextoRevisao;
      const AOnFechada: TProcRevisaoFechada);

    procedure AbrirVicios(const ACaminhoVicios: string;
      const AOnFechada: TProcRevisaoFechada);

    function PerguntarObservacaoReenvio: string;

    procedure ExecutarComLoading(const AMensagem: string;
      const AOperacao: TProc);
  end;

implementation

uses
  Vcl.Forms,
  frmRevisao,
  frmVicios,
  frmReenvio,
  frmLoading,
  URevisaoPresenter,
  UViciosPresenter;

{ TMediadorApp }

constructor TMediadorApp.Create(const ARevisarUC: TRevisarCenaUseCase;
  const AAceitarUC: TAceitarEdicaoUseCase;
  const ARecusarUC: TRecusarEdicaoUseCase;
  const AManterVicioUC: TManterVicioUseCase;
  const AViciosRepo: IViciosRepository);
begin
  inherited Create;

  if not Assigned(ARevisarUC) then
    raise EValorInvalido.Create('TRevisarCenaUseCase não pode ser nil.');
  if not Assigned(AAceitarUC) then
    raise EValorInvalido.Create('TAceitarEdicaoUseCase não pode ser nil.');
  if not Assigned(ARecusarUC) then
    raise EValorInvalido.Create('TRecusarEdicaoUseCase não pode ser nil.');
  if not Assigned(AManterVicioUC) then
    raise EValorInvalido.Create('TManterVicioUseCase não pode ser nil.');
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');

  FRevisarUC := ARevisarUC;
  FAceitarUC := AAceitarUC;
  FRecusarUC := ARecusarUC;
  FManterVicioUC := AManterVicioUC;
  FViciosRepo := AViciosRepo;
end;

procedure TMediadorApp.AbrirRevisao(const AContexto: TContextoRevisao;
  const AOnFechada: TProcRevisaoFechada);
var
  Form: TfrmRevisao;
  Presenter: TRevisaoPresenter;
begin
  if not Assigned(AContexto) then
    raise EValorInvalido.Create('TContextoRevisao não pode ser nil.');

  Form := TfrmRevisao.Create(Application);
  try
    Presenter := TRevisaoPresenter.Create(
      Form, Self, FAceitarUC, FRecusarUC, FRevisarUC,
      AContexto, AOnFechada);
    try
      Presenter.Iniciar;
      Form.ShowModal;
    finally
      Presenter.Free;
    end;
  finally
    AContexto.Free;
    Form.Free;
  end;
end;

procedure TMediadorApp.AbrirVicios(const ACaminhoVicios: string;
  const AOnFechada: TProcRevisaoFechada);
var
  Form: TfrmVicios;
  Presenter: TViciosPresenter;
begin
  if ACaminhoVicios = '' then
    raise EValorInvalido.Create('CaminhoVicios não pode ser vazio.');

  Form := TfrmVicios.Create(Application);
  try
    Presenter := TViciosPresenter.Create(
      Form, FManterVicioUC, FViciosRepo, ACaminhoVicios);
    try
      Presenter.Iniciar;
      Form.ShowModal;
    finally
      Presenter.Free;
    end;
  finally
    Form.Free;

    if Assigned(AOnFechada) then
      AOnFechada();
  end;
end;

function TMediadorApp.PerguntarObservacaoReenvio: string;
var
  Form: TfrmReenvio;
begin
  Form := TfrmReenvio.Create(Application);
  try
    if Form.ModalResult = mrOk then
      Result := Form.Observacao
    else
      Result := '';
  finally
    Form.Free;
  end;
end;

procedure TMediadorApp.ExecutarComLoading(const AMensagem: string;
  const AOperacao: TProc);
var
  Form: TfrmLoading;
begin
  if not Assigned(AOperacao) then
    raise EValorInvalido.Create('Operação não pode ser nil.');

  Form := TfrmLoading.Create(Application);
  try
    Form.Configurar(AMensagem, AOperacao);
    // ShowModal dispara OnShow → executa a operação → fecha.
    // Exceções da operação propagam.
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.
