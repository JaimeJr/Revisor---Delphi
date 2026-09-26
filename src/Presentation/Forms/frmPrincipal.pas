unit frmPrincipal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Graphics,
  UIPrincipalView,
  UTiposUI,
  UValores;

type
  TfrmPrincipal = class;

  TPainelParagrafoUI = class
  public
    ParagrafoID: TID;
    Panel: TPanel;
    CheckBox: TCheckBox;
    LabelID: TLabel;
    LabelTexto: TLabel;
    LabelStatus: TLabel;
    Disparo: TDisparoUI;
    Owner: TfrmPrincipal;
    procedure CheckBoxClick(Sender: TObject);
  end;

  TfrmPrincipal = class(TForm, IPrincipalView)
    pnlTop: TPanel;
    btnImportar: TButton;
    btnExportar: TButton;
    btnVicios: TButton;
    btnRevisar: TButton;
    btnMarcarRevisados: TButton;
    btnDesfazer: TButton;
    btnStatusAPI: TButton;
    lblStatusAPI: TLabel;

    pnlArvore: TPanel;
    treeEstrutura: TTreeView;
    splitterPrincipal: TSplitter;

    pnlConteudo: TPanel;
    lblTituloCena: TLabel;
    pnlCenaTopo: TPanel;
    btnMarcarTodos: TButton;
    btnDesmarcarTodos: TButton;
    scrollParagrafos: TScrollBox;
    pnlRodapeConteudo: TPanel;
    cmbVicio: TComboBox;
    lblContador: TLabel;

    statusBar: TStatusBar;

    dlgAbrirDocx: TOpenDialog;
    dlgSalvarDocx: TSaveDialog;
    btnMarcarSuspeitos: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnImportarClick(Sender: TObject);
    procedure BtnExportarClick(Sender: TObject);
    procedure BtnViciosClick(Sender: TObject);
    procedure BtnRevisarClick(Sender: TObject);
    procedure BtnMarcarRevisadosClick(Sender: TObject);
    procedure BtnDesfazerClick(Sender: TObject);
    procedure BtnStatusAPIClick(Sender: TObject);
    procedure BtnMarcarTodosClick(Sender: TObject);
    procedure BtnDesmarcarTodosClick(Sender: TObject);
    procedure TreeEstruturaChange(Sender: TObject; Node: TTreeNode);
    procedure CmbVicioChange(Sender: TObject);
    procedure ScrollParagrafosResize(Sender: TObject);
    procedure btnMarcarSuspeitosClick(Sender: TObject);
  private
    FCenaAtual: TID;
    FParagrafos: TObjectList<TPainelParagrafoUI>;
    FTopAcumulado: Integer;

    FAoImportar: TProcSimplesPrincipal;
    FAoExportar: TProcSimplesPrincipal;
    FAoAbrirVicios: TProcSimplesPrincipal;
    FAoSelecionarCena: TProcCenaID;
    FAoMarcarParagrafo: TProcParagrafoMarcado;
    FAoSelecionarVicio: TProcSimplesPrincipal;
    FAoRevisar: TProcSimplesPrincipal;
    FAoMarcarRevisados: TProcSimplesPrincipal;
    FAoClicarDesfazer: TProcSimplesPrincipal;
    FAoFechar: TProcSimplesPrincipal;
    FAoMarcarSuspeitos: TProcSimplesPrincipal;

    procedure LimparParagrafos;
    function CorDoStatus(const AStatus: TStatusParagrafo): TColor;
    function TextoDoStatus(const AStatus: TStatusParagrafo): string;
    procedure PreencherArvoreRecursivo(const AParent: TTreeNode;
      const ANos: TArray<TNoArvoreUI>);
    procedure ConstruirParagrafo(const APar: TParagrafoUI);
    procedure ReposicionarPainel(const AWrap: TPainelParagrafoUI);
    procedure ReposicionarTodos;
    procedure OnParagrafoCheckBox(const AParagrafoID: TID;
      const AMarcado: Boolean);
    procedure AtualizarContador;
    procedure AplicarMarcacaoEmTodos(const AMarcado: Boolean);
    procedure DefinirStatusAPI(const AOnline: Boolean;
      const AMotivo: string);
    function MedirAlturaTexto(const ATexto: string; const ALargura: Integer;
      const AFont: TFont): Integer;
    function GetAoMarcarSuspeitos: TProcSimplesPrincipal;
    procedure SetAoMarcarSuspeitos(const Value: TProcSimplesPrincipal);
    procedure AtualizarBotaoSuspeitos;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function CenaSelecionadaID: TID;
    function ParagrafosSelecionadosIDs: TArray<TID>;
    function VicioSelecionado: string;
    function ModoSelecionado: TModoEnvio;

    procedure ExibirArvore(const ARaiz: TArray<TNoArvoreUI>);
    procedure LimparArvore;
    procedure ExibirCena(const ACena: TCenaUI; const ATitulo: string);
    procedure LimparCena;
    procedure PopularComboVicios(const AVicios: TArray<string>);

    procedure AtualizarTitulo(const ATitulo: string);
    procedure AtualizarResumo(const AResumo: TResumoUI);
    procedure AtualizarBarraStatus(const ATexto: string);
    procedure AtualizarCustoAcumulado(const ATexto: string);

    procedure HabilitarImportar(const AHabilitado: Boolean);
    procedure HabilitarRevisar(const AHabilitado: Boolean);
    procedure HabilitarVarredura(const AHabilitado: Boolean);
    procedure HabilitarExportar(const AHabilitado: Boolean);
    procedure HabilitarMarcarRevisados(const AHabilitado: Boolean);
    procedure HabilitarDesfazer(const AHabilitado: Boolean;
      const ADescricao: string);

    function PerguntarCaminhoDocx: string;
    function PerguntarCaminhoSaidaDocx(const ASugestao: string): string;
    procedure ExibirErro(const AMensagem: string);
    procedure ExibirInfo(const AMensagem: string);
    procedure ExibirAviso(const AMensagem: string);
    function Confirmar(const AMensagem: string): Boolean;

    procedure MostrarProgresso(const AMensagem: string);
    procedure OcultarProgresso;
    procedure FecharAplicacao;

    function GetAoImportar: TProcSimplesPrincipal;
    procedure SetAoImportar(const Value: TProcSimplesPrincipal);
    property AoImportar: TProcSimplesPrincipal
      read GetAoImportar write SetAoImportar;

    function GetAoExportar: TProcSimplesPrincipal;
    procedure SetAoExportar(const Value: TProcSimplesPrincipal);
    property AoExportar: TProcSimplesPrincipal
      read GetAoExportar write SetAoExportar;

    function GetAoAbrirVicios: TProcSimplesPrincipal;
    procedure SetAoAbrirVicios(const Value: TProcSimplesPrincipal);
    property AoAbrirVicios: TProcSimplesPrincipal
      read GetAoAbrirVicios write SetAoAbrirVicios;

    function GetAoSelecionarCena: TProcCenaID;
    procedure SetAoSelecionarCena(const Value: TProcCenaID);
    property AoSelecionarCena: TProcCenaID
      read GetAoSelecionarCena write SetAoSelecionarCena;

    function GetAoMarcarParagrafo: TProcParagrafoMarcado;
    procedure SetAoMarcarParagrafo(const Value: TProcParagrafoMarcado);
    property AoMarcarParagrafo: TProcParagrafoMarcado
      read GetAoMarcarParagrafo write SetAoMarcarParagrafo;

    function GetAoSelecionarVicio: TProcSimplesPrincipal;
    procedure SetAoSelecionarVicio(const Value: TProcSimplesPrincipal);
    property AoSelecionarVicio: TProcSimplesPrincipal
      read GetAoSelecionarVicio write SetAoSelecionarVicio;

    function GetAoRevisar: TProcSimplesPrincipal;
    procedure SetAoRevisar(const Value: TProcSimplesPrincipal);
    property AoRevisar: TProcSimplesPrincipal
      read GetAoRevisar write SetAoRevisar;

    function GetAoMarcarRevisados: TProcSimplesPrincipal;
    procedure SetAoMarcarRevisados(const Value: TProcSimplesPrincipal);
    property AoMarcarRevisados: TProcSimplesPrincipal
      read GetAoMarcarRevisados write SetAoMarcarRevisados;

    function GetAoClicarDesfazer: TProcSimplesPrincipal;
    procedure SetAoClicarDesfazer(const Value: TProcSimplesPrincipal);
    property AoClicarDesfazer: TProcSimplesPrincipal
      read GetAoClicarDesfazer write SetAoClicarDesfazer;

    function GetAoFechar: TProcSimplesPrincipal;
    procedure SetAoFechar(const Value: TProcSimplesPrincipal);
    property AoFechar: TProcSimplesPrincipal
      read GetAoFechar write SetAoFechar;

    function TotalSuspeitosNaCena: Integer;
    procedure MarcarSuspeitos;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

