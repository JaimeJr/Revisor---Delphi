unit frmRevisao;

{
  frmRevisao.pas
  ─────────────────────────────────────────────────────────────
  Tela de revisão.

  Layout:
    ┌────────────────────────────────────────────────────────┐
    │  Cena 2.1 — Revisão            [status_parse]          │  pnlTop
    ├────────────────────────────────────────────────────────┤
    │  ┌───────────────┬─────────────────────────────────┐   │
    │  │ Lista edições │  Antigo          │  Sugerido    │   │  pnlBody
    │  │ ☑ p03 anafora │  ┌──────────┐    ┌──────────┐   │   │
    │  │ ☑ p04 anafora │  │  memo    │    │  memo    │   │   │
    │  │ ☐ p05 adverb. │  └──────────┘    └──────────┘   │   │
    │  └───────────────┴─────────────────────────────────┘   │
    ├────────────────────────────────────────────────────────┤
    │ [Recusar tudo] [Reenviar]  [Aceitar selec.] [Aceitar tudo] [Bruta] │
    ├────────────────────────────────────────────────────────┤
    │ tokens: N │ custo: $X.XX │ chamada: req-0007          │
    └────────────────────────────────────────────────────────┘

  Implementa IRevisaoView. Não conhece Presenter, UseCase
  nem repositório. Recebe TRevisaoUI como referência (sem
  ownership) e emite eventos.

  Ref counting:
    • TForm não é TInterfacedObject. _AddRef/_Release são
      neutralizados; o ciclo de vida é do VCL.
  ─────────────────────────────────────────────────────────────
}

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
  UIRevisaoView,
  UTiposUI,
  UValores;

