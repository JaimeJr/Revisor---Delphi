unit UMarcarRevisadoManualCommand;

{
  UMarcarRevisadoManualCommand.pas
  ─────────────────────────────────────────────────────────────
  Comando reversível que alterna (toggle) entre "pendente" e
  "revisado manualmente".

  Regra de toggle:
    • spPendente       → spRevisadoManual
    • spRevisadoManual → spPendente
    • Qualquer outro   → no-op silencioso (o UseCase já filtra)

  O UseCase é quem decide se cria o comando ou não, com base no
  status atual. O comando, quando executado, assume que o status
  é toggleável — mas defende com no-op se não for.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UIComandoEditorial,
  UManuscrito,
  UValores;

type
  TMarcarRevisadoManualCommand = class(TInterfacedObject, IComandoEditorial)
  private
    FParagrafo: TParagrafo;
    FStatusAnterior: TStatusParagrafo;
    FTrocou: Boolean;
  public
    constructor Create(const AParagrafo: TParagrafo);

    procedure Executar;
    procedure Desfazer;
    function Descricao: string;

    /// <summary>True se o comando realmente alterou o status.</summary>
    function Trocou: Boolean;
  end;

implementation

{ TMarcarRevisadoManualCommand }

constructor TMarcarRevisadoManualCommand.Create(const AParagrafo: TParagrafo);
begin
  inherited Create;
  if not Assigned(AParagrafo) then
    raise EValorInvalido.Create('Parágrafo não pode ser nil.');
  FParagrafo := AParagrafo;
  FTrocou := False;
end;

procedure TMarcarRevisadoManualCommand.Executar;
begin
  FStatusAnterior := FParagrafo.Status;
  FTrocou := False;

  case FParagrafo.Status of
    spPendente:
      begin
        FParagrafo.MarcarRevisadoManual;
        FTrocou := True;
      end;
    spRevisadoManual:
      begin
        FParagrafo.Status := spPendente;
        FTrocou := True;
      end;
    // spAceito, spRecusado, spEditadoManual → no-op
  end;
end;

procedure TMarcarRevisadoManualCommand.Desfazer;
begin
  if FTrocou then
    FParagrafo.Status := FStatusAnterior;
end;

function TMarcarRevisadoManualCommand.Descricao: string;
begin
  Result := Format('Marcar/desmarcar revisado manual: %s',
    [FParagrafo.ID]);
end;

function TMarcarRevisadoManualCommand.Trocou: Boolean;
begin
  Result := FTrocou;
end;

end.