var
  FormPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

uses
  System.Net.HttpClient,
  System.Net.URLClient,
  UConfigApp;

const
  COR_PENDENTE        = clWindowText;
  COR_ACEITO          = $00228B22;
  COR_RECUSADO        = clGray;
  COR_REVISADO_MANUAL = $00A06020;
  COR_EDITADO_MANUAL  = $00A05000;

  MARGEM_ESQUERDA = 8;
  MARGEM_DIREITA = 20;   // espaço para a scrollbar vertical
  MARGEM_VERTICAL = 4;
  ALTURA_MINIMA = 32;

{ TPainelParagrafoUI }

procedure TPainelParagrafoUI.CheckBoxClick(Sender: TObject);
begin
  if Assigned(Owner) then
    Owner.OnParagrafoCheckBox(ParagrafoID, CheckBox.Checked);
end;

{ TfrmPrincipal }

constructor TfrmPrincipal.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FParagrafos := TObjectList<TPainelParagrafoUI>.Create;
end;

destructor TfrmPrincipal.Destroy;
begin
  FParagrafos.Free;
  inherited;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FCenaAtual := '';
  FTopAcumulado := 0;
  LimparArvore;
  LimparCena;
  HabilitarRevisar(False);
  HabilitarExportar(False);
  HabilitarMarcarRevisados(False);
  HabilitarDesfazer(False, '');
  cmbVicio.Items.Clear;
  lblContador.Caption := '';

  lblStatusAPI.Caption := '—';
  lblStatusAPI.Font.Color := clGray;
  lblStatusAPI.Hint := 'Clique em "Checar API" para verificar.';
  lblStatusAPI.ShowHint := True;
