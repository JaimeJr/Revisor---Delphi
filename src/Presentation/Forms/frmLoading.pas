unit frmLoading;

{
  frmLoading.pas
  ─────────────────────────────────────────────────────────────
  Tela de loading modal.

  Mecânica (importante):
    • A operação NÃO é executada no OnShow diretamente.
      Setar ModalResult no OnShow não fecha o form com
      segurança — o ShowModal ainda está inicializando.
    • Usamos TThread.ForceQueue para agendar a operação na
      fila de mensagens da thread principal. Ela roda depois
      que o ShowModal já entrou no loop, e o ModalResult
      funciona corretamente.
    • Exceção da operação é capturada, guardada como texto,
      e relançada pelo chamador (o Mediador) após o ShowModal
      retornar.

  Por que guardar só o texto:
    • Guardar o objeto Exception exigiria AcquireExceptionObject
      e ReleaseExceptionObject com ref counting manual.
    • O chamador só precisa da mensagem para mostrar ao
      usuário. O tipo específico da exceção não muda a UX.

  Animação:
    • TProgressBar com Style = pbstMarquee — barra
      indeterminada nativa, sem timer manual.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.ExtCtrls;

type
  TfrmLoading = class(TForm)
    pnlClient: TPanel;
    lblMensagem: TLabel;
    barra: TProgressBar;
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FOperacao: TProc;
    FMensagem: string;
    FExecutou: Boolean;
    FMensagemErro: string;
    FClasseErro: string;
  public
    /// <summary>
    ///   Configura a mensagem e a operação. Deve ser chamado
    ///   antes de ShowModal.
    /// </summary>
    procedure Configurar(const AMensagem: string;
      const AOperacao: TProc);

    /// <summary>Mensagem de erro, se a operação falhou. '' se OK.</summary>
    property MensagemErro: string read FMensagemErro;

    /// <summary>Nome da classe da exceção, se falhou.</summary>
    property ClasseErro: string read FClasseErro;
  end;

var
  FormLoading: TfrmLoading;

implementation

{$R *.dfm}

procedure TfrmLoading.Configurar(const AMensagem: string;
  const AOperacao: TProc);
begin
  FMensagem := AMensagem;
  FOperacao := AOperacao;
  FExecutou := False;
  FMensagemErro := '';
  FClasseErro := '';
end;

procedure TfrmLoading.FormShow(Sender: TObject);
begin
  lblMensagem.Caption := FMensagem;

  // Pinta a tela antes de agendar a operação.
  Update;
  Application.ProcessMessages;

  if FExecutou then
    Exit;
  FExecutou := True;

  // Agenda a operação para rodar DEPOIS que o ShowModal
  // entrar no loop de mensagens. Isso resolve o problema
  // de ModalResult setado durante o OnShow não fechar o form.
  TThread.ForceQueue(nil,
    procedure
    begin
      try
        if Assigned(FOperacao) then
          FOperacao();
      except
        on E: Exception do
        begin
          FClasseErro := E.ClassName;
          FMensagemErro := E.Message;
        end;
      end;

      // Fecha o modal (agora sim, dentro do loop).
      ModalResult := mrOk;
    end);
end;

procedure TfrmLoading.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  // Só permite fechar se a operação já executou (evita Alt+F4
  // no meio do trabalho).
  CanClose := FExecutou;
end;

end.
