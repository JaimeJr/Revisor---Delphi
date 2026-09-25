unit URecusarEdicaoCommand;

{
  URecusarEdicaoCommand.pas
  ─────────────────────────────────────────────────────────────
  Comando reversível que registra a recusa de uma edição.

  Efeitos:
    1. Paragrafo.Status := spRecusado (só se estava pendente).
    2. Adiciona TRevisaoParagrafo com Aceita := False.
    3. NÃO altera Paragrafo.Texto.
    4. NÃO alimenta Vicios.JSON (recusa não vira exemplo).

  Reverter:
    1. Remove a revisão adicionada.
    2. Restaura o status anterior.

  Por que registrar a recusa:
    • Auditoria: saber que uma edição foi proposta e rejeitada.
    • Evitar que o reenvio proponha exatamente a mesma coisa
      (futuro: cruzar com Envio.JSON).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UIComandoEditorial,
  UManuscrito,
  UEdicaoSugerida,
  UValores;

type
  TRecusarEdicaoCommand = class(TInterfacedObject, IComandoEditorial)
  private
    FParagrafo: TParagrafo;
    FEdicao: TEdicaoSugerida;
    FIDChamada: string;

    FStatusAnterior: TStatusParagrafo;
    FRevisaoAdicionada: TRevisaoParagrafo;
  public
    constructor Create(const AParagrafo: TParagrafo;
      const AEdicao: TEdicaoSugerida; const AIDChamada: string);

    procedure Executar;
    procedure Desfazer;
    function Descricao: string;
  end;

implementation

{ TRecusarEdicaoCommand }

constructor TRecusarEdicaoCommand.Create(const AParagrafo: TParagrafo;
  const AEdicao: TEdicaoSugerida; const AIDChamada: string);
begin
  inherited Create;

  if not Assigned(AParagrafo) then
    raise EValorInvalido.Create('Parágrafo não pode ser nil.');
  if not Assigned(AEdicao) then
    raise EValorInvalido.Create('Edição não pode ser nil.');
  if AEdicao.VicioID = '' then
    raise EValorInvalido.Create('Edição precisa ter VicioID.');

  FParagrafo := AParagrafo;
  FEdicao := AEdicao;
  FIDChamada := AIDChamada;
end;

procedure TRecusarEdicaoCommand.Executar;
var
  Rev: TRevisaoParagrafo;
begin
  FStatusAnterior := FParagrafo.Status;

  Rev := TRevisaoParagrafo.Create;
  Rev.IDChamada := FIDChamada;
  Rev.VicioID := FEdicao.VicioID;
  Rev.HashParagrafoAntes := FParagrafo.Hash;
  Rev.Aceita := False;
  Rev.Timestamp := Now;
  FParagrafo.AdicionarRevisao(Rev);
  FRevisaoAdicionada := Rev;

  // Só muda o status se o parágrafo ainda estava intocado.
  // Se já tinha sido aceito antes, mantém spAceito — a recusa
  // é sobre uma edição específica, não sobre o parágrafo.
  if FParagrafo.Status = spPendente then
    FParagrafo.Status := spRecusado;
end;

procedure TRecusarEdicaoCommand.Desfazer;
var
  Idx: Integer;
begin
  if Assigned(FRevisaoAdicionada) then
  begin
    Idx := FParagrafo.Revisoes.IndexOf(FRevisaoAdicionada);
    if Idx >= 0 then
      FParagrafo.Revisoes.Delete(Idx);
    FRevisaoAdicionada := nil;
  end;

  FParagrafo.Status := FStatusAnterior;
end;

function TRecusarEdicaoCommand.Descricao: string;
begin
  Result := Format('Recusar edição %s em %s',
    [FEdicao.VicioID, FEdicao.ParagrafoID]);
end;

end.