end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FAoFechar) then
    FAoFechar();
end;

// ────────────────────────────────────────────────────────────
// Handlers
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.BtnImportarClick(Sender: TObject);
begin if Assigned(FAoImportar) then FAoImportar(); end;

procedure TfrmPrincipal.BtnExportarClick(Sender: TObject);
begin if Assigned(FAoExportar) then FAoExportar(); end;

procedure TfrmPrincipal.BtnViciosClick(Sender: TObject);
begin if Assigned(FAoAbrirVicios) then FAoAbrirVicios(); end;

procedure TfrmPrincipal.BtnRevisarClick(Sender: TObject);
begin if Assigned(FAoRevisar) then FAoRevisar(); end;

procedure TfrmPrincipal.BtnMarcarRevisadosClick(Sender: TObject);
begin if Assigned(FAoMarcarRevisados) then FAoMarcarRevisados(); end;

procedure TfrmPrincipal.btnMarcarSuspeitosClick(Sender: TObject);
begin
  if Assigned(FAoMarcarSuspeitos) then
    FAoMarcarSuspeitos();
end;

procedure TfrmPrincipal.BtnDesfazerClick(Sender: TObject);
begin if Assigned(FAoClicarDesfazer) then FAoClicarDesfazer(); end;

procedure TfrmPrincipal.BtnMarcarTodosClick(Sender: TObject);
begin AplicarMarcacaoEmTodos(True); end;

procedure TfrmPrincipal.BtnDesmarcarTodosClick(Sender: TObject);
begin AplicarMarcacaoEmTodos(False); end;

procedure TfrmPrincipal.TreeEstruturaChange(Sender: TObject;
  Node: TTreeNode);
var
  ID: TID;
begin
  if Node = nil then
    Exit;
  if Node.Level <> 2 then
    Exit;

  ID := TID(Node.Data);
  if ID = '' then
    Exit;

  if Assigned(FAoSelecionarCena) then
    FAoSelecionarCena(ID);
end;

procedure TfrmPrincipal.CmbVicioChange(Sender: TObject);
begin
  if Assigned(FAoSelecionarVicio) then
    FAoSelecionarVicio();
end;

procedure TfrmPrincipal.ScrollParagrafosResize(Sender: TObject);
begin
  // Quando a largura do scrollbox muda (redimensionamento da
  // janela), redistribui os painéis.
  ReposicionarTodos;
end;

// ────────────────────────────────────────────────────────────
// Marcação
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.AplicarMarcacaoEmTodos(const AMarcado: Boolean);
var
  Par: TPainelParagrafoUI;
begin
  for Par in FParagrafos do
    Par.CheckBox.Checked := AMarcado;

  AtualizarContador;

  if Assigned(FAoMarcarParagrafo) and (FParagrafos.Count > 0) then
    FAoMarcarParagrafo('', AMarcado);
end;

procedure TfrmPrincipal.OnParagrafoCheckBox(const AParagrafoID: TID;
  const AMarcado: Boolean);
