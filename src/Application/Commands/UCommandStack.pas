unit UCommandStack;

{
  UCommandStack.pas
  ─────────────────────────────────────────────────────────────
  Pilha de comandos editoriais com undo ilimitado.

  Comportamento:
    • Executar(cmd) chama cmd.Executar e empilha.
    • DesfazerUltimo chama cmd.Desfazer e desempilha.
    • Redo não é suportado na v1 — se o usuário desfizer e depois
      quiser refazer, precisa refazer a ação (aceitar de novo,
      comando novo).
    • Limpar descarta toda a pilha sem desfazer (uso típico:
      trocar de manuscrito).

  Ownership:
    • A pilha NÃO é dona dos comandos. Quem cria é quem libera.
    • Isso permite ao chamador manter referência ao comando
      depois de empilhar, se precisar.
    • O IComandoEditorial é gerenciado por interface (referência
      contada). Adicionar a uma TList mantém a referência viva.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UIComandoEditorial,
  UValores;

type
  TCommandStack = class
  private
    FComandos: TList<IComandoEditorial>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Executa e empilha um comando.</summary>
    procedure Executar(const AComando: IComandoEditorial);

    /// <summary>
    ///   Desfaz o último comando. Retorna False se a pilha
    ///   estava vazia.
    /// </summary>
    function DesfazerUltimo: Boolean;

    /// <summary>True se há algo para desfazer.</summary>
    function PodeDesfazer: Boolean;

    /// <summary>Descrição do último comando, ou '' se vazia.</summary>
    function DescricaoUltimo: string;

    /// <summary>Limpa a pilha sem desfazer nada.</summary>
    procedure Limpar;

    /// <summary>Total de comandos empilhados.</summary>
    function Total: Integer;
  end;

implementation

{ TCommandStack }

constructor TCommandStack.Create;
begin
  inherited;
  FComandos := TList<IComandoEditorial>.Create;
end;

destructor TCommandStack.Destroy;
begin
  FComandos.Free;
  inherited;
end;

procedure TCommandStack.Executar(const AComando: IComandoEditorial);
begin
  if not Assigned(AComando) then
    raise EValorInvalido.Create('Comando não pode ser nil.');

  AComando.Executar;
  FComandos.Add(AComando);
end;

function TCommandStack.DesfazerUltimo: Boolean;
var
  Cmd: IComandoEditorial;
begin
  if FComandos.Count = 0 then
    Exit(False);

  Cmd := FComandos[FComandos.Count - 1];
  Cmd.Desfazer;
  FComandos.Delete(FComandos.Count - 1);
  Result := True;
end;

function TCommandStack.PodeDesfazer: Boolean;
begin
  Result := FComandos.Count > 0;
end;

function TCommandStack.DescricaoUltimo: string;
begin
  if FComandos.Count = 0 then
    Exit('');
  Result := FComandos[FComandos.Count - 1].Descricao;
end;

procedure TCommandStack.Limpar;
begin
  FComandos.Clear;
end;

function TCommandStack.Total: Integer;
begin
  Result := FComandos.Count;
end;

end.
