unit frmReenvio;

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
  Vcl.ExtCtrls;

type
  TfrmReenvio = class(TForm)
    pnlTop: TPanel;
    lblInstrucao: TLabel;
    pnlBotoes: TPanel;
    btnCancelar: TButton;
    btnReenviar: TButton;
    memObservacao: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BtnCancelarClick(Sender: TObject);
    procedure BtnReenviarClick(Sender: TObject);
  private
    FObservacao: string;
  public
    property Observacao: string read FObservacao;
  end;

implementation

{$R *.dfm}

procedure TfrmReenvio.FormCreate(Sender: TObject);
begin
  FObservacao := '';
  memObservacao.Clear;
  memObservacao.SetFocus;
end;

procedure TfrmReenvio.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Esc cancela.
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Exit;
  end;

  // Ctrl+Enter confirma.
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    BtnReenviarClick(nil);
    Key := 0;
  end;
end;

procedure TfrmReenvio.BtnCancelarClick(Sender: TObject);
begin
  FObservacao := '';
  ModalResult := mrCancel;
end;

procedure TfrmReenvio.BtnReenviarClick(Sender: TObject);
begin
  FObservacao := Trim(memObservacao.Text);
  if FObservacao = '' then
  begin
    MessageDlg('Digite uma observação antes de reenviar.',
      mtWarning, [mbOK], 0);
    memObservacao.SetFocus;
    Exit;
  end;
  ModalResult := mrOk;
end;

end.
