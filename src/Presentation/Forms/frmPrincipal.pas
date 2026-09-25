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
  TfrmPrincipal = class(TForm, IPrincipalView)
    // Toolbar
    pnlTop: TPanel;
    btnImportar: TButton;
    btnExportar: TButton;
    btnVicios: TButton;
    btnRevisar: TButton;
    btnMarcarRevisados: TButton;
    btnDesfazer: TButton;
    btnStatusAPI: TButton;
    lblStatusAPI: TLabel;

    // Área esquerda
    pnlArvore: TPanel;
    treeEstrutura: TTreeView;
    splitterPrincipal: TSplitter;

    // Área direita
    pnlConteudo: TPanel;
    lblTituloCapitulo: TLabel;
    scrollCenas: TScrollBox;
    pnlRodapeConteudo: TPanel;
    cmbVicio: TComboBox;
    lblContador: TLabel;

    // Status bar
    statusBar: TStatusBar;

    // Diálogos
    dlgAbrirDocx: TOpenDialog;
    dlgSalvarDocx: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnImportarClick(Sender: TObject);
    procedure BtnExportarClick(Sender: TObject);
    procedure BtnViciosClick(Sender: TObject);
    procedure BtnRevisarClick(Sender: TObject);
    procedure BtnMarcarRevisadosClick(Sender: TObject);
    procedure BtnDesfazerClick(Sender: TObject);
    procedure BtnStatusAPIClick(Sender: TObject);
    procedure TreeEstruturaChange(Sender: TObject; Node: TTreeNode);
    procedure CmbVicioChange(Sender: TObject);
  private
    FCenaSelecionada: TID;

    FAoImportar: TProcSimplesPrincipal;
    FAoExportar: TProcSimplesPrincipal;
    FAoAbrirVicios: TProcSimplesPrincipal;
    FAoSelecionarCena: TProcCenaID;
    FAoSelecionarVicio: TProcSimplesPrincipal;
    FAoRevisar: TProcSimplesPrincipal;
    FAoMarcarRevisados: TProcSimplesPrincipal;
    FAoClicarDesfazer: TProcSimplesPrincipal;
    FAoFechar: TProcSimplesPrincipal;

    procedure LimparPainelCapitulo;
    procedure PreencherArvoreRecursivo(const AParent: TTreeNode;
      const ANos: TArray<TNoArvoreUI>);
    procedure DefinirStatusAPI(const AOnline: Boolean;
      const AMotivo: string);
    procedure AtualizarContador;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // ════════════════════════════════════════════════════════
    //  IPrincipalView — consultas
    // ════════════════════════════════════════════════════════

    function CenaSelecionadaID: TID;
    function VicioSelecionado: string;
    function ModoSelecionado: TModoEnvio;

    // ════════════════════════════════════════════════════════
    //  IPrincipalView — renderização
    // ════════════════════════════════════════════════════════

    procedure ExibirArvore(const ARaiz: TArray<TNoArvoreUI>);
    procedure LimparArvore;
    procedure ExibirCapitulo(const ACapitulo: TCapituloUI);
    procedure LimparCapitulo;

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

    // ════════════════════════════════════════════════════════
    //  IPrincipalView — diálogos e ciclo de vida
    // ════════════════════════════════════════════════════════

    function PerguntarCaminhoDocx: string;
    function PerguntarCaminhoSaidaDocx(const ASugestao: string): string;
    procedure ExibirErro(const AMensagem: string);
    procedure ExibirInfo(const AMensagem: string);
    procedure ExibirAviso(const AMensagem: string);
    function Confirmar(const AMensagem: string): Boolean;

    procedure MostrarProgresso(const AMensagem: string);
    procedure OcultarProgresso;
    procedure FecharAplicacao;

    // ════════════════════════════════════════════════════════
    //  IPrincipalView — eventos
    // ════════════════════════════════════════════════════════

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

    // ─── Suporte a interface (sem ref counting) ───
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
  ALTURA_CABECALHO_CENA = 26;
  ALTURA_MEMO_CENA = 180;

{ TfrmPrincipal }

constructor TfrmPrincipal.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TfrmPrincipal.Destroy;
begin
  inherited;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FCenaSelecionada := '';
  LimparArvore;
  LimparCapitulo;
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
// Handlers dos botões
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.BtnImportarClick(Sender: TObject);
begin
  if Assigned(FAoImportar) then
    FAoImportar();
end;

procedure TfrmPrincipal.BtnExportarClick(Sender: TObject);
begin
  if Assigned(FAoExportar) then
    FAoExportar();
end;

procedure TfrmPrincipal.BtnViciosClick(Sender: TObject);
begin
  if Assigned(FAoAbrirVicios) then
    FAoAbrirVicios();
end;

procedure TfrmPrincipal.BtnRevisarClick(Sender: TObject);
begin
  if Assigned(FAoRevisar) then
    FAoRevisar();
end;

procedure TfrmPrincipal.BtnMarcarRevisadosClick(Sender: TObject);
begin
  if Assigned(FAoMarcarRevisados) then
    FAoMarcarRevisados();
end;

procedure TfrmPrincipal.BtnDesfazerClick(Sender: TObject);
begin
  if Assigned(FAoClicarDesfazer) then
    FAoClicarDesfazer();
end;

procedure TfrmPrincipal.TreeEstruturaChange(Sender: TObject;
  Node: TTreeNode);
var
  ID: TID;
begin
  if Node = nil then
    Exit;

  ID := TID(Node.Data);
  if ID = '' then
    Exit;
  if Node.Level = 0 then
    Exit;  // Ato é só agrupador visual

  if Assigned(FAoSelecionarCena) then
    FAoSelecionarCena(ID);
