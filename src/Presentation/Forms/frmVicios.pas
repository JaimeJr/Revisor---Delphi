unit frmVicios;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Graphics,
  Vcl.ExtCtrls,
  UIViciosView,
  UTiposUI,
  UValores;

type
  TfrmVicios = class(TForm, IUViciosView)
    // Topo
    pnlTop: TPanel;
    lblTitulo: TLabel;

    // Esquerda — lista
    pnlLeft: TPanel;
    lstVicios: TListBox;
    splitterLeft: TSplitter;

    // Direita — formulário
    pnlRight: TPanel;
    lblID: TLabel;
    edtID: TEdit;
    lblNome: TLabel;
    edtNome: TEdit;
    lblDescricao: TLabel;
    memDescricao: TMemo;
    lblDica: TLabel;
    memDica: TMemo;
    lblGatilho: TLabel;
    edtGatilho: TEdit;
    chkCrossCena: TCheckBox;
    lblOrigem: TLabel;
    lblOrigemValor: TLabel;
    lblFrequencia: TLabel;
    lblFrequenciaValor: TLabel;

    // Rodapé
    pnlBotoes: TPanel;
    btnNovo: TButton;
    btnSalvar: TButton;
    btnRemover: TButton;
    btnFechar: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnNovoClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure BtnRemoverClick(Sender: TObject);
    procedure BtnFecharClick(Sender: TObject);
    procedure LstViciosClick(Sender: TObject);
    procedure EdtIDChange(Sender: TObject);
  private
    FModoNovo: Boolean;
    FSelecionadoID: string;
    FTemAlteracao: Boolean;

    FAoSelecionarVicio: TProcVicioID;
    FAoNovoVicio: TProcSimplesVicios;
    FAoSalvarVicio: TProcSalvarVicio;
    FAoRemoverVicio: TProcVicioID;
    FAoFechar: TProcSimplesVicios;

    procedure MarcarAlterado;
    procedure ConfirmarTroca;
    function ValidarID(const AID: string; out AMotivo: string): Boolean;
    procedure ExibirAviso(const AMensagem: string);
    procedure ExibirDetalheNulo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // ????????????????????????????????????????????????????????
    //  IUViciosView
    // ????????????????????????????????????????????????????????

    procedure ExibirCatalogo(const AVicios: TArray<TVicioUI>);
    procedure ExibirDetalhe(const AVicio: TVicioUI);
    procedure EntrarModoNovo;
    procedure SelecionarNaLista(const AID: string);

    procedure HabilitarRemover(const AHabilitado: Boolean;
      const AMotivo: string);
    procedure HabilitarSalvar(const AHabilitado: Boolean);
    procedure HabilitarIDEditavel(const AEditavel: Boolean);

    procedure ExibirErro(const AMensagem: string);
    procedure ExibirInfo(const AMensagem: string);
    function Confirmar(const AMensagem: string): Boolean;

    procedure MostrarProgresso(const AMensagem: string);
    procedure OcultarProgresso;
    procedure FecharTela;

    function IDEmEdicao: string;
    function NomeEmEdicao: string;
    function DescricaoEmEdicao: string;
    function DicaEmEdicao: string;
    function GatilhoEmEdicao: string;
    function CrossCenaEmEdicao: Boolean;

    function GetAoSelecionarVicio: TProcVicioID;
    procedure SetAoSelecionarVicio(const Value: TProcVicioID);
    property AoSelecionarVicio: TProcVicioID
      read GetAoSelecionarVicio write SetAoSelecionarVicio;

    function GetAoNovoVicio: TProcSimplesVicios;
    procedure SetAoNovoVicio(const Value: TProcSimplesVicios);
    property AoNovoVicio: TProcSimplesVicios
      read GetAoNovoVicio write SetAoNovoVicio;

    function GetAoSalvarVicio: TProcSalvarVicio;
    procedure SetAoSalvarVicio(const Value: TProcSalvarVicio);
    property AoSalvarVicio: TProcSalvarVicio
      read GetAoSalvarVicio write SetAoSalvarVicio;

    function GetAoRemoverVicio: TProcVicioID;
    procedure SetAoRemoverVicio(const Value: TProcVicioID);
    property AoRemoverVicio: TProcVicioID
      read GetAoRemoverVicio write SetAoRemoverVicio;

    function GetAoFechar: TProcSimplesVicios;
    procedure SetAoFechar(const Value: TProcSimplesVicios);
    property AoFechar: TProcSimplesVicios
      read GetAoFechar write SetAoFechar;

    // ??? Suporte a interface (sem ref counting) ???
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