begin
  AtualizarContador;
  if Assigned(FAoMarcarParagrafo) then
    FAoMarcarParagrafo(AParagrafoID, AMarcado);
end;

procedure TfrmPrincipal.AtualizarContador;
var
  Marcados: Integer;
begin
  Marcados := Length(ParagrafosSelecionadosIDs);
  if FParagrafos.Count = 0 then
    lblContador.Caption := ''
  else
    lblContador.Caption := Format('%d de %d marcado(s)',
      [Marcados, FParagrafos.Count]);
end;

// ────────────────────────────────────────────────────────────
// IPrincipalView — consultas
// ────────────────────────────────────────────────────────────

function TfrmPrincipal.CenaSelecionadaID: TID;
begin
  Result := FCenaAtual;
end;

function TfrmPrincipal.ParagrafosSelecionadosIDs: TArray<TID>;
var
  Lista: TList<TID>;
  Par: TPainelParagrafoUI;
begin
  Lista := TList<TID>.Create;
  try
    for Par in FParagrafos do
      if Par.CheckBox.Checked then
        Lista.Add(Par.ParagrafoID);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TfrmPrincipal.VicioSelecionado: string;
begin
  if cmbVicio.ItemIndex < 0 then
    Exit('');
  Result := cmbVicio.Text;
end;

function TfrmPrincipal.ModoSelecionado: TModoEnvio;
begin
  Result := meCirurgico;
end;

// ────────────────────────────────────────────────────────────
// Árvore
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.LimparArvore;
begin
  treeEstrutura.Items.Clear;
  FCenaAtual := '';
end;

procedure TfrmPrincipal.PreencherArvoreRecursivo(const AParent: TTreeNode;
  const ANos: TArray<TNoArvoreUI>);
var
  No: TNoArvoreUI;
  TreeNode: TTreeNode;
begin
  for No in ANos do
  begin
    TreeNode := treeEstrutura.Items.AddChild(AParent, No.Nome);
    TreeNode.Data := Pointer(No.ID);
    PreencherArvoreRecursivo(TreeNode, No.Filhos);
  end;
end;

procedure TfrmPrincipal.ExibirArvore(const ARaiz: TArray<TNoArvoreUI>);
begin
  treeEstrutura.Items.BeginUpdate;
  try
    LimparArvore;
    PreencherArvoreRecursivo(nil, ARaiz);
  finally
    treeEstrutura.Items.EndUpdate;
  end;
  treeEstrutura.FullExpand;
end;

// ────────────────────────────────────────────────────────────
// Cena
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.LimparParagrafos;
begin
  FParagrafos.Clear;
  while scrollParagrafos.ControlCount > 0 do
    scrollParagrafos.Controls[0].Free;

  FTopAcumulado := 0;
  scrollParagrafos.VertScrollBar.Position := 0;
end;

procedure TfrmPrincipal.LimparCena;
begin
  LimparParagrafos;
  FCenaAtual := '';
  lblTituloCena.Caption := '';
  lblContador.Caption := '';

  AtualizarBotaoSuspeitos;
end;

procedure TfrmPrincipal.AtualizarBotaoSuspeitos;
var
  Total: Integer;
begin
  Total := TotalSuspeitosNaCena;
  btnMarcarSuspeitos.Enabled := Total > 0;
  if Total > 0 then
    btnMarcarSuspeitos.Caption := Format('Marcar suspeitos (%d)', [Total])
  else
    btnMarcarSuspeitos.Caption := 'Marcar suspeitos';
end;

function TfrmPrincipal.TotalSuspeitosNaCena: Integer;
var
  Par: TPainelParagrafoUI;
begin
  Result := 0;
  for Par in FParagrafos do
    if Assigned(Par.Disparo) then
      Inc(Result);
end;

procedure TfrmPrincipal.MarcarSuspeitos;
var
  Par: TPainelParagrafoUI;
  Alterou: Boolean;
begin
  Alterou := False;

  for Par in FParagrafos do
    if Assigned(Par. Disparo) and not Par.CheckBox.Checked then
    begin
      Par.CheckBox.Checked := True;
      Alterou := True;
    end;

  if Alterou then
  begin
    AtualizarContador;
    if Assigned(FAoMarcarParagrafo) then
      FAoMarcarParagrafo('', True);  // mesmo padrão do "Marcar todos"
  end;

  AtualizarBotaoSuspeitos;
end;
function TfrmPrincipal.MedirAlturaTexto(const ATexto: string;
  const ALargura: Integer; const AFont: TFont): Integer;