type
  TfrmRevisao = class(TForm, IRevisaoView)
    // Topo
    pnlTop: TPanel;
    lblTitulo: TLabel;
    lblStatusParse: TLabel;

    // Corpo
    pnlBody: TPanel;
    pnlLista: TPanel;
    lstEdicoes: TListView;
    splitterLista: TSplitter;
    pnlMemos: TPanel;
    splitterMemos: TSplitter;
    pnlAntigo: TPanel;
    lblAntigo: TLabel;
    memAntigo: TMemo;
    pnlNovo: TPanel;
    lblNovo: TLabel;
    memNovo: TMemo;

    // Rodapé
    pnlBotoes: TPanel;
    btnRecusarTudo: TButton;
    btnReenviar: TButton;
    btnAceitarSelecionadas: TButton;
    btnAceitarTudo: TButton;
    btnExibirRespostaBruta: TButton;

    statusBar: TStatusBar;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnRecusarTudoClick(Sender: TObject);
    procedure BtnReenviarClick(Sender: TObject);
    procedure BtnAceitarSelecionadasClick(Sender: TObject);
    procedure BtnAceitarTudoClick(Sender: TObject);
    procedure BtnExibirRespostaBrutaClick(Sender: TObject);
    procedure LstEdicoesSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure LstEdicoesItemChecked(Sender: TObject; Item: TListItem);
  private
    FChaves: TStringList;        // paralela aos itens de lstEdicoes
    FRevisaoAtual: TRevisaoUI;   // referência, NÃO dona
    FOnClose: TProcNotificacao;
    FAtualizandoLista: Boolean;  // suprime eventos durante mutações

    FAoMarcarEdicao: TProcEdicaoMarcada;
    FAoMarcarParagrafo: TProcParagrafoMarcado;
    FAoSelecionarEdicao: TProcSelecionarEdicao;
    FAoAceitarSelecionadas: TProcSimples;
    FAoAceitarTudo: TProcSimples;
    FAoRecusarTudo: TProcSimples;
    FAoReenviar: TProcSimples;

    function ChaveDoItem(const AItem: TListItem): string;
    function ItemDaChave(const AChave: string): TListItem;
    procedure LimparLista;
    procedure PreencherLista;
    function CorDoStatus(const AStatus: TStatusParse): TColor;
    function TextoDoStatus(const AStatus: TStatusParse): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // ════════════════════════════════════════════════════════
    //  IRevisaoView
    // ════════════════════════════════════════════════════════

    procedure ExibirRevisao(const ARevisao: TRevisaoUI);
    procedure ExibirTextosDoParagrafo(const ATextoAntigo,
      ATextoNovo: string);
    procedure AtualizarEdicaoMarcada(const AChave: string;
      const AMarcada: Boolean);
    procedure ExibirRespostaBruta(const ATexto: string);
    procedure AtualizarTitulo(const ACenaID: TID; const AModo: TModoEnvio);
    procedure AtualizarRodape(const ATokens: Integer; const ACusto: Double);
    procedure AtualizarStatusParse(const AStatus: TStatusParse;
      const AMensagem: string);

    procedure HabilitarAceitarSelecionadas(const AHabilitado: Boolean);
    procedure HabilitarAceitarTudo(const AHabilitado: Boolean);
    procedure HabilitarRecusarTudo(const AHabilitado: Boolean);
    procedure HabilitarReenviar(const AHabilitado: Boolean);
    procedure HabilitarExibirRespostaBruta(const AHabilitado: Boolean);

    procedure ExibirErro(const AMensagem: string);
    procedure ExibirInfo(const AMensagem: string);
    function Confirmar(const AMensagem: string): Boolean;

    procedure MostrarProgresso(const AMensagem: string);
    procedure OcultarProgresso;
    procedure FecharTela;
    procedure SetOnClose(const AOnClose: TProcNotificacao);

    function EdicoesSelecionadas: TArray<string>;

    function GetAoMarcarEdicao: TProcEdicaoMarcada;
    procedure SetAoMarcarEdicao(const Value: TProcEdicaoMarcada);
    property AoMarcarEdicao: TProcEdicaoMarcada
      read GetAoMarcarEdicao write SetAoMarcarEdicao;

    function GetAoMarcarParagrafo: TProcParagrafoMarcado;
    procedure SetAoMarcarParagrafo(const Value: TProcParagrafoMarcado);
    property AoMarcarParagrafo: TProcParagrafoMarcado
      read GetAoMarcarParagrafo write SetAoMarcarParagrafo;

    function GetAoSelecionarEdicao: TProcSelecionarEdicao;
    procedure SetAoSelecionarEdicao(const Value: TProcSelecionarEdicao);
    property AoSelecionarEdicao: TProcSelecionarEdicao
      read GetAoSelecionarEdicao write SetAoSelecionarEdicao;

    function GetAoAceitarSelecionadas: TProcSimples;
    procedure SetAoAceitarSelecionadas(const Value: TProcSimples);
    property AoAceitarSelecionadas: TProcSimples
      read GetAoAceitarSelecionadas write SetAoAceitarSelecionadas;

    function GetAoAceitarTudo: TProcSimples;
    procedure SetAoAceitarTudo(const Value: TProcSimples);
    property AoAceitarTudo: TProcSimples
      read GetAoAceitarTudo write SetAoAceitarTudo;

    function GetAoRecusarTudo: TProcSimples;
    procedure SetAoRecusarTudo(const Value: TProcSimples);
    property AoRecusarTudo: TProcSimples
      read GetAoRecusarTudo write SetAoRecusarTudo;

    function GetAoReenviar: TProcSimples;
    procedure SetAoReenviar(const Value: TProcSimples);
    property AoReenviar: TProcSimples
      read GetAoReenviar write SetAoReenviar;

    // ─── Suporte a interface (sem ref counting) ───
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

var
  FormRevisao: TfrmRevisao;

implementation

{$R *.dfm}

const
  COR_OK          = $00228B22;   // verde
  COR_VAZIO       = $00808080;   // cinza
  COR_FORA_ESCOPO = $0000A5FF;   // laranja
  COR_PARSE_ERROR = clRed;

{ TfrmRevisao }

constructor TfrmRevisao.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChaves := TStringList.Create;
end;

destructor TfrmRevisao.Destroy;
begin
  FChaves.Free;
  inherited;
end;

procedure TfrmRevisao.FormCreate(Sender: TObject);
begin
  FAtualizandoLista := False;
  lblTitulo.Caption := 'Revisão';
  lblStatusParse.Caption := '';
  memAntigo.Clear;
  memNovo.Clear;
  LimparLista;
  HabilitarAceitarSelecionadas(False);
  HabilitarAceitarTudo(False);
  HabilitarRecusarTudo(False);
  HabilitarReenviar(True);
  HabilitarExibirRespostaBruta(False);
end;

procedure TfrmRevisao.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FOnClose) then
    FOnClose();
end;

// ────────────────────────────────────────────────────────────
// Handlers dos botões
// ────────────────────────────────────────────────────────────