var
  FormVicios: TfrmVicios;

implementation

{$R *.dfm}

{ TfrmVicios }

constructor TfrmVicios.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FModoNovo := False;
  FSelecionadoID := '';
  FTemAlteracao := False;
end;

destructor TfrmVicios.Destroy;
begin
  inherited;
end;

procedure TfrmVicios.FormCreate(Sender: TObject);
begin
  FModoNovo := False;
  FSelecionadoID := '';
  FTemAlteracao := False;
  HabilitarSalvar(False);
  HabilitarRemover(False, 'Nenhum vício selecionado.');
  HabilitarIDEditavel(False);
  lblOrigemValor.Caption := '';
  lblFrequenciaValor.Caption := '';
end;

procedure TfrmVicios.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FTemAlteracao then
  begin
    if not Confirmar(
      'Há alterações não salvas. Descartar e fechar?') then
    begin
      Action := caNone;
      Exit;
    end;
  end;

  if Assigned(FAoFechar) then
    FAoFechar();
end;

// ????????????????????????????????????????????????????????????
// Handlers de componentes
// ????????????????????????????????????????????????????????????

procedure TfrmVicios.BtnNovoClick(Sender: TObject);
begin
  ConfirmarTroca;
  if Assigned(FAoNovoVicio) then
    FAoNovoVicio();
end;

procedure TfrmVicios.BtnSalvarClick(Sender: TObject);
var
  MotivoID: string;
begin
  if Trim(edtNome.Text) = '' then
  begin
    ExibirAviso('Nome não pode ser vazio.');
    edtNome.SetFocus;
    Exit;
  end;

  if FModoNovo then
  begin
    if not ValidarID(edtID.Text, MotivoID) then
    begin
      ExibirErro(MotivoID);
      edtID.SetFocus;
      Exit;
    end;
  end;

  if Assigned(FAoSalvarVicio) then
    FAoSalvarVicio(
      Trim(edtID.Text),
      Trim(edtNome.Text),
      Trim(memDescricao.Text),
      Trim(memDica.Text),
      Trim(edtGatilho.Text),
      chkCrossCena.Checked);
end;

procedure TfrmVicios.BtnRemoverClick(Sender: TObject);
begin
  if FSelecionadoID = '' then
    Exit;

  if not Confirmar(Format(
    'Remover o vício "%s" do catálogo? ' +
    'Esta ação não pode ser desfeita.',
    [FSelecionadoID])) then
    Exit;

  if Assigned(FAoRemoverVicio) then
    FAoRemoverVicio(FSelecionadoID);
end;

procedure TfrmVicios.BtnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmVicios.LstViciosClick(Sender: TObject);
var
  ID: string;
begin
  if lstVicios.ItemIndex < 0 then
    Exit;

  ID := lstVicios.Items[lstVicios.ItemIndex];
  if ID = FSelecionadoID then
    Exit;

  ConfirmarTroca;
  if Assigned(FAoSelecionarVicio) then
    FAoSelecionarVicio(ID);
end;

procedure TfrmVicios.EdtIDChange(Sender: TObject);
begin
  // Só invalida se estamos em modo novo (em edição o ID é read-only).
  if FModoNovo then
    MarcarAlterado;
end;

// ????????????????????????????????????????????????????????????
// Auxiliares internos
// ????????????????????????????????????????????????????????????

procedure TfrmVicios.MarcarAlterado;
begin
  FTemAlteracao := True;
end;

procedure TfrmVicios.ConfirmarTroca;
begin
  // Sem alterações — não pergunta nada.
  if not FTemAlteracao then
    Exit;

  if Confirmar('Há alterações não salvas. Descartar?') then
    FTemAlteracao := False;
