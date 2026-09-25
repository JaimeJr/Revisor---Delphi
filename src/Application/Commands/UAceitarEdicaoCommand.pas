unit UAceitarEdicaoCommand;

{
  UAceitarEdicaoCommand.pas
  ─────────────────────────────────────────────────────────────
  Comando reversível que aceita UMA edição da IA.

  Efeitos:
    1. Paragrafo.Texto := Edicao.Sugerido.
    2. Paragrafo.Status := spAceito.
    3. Adiciona TRevisaoParagrafo em Paragrafo.Revisoes.
    4. Marca Edicao.Aplicada := True.

  Reverter:
    1. Paragrafo.Texto := TextoAnterior (guardado no Executar).
    2. Remove a revisão adicionada.
    3. Status := spPendente (volta ao estado anterior).
    4. Edicao.Aplicada := False.

  Observações:
    • O comando NÃO persiste. Persistência é responsabilidade
      do UseCase que o executa.
    • O comando NÃO alimenta Vicios.JSON. Isso também é do UseCase.
    • Reverter assume que nenhum outro comando foi aplicado depois
      sobre o mesmo parágrafo. Fora isso, a pilha garante ordem.
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
  TAceitarEdicaoCommand = class(TInterfacedObject, IComandoEditorial)
  private
    FParagrafo: TParagrafo;
    FEdicao: TEdicaoSugerida;
    FIDChamada: string;

    // Estado capturado no Executar para permitir Desfazer.
    FTextoAnterior: string;
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

{ TAceitarEdicaoCommand }

constructor TAceitarEdicaoCommand.Create(const AParagrafo: TParagrafo;
  const AEdicao: TEdicaoSugerida; const AIDChamada: string);
begin
  inherited Create;
  if not Assigned(AParagrafo) then
    raise EValorInvalido.Create('Parágrafo não pode ser nil.');
  if not Assigned(AEdicao) then
    raise EValorInvalido.Create('Edição não pode ser nil.');
  if not AEdicao.EhValida then
    raise EValorInvalido.Create(
      'Edição precisa ter parágrafo, vício e texto sugerido.');

  FParagrafo := AParagrafo;
  FEdicao := AEdicao;
  FIDChamada := AIDChamada;
end;

procedure TAceitarEdicaoCommand.Executar;
var
  Rev: TRevisaoParagrafo;
begin
  // Captura o estado anterior (para Desfazer).
  FTextoAnterior := FParagrafo.Texto;
  FStatusAnterior := FParagrafo.Status;

  // Aplica o novo texto.
  FParagrafo.Texto := FEdicao.Sugerido;
  FParagrafo.Hash := FParagrafo.Hash;  // hash do texto original é mantido;
                                       // um recálculo ficaria em outro lugar

  // Registra a revisão.
  Rev := TRevisaoParagrafo.Create;
  Rev.IDChamada := FIDChamada;
  Rev.VicioID := FEdicao.VicioID;
  Rev.HashParagrafoAntes := FParagrafo.Hash;
  Rev.Aceita := True;
  Rev.Timestamp := Now;
  FParagrafo.AdicionarRevisao(Rev);
  FRevisaoAdicionada := Rev;

  // Atualiza status e marca a edição.
  FParagrafo.Status := spAceito;
  FEdicao.Aplicada := True;
end;

procedure TAceitarEdicaoCommand.Desfazer;
var
  Idx: Integer;
begin
  // Remove a revisão adicionada (se ainda estiver lá).
  if Assigned(FRevisaoAdicionada) then
  begin
    Idx := FParagrafo.Revisoes.IndexOf(FRevisaoAdicionada);
    if Idx >= 0 then
      FParagrafo.Revisoes.Delete(Idx);
    FRevisaoAdicionada := nil;
  end;

  // Restaura texto e status.
  FParagrafo.Texto := FTextoAnterior;
  FParagrafo.Status := FStatusAnterior;
  FEdicao.Aplicada := False;
end;

function TAceitarEdicaoCommand.Descricao: string;
begin
  Result := Format('Aceitar edição %s em %s',
    [FEdicao.VicioID, FEdicao.ParagrafoID]);
end;

end.