procedure TfrmRevisao.BtnRecusarTudoClick(Sender: TObject);
begin
  if Assigned(FAoRecusarTudo) then
    FAoRecusarTudo();
end;

procedure TfrmRevisao.BtnReenviarClick(Sender: TObject);
begin
  if Assigned(FAoReenviar) then
    FAoReenviar();
end;

procedure TfrmRevisao.BtnAceitarSelecionadasClick(Sender: TObject);
begin
  if Assigned(FAoAceitarSelecionadas) then
    FAoAceitarSelecionadas();
end;

procedure TfrmRevisao.BtnAceitarTudoClick(Sender: TObject);
begin
  if Assigned(FAoAceitarTudo) then
    FAoAceitarTudo();
end;

procedure TfrmRevisao.BtnExibirRespostaBrutaClick(Sender: TObject);
begin
  if Assigned(FRevisaoAtual) then
    ExibirRespostaBruta(FRevisaoAtual.RespostaBruta);
end;

// ────────────────────────────────────────────────────────────
// Handlers da lista
// ────────────────────────────────────────────────────────────

procedure TfrmRevisao.LstEdicoesSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  if FAtualizandoLista then
    Exit;
  if not Selected or (Item = nil) then
    Exit;
  if not Assigned(FAoSelecionarEdicao) then
    Exit;

  FAoSelecionarEdicao(ChaveDoItem(Item));
end;

procedure TfrmRevisao.LstEdicoesItemChecked(Sender: TObject;
  Item: TListItem);
begin
  if FAtualizandoLista then
    Exit;
  if Item = nil then
    Exit;
  if not Assigned(FAoMarcarEdicao) then
    Exit;

  FAoMarcarEdicao(ChaveDoItem(Item), Item.Checked);
end;

// ────────────────────────────────────────────────────────────
// Auxiliares internos
// ────────────────────────────────────────────────────────────

function TfrmRevisao.ChaveDoItem(const AItem: TListItem): string;
begin
  if (AItem = nil) or (AItem.Index < 0) or
     (AItem.Index >= FChaves.Count) then
    Exit('');
  Result := FChaves[AItem.Index];
end;

function TfrmRevisao.ItemDaChave(const AChave: string): TListItem;
var
  I: Integer;
begin
  I := FChaves.IndexOf(AChave);
  if (I < 0) or (I >= lstEdicoes.Items.Count) then
    Exit(nil);
  Result := lstEdicoes.Items[I];
end;

procedure TfrmRevisao.LimparLista;
begin
  FAtualizandoLista := True;
  try
    lstEdicoes.Items.BeginUpdate;
    try
      lstEdicoes.Items.Clear;
      FChaves.Clear;
    finally
      lstEdicoes.Items.EndUpdate;
    end;
  finally
    FAtualizandoLista := False;
  end;
end;

procedure TfrmRevisao.PreencherLista;
var
  Ed: TEdicaoUI;
  Item: TListItem;
begin
  if not Assigned(FRevisaoAtual) then
    Exit;

  FAtualizandoLista := True;
  try
    lstEdicoes.Items.BeginUpdate;
    try
      lstEdicoes.Items.Clear;
      FChaves.Clear;

      for Ed in FRevisaoAtual.Edicoes do
      begin
        Item := lstEdicoes.Items.Add;
        Item.Caption := Ed.ParagrafoID;
        Item.SubItems.Add(Ed.VicioID);
        Item.SubItems.Add(Ed.Motivo);
        Item.Checked := Ed.Selecionada;

        if not Ed.DentroEscopo then
        begin
          // Marca visual: edição fora do escopo não pode ser
          // marcada. Não bloqueamos o checkbox no VCL (não é
          // trivial), mas o Presenter rejeita a marcação.
          Item.SubItems.Add('(fora do escopo)');
        end;

        FChaves.Add(Ed.Chave);
      end;
    finally
      lstEdicoes.Items.EndUpdate;
    end;
  finally
    FAtualizandoLista := False;
  end;
end;

function TfrmRevisao.CorDoStatus(const AStatus: TStatusParse): TColor;
begin
  case AStatus of
    spOK:         Result := COR_OK;
    spVazio:      Result := COR_VAZIO;
    spForaEscopo: Result := COR_FORA_ESCOPO;
    spParseError: Result := COR_PARSE_ERROR;
  else
    Result := clWindowText;
  end;
end;