end;

function TfrmVicios.ValidarID(const AID: string;
  out AMotivo: string): Boolean;
begin
  AMotivo := '';
  if AID.Trim = '' then
  begin
    AMotivo := 'ID não pode ser vazio.';
    Exit(False);
  end;
  // Validação completa fica no UseCase; aqui só o básico
  // para feedback imediato ao usuário.
  if not CharInSet(AID.Trim[1], ['a'..'z']) then
  begin
    AMotivo := 'ID deve começar com letra minúscula.';
    Exit(False);
  end;
  Result := True;
end;

procedure TfrmVicios.ExibirAviso(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtWarning, [mbOK], 0);
end;

procedure TfrmVicios.ExibirCatalogo(const AVicios: TArray<TVicioUI>);
var
  V: TVicioUI;
  IDSelecionado: string;
begin
  IDSelecionado := FSelecionadoID;

  lstVicios.Items.BeginUpdate;
  try
    lstVicios.Items.Clear;
    for V in AVicios do
      lstVicios.Items.Add(V.ID);
  finally
    lstVicios.Items.EndUpdate;
  end;

  if IDSelecionado <> '' then
    SelecionarNaLista(IDSelecionado);
end;

procedure TfrmVicios.ExibirDetalhe(const AVicio: TVicioUI);
begin
  if AVicio = nil then
  begin
    ExibirDetalheNulo;
    Exit;
  end;

  FModoNovo := False;
  FSelecionadoID := AVicio.ID;
  FTemAlteracao := False;

  edtID.Text := AVicio.ID;
  edtNome.Text := AVicio.Nome;
  memDescricao.Text := AVicio.Descricao;
  memDica.Text := AVicio.DicaCorrecao;
  edtGatilho.Text := AVicio.GatilhoLocal;
  chkCrossCena.Checked := AVicio.PrecisaCrossCena;

  lblOrigemValor.Caption := 'Sistema';
  lblFrequenciaValor.Caption := IntToStr(AVicio.FrequenciaNoManuscrito);

  HabilitarIDEditavel(False);
  HabilitarSalvar(True);
  HabilitarRemover(AVicio.EhGenerico,'Vícios do sistema não podem ser removidos.');

  SelecionarNaLista(AVicio.ID);
end;

procedure TfrmVicios.ExibirDetalheNulo;
begin
  FModoNovo := False;
  FSelecionadoID := '';
  FTemAlteracao := False;

  edtID.Text := '';
  edtNome.Text := '';
  memDescricao.Clear;
  memDica.Clear;
  edtGatilho.Clear;
  chkCrossCena.Checked := False;

  lblOrigemValor.Caption := '';
  lblFrequenciaValor.Caption := '';

  HabilitarIDEditavel(False);
  HabilitarSalvar(False);
  HabilitarRemover(False, 'Nenhum vício selecionado.');
end;

procedure TfrmVicios.EntrarModoNovo;
begin
  FModoNovo := True;
  FSelecionadoID := '';
  FTemAlteracao := False;

  edtID.Text := '';
  edtNome.Text := '';
  memDescricao.Clear;
  memDica.Clear;
  edtGatilho.Clear;
  chkCrossCena.Checked := False;

  lblOrigemValor.Caption := 'Autor';
  lblFrequenciaValor.Caption := '0';

  HabilitarIDEditavel(True);
  HabilitarSalvar(True);
  HabilitarRemover(False, 'Salve o novo vício antes de removê-lo.');

  if lstVicios.ItemIndex >= 0 then
    lstVicios.ItemIndex := -1;

  edtID.SetFocus;
end;

procedure TfrmVicios.SelecionarNaLista(const AID: string);
var
  I: Integer;
begin
  for I := 0 to lstVicios.Items.Count - 1 do
    if lstVicios.Items[I] = AID then
    begin
      lstVicios.ItemIndex := I;
      Exit;
    end;
  lstVicios.ItemIndex := -1;
end;

// ????????????????????????????????????????????????????????????
// IUViciosView — habilitar / desabilitar
// ????????????????????????????????????????????????????????????

procedure TfrmVicios.HabilitarRemover(const AHabilitado: Boolean;
  const AMotivo: string);