end;

procedure TfrmPrincipal.CmbVicioChange(Sender: TObject);
begin
  if Assigned(FAoSelecionarVicio) then
    FAoSelecionarVicio();
end;

// ────────────────────────────────────────────────────────────
// IPrincipalView — consultas
// ────────────────────────────────────────────────────────────

function TfrmPrincipal.CenaSelecionadaID: TID;
begin
  Result := FCenaSelecionada;
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
// IPrincipalView — árvore
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.LimparArvore;
begin
  treeEstrutura.Items.Clear;
  FCenaSelecionada := '';
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
// IPrincipalView — capítulo
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.LimparPainelCapitulo;
begin
  // Painéis e memos são filhos de scrollCenas. Liberar o pai
  // libera todos em cascata.
  while scrollCenas.ControlCount > 0 do
    scrollCenas.Controls[0].Free;
end;

procedure TfrmPrincipal.LimparCapitulo;
begin
  LimparPainelCapitulo;
  lblTituloCapitulo.Caption := '';
  lblContador.Caption := '';
end;

procedure TfrmPrincipal.ExibirCapitulo(const ACapitulo: TCapituloUI);
var
  Cena: TCenaUI;
  Par: TParagrafoUI;
  PnlCena: TPanel;
  LblCena: TLabel;
  Mem: TMemo;
  SB: TStringBuilder;
begin
  scrollCenas.DisableAlign;
  try
    LimparPainelCapitulo;

    lblTituloCapitulo.Caption :=
      Format('CAPÍTULO %d — %s', [ACapitulo.Numero, ACapitulo.Titulo]);

    for Cena in ACapitulo.Cenas do
    begin
      // ─── Painel da cena ───
      PnlCena := TPanel.Create(scrollCenas);
      PnlCena.Parent := scrollCenas;
      PnlCena.Align := alTop;
      PnlCena.BevelOuter := bvNone;
      PnlCena.ShowCaption := False;
      PnlCena.AlignWithMargins := True;
      PnlCena.Margins.Top := 8;
      PnlCena.Margins.Bottom := 4;
      PnlCena.Margins.Left := 8;
      PnlCena.Margins.Right := 8;
      PnlCena.Height := ALTURA_CABECALHO_CENA + ALTURA_MEMO_CENA;

      // ─── Cabeçalho ───
      LblCena := TLabel.Create(PnlCena);
      LblCena.Parent := PnlCena;
      LblCena.Align := alTop;
      LblCena.Height := ALTURA_CABECALHO_CENA;
      LblCena.Caption := Format('  Cena %d.%d',
        [ACapitulo.Numero, Cena.Numero]);
      LblCena.Font.Style := [fsBold];
      LblCena.Font.Size := 11;
      LblCena.Layout := tlCenter;

      // ─── Texto da cena (todos os parágrafos) ───
      SB := TStringBuilder.Create;
      try
        for Par in Cena.Paragrafos do
        begin
          if SB.Length > 0 then
            SB.AppendLine;  // linha em branco entre parágrafos
          SB.Append(Par.Texto);
          SB.AppendLine;
        end;

        Mem := TMemo.Create(PnlCena);
        Mem.Parent := PnlCena;
        Mem.Align := alClient;
        Mem.ReadOnly := True;
        Mem.BorderStyle := bsNone;
        Mem.ScrollBars := ssVertical;
        Mem.WordWrap := True;
        Mem.Font.Name := 'Segoe UI';
        Mem.Font.Size := 11;
        Mem.Text := SB.ToString;
        Mem.Color := clWindow;
      finally
        SB.Free;
      end;
    end;
  finally
    scrollCenas.EnableAlign;
  end;

  AtualizarContador;
end;

procedure TfrmPrincipal.AtualizarContador;
begin
  if FCenaSelecionada = '' then
    lblContador.Caption := ''
  else
    lblContador.Caption := 'Cena selecionada: ' + FCenaSelecionada;
end;

// ────────────────────────────────────────────────────────────
// IPrincipalView — atualizações simples
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
// IPrincipalView — habilitar / desabilitar
// ────────────────────────────────────────────────────────────

procedure TfrmPrincipal.HabilitarImportar(const AHabilitado: Boolean);
begin
  btnImportar.Enabled := AHabilitado;
end;

procedure TfrmPrincipal.HabilitarRevisar(const AHabilitado: Boolean);
begin
  btnRevisar.Enabled := AHabilitado;
end;

procedure TfrmPrincipal.HabilitarVarredura(const AHabilitado: Boolean);
begin
  // v2
end;

procedure TfrmPrincipal.HabilitarExportar(const AHabilitado: Boolean);
begin
  btnExportar.Enabled := AHabilitado;
end;

procedure TfrmPrincipal.HabilitarMarcarRevisados(const AHabilitado: Boolean);
begin
  btnMarcarRevisados.Enabled := AHabilitado;
end;

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
// IPrincipalView — diálogos e ciclo de vida
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
begin
  MessageDlg(AMensagem, mtError, [mbOK], 0);
end;

procedure TfrmPrincipal.ExibirInfo(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtInformation, [mbOK], 0);
end;

procedure TfrmPrincipal.ExibirAviso(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtWarning, [mbOK], 0);
end;

function TfrmPrincipal.Confirmar(const AMensagem: string): Boolean;
begin
  Result := MessageDlg(AMensagem, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

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
begin
  Close;
end;

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

function TfrmPrincipal._AddRef: Integer;
begin Result := -1; end;
function TfrmPrincipal._Release: Integer;
begin Result := -1; end;

end.