function TfrmRevisao.TextoDoStatus(const AStatus: TStatusParse): string;
begin
  case AStatus of
    spOK:         Result := 'Resposta válida';
    spVazio:      Result := 'Nenhum vício encontrado';
    spForaEscopo: Result := 'Edições fora do escopo';
    spParseError: Result := 'Falha ao interpretar resposta';
  else
    Result := '';
  end;
end;

// ────────────────────────────────────────────────────────────
// IRevisaoView — renderização
// ────────────────────────────────────────────────────────────

procedure TfrmRevisao.ExibirRevisao(const ARevisao: TRevisaoUI);
begin
  FRevisaoAtual := ARevisao;  // referência; ownership do chamador

  if ARevisao = nil then
  begin
    LimparLista;
    memAntigo.Clear;
    memNovo.Clear;
    Exit;
  end;

  PreencherLista;
  AtualizarStatusParse(ARevisao.StatusParse, ARevisao.VicioGeral);
  AtualizarRodape(ARevisao.TokensPrompt + ARevisao.TokensResposta,
    ARevisao.CustoEstimado);
  statusBar.Panels[2].Text := 'Chamada: ' + ARevisao.IDChamada;

  HabilitarAceitarTudo(ARevisao.TotalAplicaveis > 0);
  HabilitarRecusarTudo(ARevisao.Edicoes.Count > 0);
  HabilitarAceitarSelecionadas(False);  // nada marcado ainda
end;

procedure TfrmRevisao.ExibirTextosDoParagrafo(const ATextoAntigo,
  ATextoNovo: string);
begin
  memAntigo.Text := ATextoAntigo;
  memNovo.Text := ATextoNovo;
end;

procedure TfrmRevisao.AtualizarEdicaoMarcada(const AChave: string;
  const AMarcada: Boolean);
var
  Item: TListItem;
begin
  Item := ItemDaChave(AChave);
  if Item = nil then
    Exit;

  FAtualizandoLista := True;
  try
    Item.Checked := AMarcada;
  finally
    FAtualizandoLista := False;
  end;
end;

procedure TfrmRevisao.ExibirRespostaBruta(const ATexto: string);
begin
  if ATexto.Trim = '' then
    ExibirInfo('(resposta bruta vazia)')
  else
    ShowMessage(ATexto);
end;

procedure TfrmRevisao.AtualizarTitulo(const ACenaID: TID;
  const AModo: TModoEnvio);
var
  ModoTexto: string;
begin
  case AModo of
    meCirurgico: ModoTexto := 'cirúrgico';
    meVarredura: ModoTexto := 'varredura';
  else
    ModoTexto := '?';
  end;

  lblTitulo.Caption := Format('Revisão — %s (modo %s)',
    [ACenaID, ModoTexto]);
end;

procedure TfrmRevisao.AtualizarRodape(const ATokens: Integer;
  const ACusto: Double);
begin
  statusBar.Panels[0].Text := Format('Tokens: %d', [ATokens]);
  statusBar.Panels[1].Text := Format('Custo: $%.4f', [ACusto]);
end;

procedure TfrmRevisao.AtualizarStatusParse(const AStatus: TStatusParse;
  const AMensagem: string);
var
  Texto: string;
begin
  Texto := TextoDoStatus(AStatus);
  if AMensagem.Trim <> '' then
    Texto := Texto + ' — ' + AMensagem;

  lblStatusParse.Caption := Texto;
  lblStatusParse.Font.Color := CorDoStatus(AStatus);
end;

// ────────────────────────────────────────────────────────────
// IRevisaoView — habilitar / desabilitar
// ────────────────────────────────────────────────────────────

procedure TfrmRevisao.HabilitarAceitarSelecionadas(
  const AHabilitado: Boolean);
begin
  btnAceitarSelecionadas.Enabled := AHabilitado;
end;

procedure TfrmRevisao.HabilitarAceitarTudo(const AHabilitado: Boolean);
begin
  btnAceitarTudo.Enabled := AHabilitado;
end;

procedure TfrmRevisao.HabilitarRecusarTudo(const AHabilitado: Boolean);
begin
  btnRecusarTudo.Enabled := AHabilitado;
end;

procedure TfrmRevisao.HabilitarReenviar(const AHabilitado: Boolean);
begin
  btnReenviar.Enabled := AHabilitado;
end;

procedure TfrmRevisao.HabilitarExibirRespostaBruta(
  const AHabilitado: Boolean);