begin
  btnRemover.Enabled := not AHabilitado;
  if AHabilitado and (AMotivo <> '') then
    btnRemover.Hint := AMotivo
  else
    btnRemover.Hint := '';
end;

procedure TfrmVicios.HabilitarSalvar(const AHabilitado: Boolean);
begin
  btnSalvar.Enabled := AHabilitado;
end;

procedure TfrmVicios.HabilitarIDEditavel(const AEditavel: Boolean);
begin
  edtID.ReadOnly := not AEditavel;
  edtID.Color := clWindow;
end;

// ????????????????????????????????????????????????????????????
// IUViciosView — diálogos
// ????????????????????????????????????????????????????????????

procedure TfrmVicios.ExibirErro(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtError, [mbOK], 0);
end;

procedure TfrmVicios.ExibirInfo(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtInformation, [mbOK], 0);
end;

function TfrmVicios.Confirmar(const AMensagem: string): Boolean;
begin
  Result := MessageDlg(AMensagem, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

// ????????????????????????????????????????????????????????????
// IUViciosView — ciclo de vida
// ????????????????????????????????????????????????????????????

procedure TfrmVicios.MostrarProgresso(const AMensagem: string);
begin
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;
end;

procedure TfrmVicios.OcultarProgresso;
begin
  Screen.Cursor := crDefault;
end;

procedure TfrmVicios.FecharTela;
begin
  Close;
end;

// ????????????????????????????????????????????????????????????
// IUViciosView — consultas
// ????????????????????????????????????????????????????????????

function TfrmVicios.IDEmEdicao: string;
begin
  Result := Trim(edtID.Text);
end;

function TfrmVicios.NomeEmEdicao: string;
begin
  Result := Trim(edtNome.Text);
end;

function TfrmVicios.DescricaoEmEdicao: string;
begin
  Result := Trim(memDescricao.Text);
end;

function TfrmVicios.DicaEmEdicao: string;
begin
  Result := Trim(memDica.Text);
end;

function TfrmVicios.GatilhoEmEdicao: string;
begin
  Result := Trim(edtGatilho.Text);
end;

function TfrmVicios.CrossCenaEmEdicao: Boolean;
begin
  Result := chkCrossCena.Checked;
end;

// ????????????????????????????????????????????????????????????
// IUViciosView — getters/setters dos eventos
// ????????????????????????????????????????????????????????????

function TfrmVicios.GetAoSelecionarVicio: TProcVicioID;
begin
  Result := FAoSelecionarVicio;
end;

procedure TfrmVicios.SetAoSelecionarVicio(const Value: TProcVicioID);
begin
  FAoSelecionarVicio := Value;
end;

function TfrmVicios.GetAoNovoVicio: TProcSimplesVicios;
begin
  Result := FAoNovoVicio;
end;

procedure TfrmVicios.SetAoNovoVicio(const Value: TProcSimplesVicios);
begin
  FAoNovoVicio := Value;
end;

function TfrmVicios.GetAoSalvarVicio: TProcSalvarVicio;
begin
  Result := FAoSalvarVicio;
end;

procedure TfrmVicios.SetAoSalvarVicio(const Value: TProcSalvarVicio);
begin
  FAoSalvarVicio := Value;
end;

function TfrmVicios.GetAoRemoverVicio: TProcVicioID;
begin
  Result := FAoRemoverVicio;
end;

procedure TfrmVicios.SetAoRemoverVicio(const Value: TProcVicioID);
begin
  FAoRemoverVicio := Value;
end;

function TfrmVicios.GetAoFechar: TProcSimplesVicios;
begin
  Result := FAoFechar;
end;

procedure TfrmVicios.SetAoFechar(const Value: TProcSimplesVicios);
begin
  FAoFechar := Value;
end;

// ????????????????????????????????????????????????????????????
// Suporte a interface — sem ref counting (VCL gerencia)
// ????????????????????????????????????????????????????????????

function TfrmVicios.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TfrmVicios._AddRef: Integer;
begin
  Result := -1;
end;

function TfrmVicios._Release: Integer;
begin
  Result := -1;
end;

end.