var
  R: TRect;
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(AFont);
    R := Rect(0, 0, ALargura, 0);
    DrawText(Bmp.Canvas.Handle, PChar(ATexto), Length(ATexto), R,
      DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
    Result := R.Height;
  finally
    Bmp.Free;
  end;
end;

procedure TfrmPrincipal.ConstruirParagrafo(const APar: TParagrafoUI);
var
  Pnl: TPanel;
  Chk: TCheckBox;
  LblID: TLabel;
  LblTexto: TLabel;
  LblStatus: TLabel;
  Wrap: TPainelParagrafoUI;
  LarguraTexto, AlturaTexto: Integer;
  CorTexto: TColor;
begin
  Pnl := TPanel.Create(scrollParagrafos);
  Pnl.Parent := scrollParagrafos;
  Pnl.BevelOuter := bvNone;
  Pnl.ShowCaption := False;
  Pnl.Left := MARGEM_ESQUERDA;
  Pnl.Width := scrollParagrafos.ClientWidth - MARGEM_ESQUERDA - MARGEM_DIREITA;
  if Pnl.Width < 200 then
    Pnl.Width := 200;

  // ─── Checkbox ───
  Chk := TCheckBox.Create(Pnl);
  Chk.Parent := Pnl;
  Chk.Left := 0;
  Chk.Top := 2;
  Chk.Width := 24;
  Chk.Height := 20;
  Chk.Caption := '';
  Chk.Checked := False;

  // ─── ID ───
  LblID := TLabel.Create(Pnl);
  LblID.Parent := Pnl;
  LblID.Left := Chk.Left + Chk.Width;
  LblID.Top := 2;
  LblID.Width := 52;
  LblID.Height := 20;
  LblID.Caption := APar.ParagrafoID;
  LblID.Font.Assign(Self.Font);
  LblID.Font.Style := [fsBold];

  // ─── Status à direita ───
  LblStatus := TLabel.Create(Pnl);
  LblStatus.Parent := Pnl;
  LblStatus.Width := 90;
  LblStatus.Height := 20;
  LblStatus.Left := Pnl.Width - LblStatus.Width - 4;
  LblStatus.Top := 2;
  LblStatus.Alignment := taRightJustify;
  LblStatus.Caption := TextoDoStatus(APar.Status);
  LblStatus.Font.Assign(Self.Font);
  LblStatus.Font.Color := CorDoStatus(APar.Status);
  LblStatus.Font.Style := [fsItalic];

  // ─── Texto do parágrafo ───
  LarguraTexto := LblStatus.Left - (LblID.Left + LblID.Width) - 8;
  if LarguraTexto < 100 then
    LarguraTexto := 100;

  AlturaTexto := MedirAlturaTexto(APar.Texto, LarguraTexto, Self.Font);
  if AlturaTexto < 20 then
    AlturaTexto := 20;

  LblTexto := TLabel.Create(Pnl);
  LblTexto.Parent := Pnl;
  LblTexto.Left := LblID.Left + LblID.Width;
  LblTexto.Top := 2;
  LblTexto.Width := LarguraTexto;
  LblTexto.Height := AlturaTexto;
  LblTexto.AutoSize := False;
  LblTexto.Font.Size := 20;
  LblTexto.WordWrap := True;
  lblTexto.Margins.Left := 10;
  LblTexto.Caption := APar.Texto;
  LblTexto.Font.Assign(Self.Font);
  if APar.TemDisparo and (APar.Status <> spAceito) and (APar.Status <> spRevisadoManual) then
    CorTexto := clRed
  else
    CorTexto := CorDoStatus(APar.Status);

  LblTexto.Font.Color := CorTexto;

  // Altura do painel: o maior entre o texto e o status.
  Pnl.Height := AlturaTexto + 8;
  if Pnl.Height < ALTURA_MINIMA then
    Pnl.Height := ALTURA_MINIMA;

  // ─── Wrapper ───
  Wrap := TPainelParagrafoUI.Create;
  Wrap.ParagrafoID := APar.ParagrafoID;
  Wrap.Panel := Pnl;
  Wrap.CheckBox := Chk;
  Wrap.LabelID := LblID;
  Wrap.LabelTexto := LblTexto;
  Wrap.LabelStatus := LblStatus;
  Wrap.Disparo := nil;
  if APar.Disparos.Count > 0 then
    Wrap.Disparo := APar.Disparos[0];
  Wrap.Owner := Self;
  Chk.OnClick := Wrap.CheckBoxClick;

  FParagrafos.Add(Wrap);

  ReposicionarPainel(Wrap);
end;

procedure TfrmPrincipal.ReposicionarPainel(const AWrap: TPainelParagrafoUI);
begin
  AWrap.Panel.Top := FTopAcumulado;
  Inc(FTopAcumulado, AWrap.Panel.Height + MARGEM_VERTICAL);
end;

procedure TfrmPrincipal.ReposicionarTodos;
var
  Par: TPainelParagrafoUI;
  NovaCena: TID;
begin
  // Recalcula Top de todos os painéis quando a largura muda.
  // Também re-mede altura dos labels (a quebra de linha muda).
  NovaCena := FCenaAtual;
  if NovaCena = '' then
    Exit;

  FTopAcumulado := 0;
  for Par in FParagrafos do
  begin
    Par.Panel.Width := scrollParagrafos.ClientWidth
      - MARGEM_ESQUERDA - MARGEM_DIREITA;
    if Par.Panel.Width < 200 then
      Par.Panel.Width := 200;

    Par.LabelStatus.Left := Par.Panel.Width - Par.LabelStatus.Width - 4;

    var LarguraTexto := Par.LabelStatus.Left
      - (Par.LabelID.Left + Par.LabelID.Width) - 8;
    if LarguraTexto < 100 then
      LarguraTexto := 100;

    Par.LabelTexto.Width := LarguraTexto;
    Par.LabelTexto.Height := MedirAlturaTexto(
      Par.LabelTexto.Caption, LarguraTexto, Self.Font);

    Par.Panel.Height := Par.LabelTexto.Height + 8;
    if Par.Panel.Height < ALTURA_MINIMA then
      Par.Panel.Height := ALTURA_MINIMA;

    ReposicionarPainel(Par);
  end;
end;

procedure TfrmPrincipal.ExibirCena(const ACena: TCenaUI;
  const ATitulo: string);
var
  Par: TParagrafoUI;
begin
  scrollParagrafos.DisableAlign;
  try
    LimparParagrafos;

    FCenaAtual := ACena.CenaID;
    lblTituloCena.Caption := ATitulo;

    for Par in ACena.Paragrafos do
      ConstruirParagrafo(Par);
  finally
    scrollParagrafos.EnableAlign;
  end;

  AtualizarContador;
  AtualizarBotaoSuspeitos;
end;

procedure TfrmPrincipal.PopularComboVicios(const AVicios: TArray<string>);
var
  V: string;
begin
  cmbVicio.Items.BeginUpdate;
  try
    cmbVicio.Items.Clear;
    for V in AVicios do
      cmbVicio.Items.Add(V);
    if cmbVicio.Items.Count > 0 then
      cmbVicio.ItemIndex := 0;
  finally
    cmbVicio.Items.EndUpdate;
  end;

  if Assigned(FAoSelecionarVicio) then
    FAoSelecionarVicio();

  AtualizarBotaoSuspeitos;
end;

// ────────────────────────────────────────────────────────────
// Cores e status
// ────────────────────────────────────────────────────────────

function TfrmPrincipal.CorDoStatus(const AStatus: TStatusParagrafo): TColor;
begin
  case AStatus of
    spPendente:       Result := COR_PENDENTE;
    spAceito:         Result := COR_ACEITO;
    spRecusado:       Result := COR_RECUSADO;
    spRevisadoManual: Result := COR_REVISADO_MANUAL;
    spEditadoManual:  Result := COR_EDITADO_MANUAL;
  else
    Result := COR_PENDENTE;
  end;
end;

function TfrmPrincipal.TextoDoStatus(
  const AStatus: TStatusParagrafo): string;
begin
  case AStatus of
    spPendente:       Result := '';
    spAceito:         Result := '✓ aceito';
    spRecusado:       Result := '✗ recusado';
    spRevisadoManual: Result := '⊘ revisado';
    spEditadoManual:  Result := '✎ editado';
  else
    Result := '';
  end;
end;

// ────────────────────────────────────────────────────────────
// Atualizações simples
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.AtualizarTitulo(const ATitulo: string);
begin
  Caption := 'Editor de Manuscrito — ' + ATitulo;
end;

procedure TfrmPrincipal.AtualizarResumo(const AResumo: TResumoUI);
begin
  statusBar.Panels[0].Text := AResumo.TextoFormatado;
end;

procedure TfrmPrincipal.AtualizarBarraStatus(const ATexto: string);
begin
  statusBar.Panels[1].Text := ATexto;
end;

procedure TfrmPrincipal.AtualizarCustoAcumulado(const ATexto: string);
begin
  statusBar.Panels[2].Text := ATexto;
end;

// ────────────────────────────────────────────────────────────
// Habilitar / desabilitar
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.HabilitarImportar(const AHabilitado: Boolean);
begin btnImportar.Enabled := AHabilitado; end;

procedure TfrmPrincipal.HabilitarRevisar(const AHabilitado: Boolean);
begin btnRevisar.Enabled := AHabilitado; end;

procedure TfrmPrincipal.HabilitarVarredura(const AHabilitado: Boolean);
begin end;

procedure TfrmPrincipal.HabilitarExportar(const AHabilitado: Boolean);
begin btnExportar.Enabled := AHabilitado; end;

procedure TfrmPrincipal.HabilitarMarcarRevisados(const AHabilitado: Boolean);
begin btnMarcarRevisados.Enabled := AHabilitado; end;

procedure TfrmPrincipal.HabilitarDesfazer(const AHabilitado: Boolean;
  const ADescricao: string);
begin
  btnDesfazer.Enabled := AHabilitado;
  if ADescricao = '' then
    btnDesfazer.Caption := 'Desfazer'
  else
    btnDesfazer.Caption := 'Desfazer: ' + ADescricao;
end;

// ────────────────────────────────────────────────────────────
// Diálogos
// ────────────────────────────────────────────────────────────

function TfrmPrincipal.PerguntarCaminhoDocx: string;
begin
  if dlgAbrirDocx.Execute(Handle) then
    Result := dlgAbrirDocx.FileName
  else
    Result := '';
end;

function TfrmPrincipal.PerguntarCaminhoSaidaDocx(
  const ASugestao: string): string;
begin
  dlgSalvarDocx.FileName := ASugestao;
  if dlgSalvarDocx.Execute(Handle) then
    Result := dlgSalvarDocx.FileName
  else
    Result := '';
end;

procedure TfrmPrincipal.ExibirErro(const AMensagem: string);
begin MessageDlg(AMensagem, mtError, [mbOK], 0); end;

procedure TfrmPrincipal.ExibirInfo(const AMensagem: string);
begin MessageDlg(AMensagem, mtInformation, [mbOK], 0); end;

procedure TfrmPrincipal.ExibirAviso(const AMensagem: string);
begin MessageDlg(AMensagem, mtWarning, [mbOK], 0); end;

function TfrmPrincipal.Confirmar(const AMensagem: string): Boolean;
begin
  Result := MessageDlg(AMensagem, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

// ────────────────────────────────────────────────────────────
// Ciclo de vida
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.MostrarProgresso(const AMensagem: string);
begin
  Screen.Cursor := crHourGlass;
  statusBar.Panels[1].Text := AMensagem;
  Application.ProcessMessages;
end;

procedure TfrmPrincipal.OcultarProgresso;
begin
  Screen.Cursor := crDefault;
  statusBar.Panels[1].Text := '';
end;

procedure TfrmPrincipal.FecharAplicacao;
begin Close; end;

// ────────────────────────────────────────────────────────────
// Status da API
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.BtnStatusAPIClick(Sender: TObject);
const
  URL_MODELS = 'https://api.deepseek.com/models';
  TIMEOUT_MS = 5000;
var
  Http: THTTPClient;
  Resposta: IHTTPResponse;
begin
  btnStatusAPI.Enabled := False;
  lblStatusAPI.Caption := 'Verificando...';
  lblStatusAPI.Font.Color := clGray;
  lblStatusAPI.Hint := '';
  Application.ProcessMessages;

  Http := THTTPClient.Create;
  try
    Http.ConnectionTimeout := TIMEOUT_MS;
    Http.ResponseTimeout := TIMEOUT_MS;
    Http.CustomHeaders['Authorization'] :=
      'Bearer ' + TConfigApp.Instancia.ApiKey;

    try
      Resposta := Http.Get(URL_MODELS);
      if Resposta.StatusCode = 200 then
        DefinirStatusAPI(True, '')
      else if Resposta.StatusCode = 401 then
        DefinirStatusAPI(False, 'Chave de API inválida (HTTP 401).')
      else if Resposta.StatusCode = 403 then
        DefinirStatusAPI(False, 'Acesso negado (HTTP 403).')
      else if Resposta.StatusCode >= 500 then
        DefinirStatusAPI(False, Format('Erro do servidor (HTTP %d).',
          [Resposta.StatusCode]))
      else
        DefinirStatusAPI(False, Format('Resposta inesperada (HTTP %d).',
          [Resposta.StatusCode]));
    except
      on E: Exception do
        DefinirStatusAPI(False, 'Sem conexão: ' + E.Message);
    end;
  finally
    Http.Free;
    btnStatusAPI.Enabled := True;
  end;
end;

procedure TfrmPrincipal.DefinirStatusAPI(const AOnline: Boolean;
  const AMotivo: string);
begin
  if AOnline then
  begin
    lblStatusAPI.Caption := 'Online';
    lblStatusAPI.Font.Color := $00228B22;
    lblStatusAPI.Hint := 'API DeepSeek respondendo normalmente.';
  end
  else
  begin
    lblStatusAPI.Caption := 'Offline';
    lblStatusAPI.Font.Color := clRed;
    if AMotivo <> '' then
      lblStatusAPI.Hint := AMotivo
    else
      lblStatusAPI.Hint := 'API DeepSeek indisponível.';
  end;
  lblStatusAPI.ShowHint := True;
end;

// ────────────────────────────────────────────────────────────
// Getters / setters dos eventos
// ────────────────────────────────────────────────────────────

function TfrmPrincipal.GetAoImportar: TProcSimplesPrincipal;
begin Result := FAoImportar; end;
procedure TfrmPrincipal.SetAoImportar(const Value: TProcSimplesPrincipal);
begin FAoImportar := Value; end;

function TfrmPrincipal.GetAoExportar: TProcSimplesPrincipal;
begin Result := FAoExportar; end;
procedure TfrmPrincipal.SetAoExportar(const Value: TProcSimplesPrincipal);
begin FAoExportar := Value; end;

function TfrmPrincipal.GetAoAbrirVicios: TProcSimplesPrincipal;
begin Result := FAoAbrirVicios; end;
procedure TfrmPrincipal.SetAoAbrirVicios(const Value: TProcSimplesPrincipal);
begin FAoAbrirVicios := Value; end;

function TfrmPrincipal.GetAoSelecionarCena: TProcCenaID;
begin Result := FAoSelecionarCena; end;
procedure TfrmPrincipal.SetAoSelecionarCena(const Value: TProcCenaID);
begin FAoSelecionarCena := Value; end;

function TfrmPrincipal.GetAoMarcarParagrafo: TProcParagrafoMarcado;
begin Result := FAoMarcarParagrafo; end;
procedure TfrmPrincipal.SetAoMarcarParagrafo(const Value: TProcParagrafoMarcado);
begin FAoMarcarParagrafo := Value; end;

function TfrmPrincipal.GetAoSelecionarVicio: TProcSimplesPrincipal;
begin Result := FAoSelecionarVicio; end;
procedure TfrmPrincipal.SetAoSelecionarVicio(const Value: TProcSimplesPrincipal);
begin FAoSelecionarVicio := Value; end;

function TfrmPrincipal.GetAoRevisar: TProcSimplesPrincipal;
begin Result := FAoRevisar; end;
procedure TfrmPrincipal.SetAoRevisar(const Value: TProcSimplesPrincipal);
begin FAoRevisar := Value; end;

function TfrmPrincipal.GetAoMarcarRevisados: TProcSimplesPrincipal;
begin Result := FAoMarcarRevisados; end;
procedure TfrmPrincipal.SetAoMarcarRevisados(const Value: TProcSimplesPrincipal);
begin FAoMarcarRevisados := Value; end;

function TfrmPrincipal.GetAoClicarDesfazer: TProcSimplesPrincipal;
begin Result := FAoClicarDesfazer; end;
procedure TfrmPrincipal.SetAoClicarDesfazer(const Value: TProcSimplesPrincipal);
begin FAoClicarDesfazer := Value; end;

function TfrmPrincipal.GetAoFechar: TProcSimplesPrincipal;
begin Result := FAoFechar; end;
procedure TfrmPrincipal.SetAoFechar(const Value: TProcSimplesPrincipal);
begin FAoFechar := Value; end;

// ────────────────────────────────────────────────────────────
// Suporte a interface
// ────────────────────────────────────────────────────────────

function TfrmPrincipal.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TfrmPrincipal.GetAoMarcarSuspeitos: TProcSimplesPrincipal;
begin
  Result := FAoMarcarSuspeitos;
end;

procedure TfrmPrincipal.SetAoMarcarSuspeitos(
  const Value: TProcSimplesPrincipal);
begin
  FAoMarcarSuspeitos := Value;
end;

function TfrmPrincipal._AddRef: Integer;
begin Result := -1; end;
function TfrmPrincipal._Release: Integer;
begin Result := -1; end;

end.