begin
  btnExibirRespostaBruta.Visible := AHabilitado;
end;

// ────────────────────────────────────────────────────────────
// IRevisaoView — diálogos
// ────────────────────────────────────────────────────────────

procedure TfrmRevisao.ExibirErro(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtError, [mbOK], 0);
end;

procedure TfrmRevisao.ExibirInfo(const AMensagem: string);
begin
  MessageDlg(AMensagem, mtInformation, [mbOK], 0);
end;

function TfrmRevisao.Confirmar(const AMensagem: string): Boolean;
begin
  Result := MessageDlg(AMensagem, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

// ────────────────────────────────────────────────────────────
// IRevisaoView — ciclo de vida
// ────────────────────────────────────────────────────────────

procedure TfrmRevisao.MostrarProgresso(const AMensagem: string);
begin
  Screen.Cursor := crHourGlass;
  statusBar.Panels[2].Text := AMensagem;
  Application.ProcessMessages;
end;

procedure TfrmRevisao.OcultarProgresso;
begin
  Screen.Cursor := crDefault;
end;

procedure TfrmRevisao.FecharTela;
begin
  Close;
end;

procedure TfrmRevisao.SetOnClose(const AOnClose: TProcNotificacao);
begin
  FOnClose := AOnClose;
end;

// ────────────────────────────────────────────────────────────
// IRevisaoView — consultas
// ────────────────────────────────────────────────────────────

function TfrmRevisao.EdicoesSelecionadas: TArray<string>;
var
  Lista: TList<string>;
  I: Integer;
begin
  Lista := TList<string>.Create;
  try
    for I := 0 to lstEdicoes.Items.Count - 1 do
      if lstEdicoes.Items[I].Checked and (I < FChaves.Count) then
        Lista.Add(FChaves[I]);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

// ────────────────────────────────────────────────────────────
// IRevisaoView — getters/setters dos eventos
// ────────────────────────────────────────────────────────────

function TfrmRevisao.GetAoMarcarEdicao: TProcEdicaoMarcada;
begin
  Result := FAoMarcarEdicao;
end;

procedure TfrmRevisao.SetAoMarcarEdicao(const Value: TProcEdicaoMarcada);
begin
  FAoMarcarEdicao := Value;
end;

function TfrmRevisao.GetAoMarcarParagrafo: TProcParagrafoMarcado;
begin
  Result := FAoMarcarParagrafo;
end;

procedure TfrmRevisao.SetAoMarcarParagrafo(
  const Value: TProcParagrafoMarcado);
begin
  FAoMarcarParagrafo := Value;
end;

function TfrmRevisao.GetAoSelecionarEdicao: TProcSelecionarEdicao;
begin
  Result := FAoSelecionarEdicao;
end;

procedure TfrmRevisao.SetAoSelecionarEdicao(
  const Value: TProcSelecionarEdicao);
begin
  FAoSelecionarEdicao := Value;
end;

function TfrmRevisao.GetAoAceitarSelecionadas: TProcSimples;
begin
  Result := FAoAceitarSelecionadas;
end;

procedure TfrmRevisao.SetAoAceitarSelecionadas(const Value: TProcSimples);
begin
  FAoAceitarSelecionadas := Value;
end;

function TfrmRevisao.GetAoAceitarTudo: TProcSimples;
begin
  Result := FAoAceitarTudo;
end;

procedure TfrmRevisao.SetAoAceitarTudo(const Value: TProcSimples);
begin
  FAoAceitarTudo := Value;
end;

function TfrmRevisao.GetAoRecusarTudo: TProcSimples;
begin
  Result := FAoRecusarTudo;
end;

procedure TfrmRevisao.SetAoRecusarTudo(const Value: TProcSimples);
begin
  FAoRecusarTudo := Value;
end;

function TfrmRevisao.GetAoReenviar: TProcSimples;
begin
  Result := FAoReenviar;
end;

procedure TfrmRevisao.SetAoReenviar(const Value: TProcSimples);
begin
  FAoReenviar := Value;
end;

// ────────────────────────────────────────────────────────────
// Suporte a interface — sem ref counting (VCL gerencia)
// ────────────────────────────────────────────────────────────

function TfrmRevisao.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TfrmRevisao._AddRef: Integer;
begin
  Result := -1;
end;

function TfrmRevisao._Release: Integer;
begin
  Result := -1;
end;

end.
