unit UPromptFactory;

{
  UPromptFactory.pas
  ─────────────────────────────────────────────────────────────
  Fábrica de construtores de prompt. Recebe um TModoEnvio e
  devolve o IConstrutorPrompt apropriado.

  Decisão de cache:
    • As duas implementações (TPromptCirurgico, TPromptVarredura)
      não têm estado mutável. Uma única instância de cada é
      suficiente para toda a sessão.
    • Criar no constructor e reutilizar evita alocação por
      chamada, e é seguro porque a interface é thread-safe
      por design (só métodos que leem config e devolvem string).

  Se um dia um construtor ganhar estado (ex: cache de
  formatação), a criação passa a ser por chamada — basta
  trocar os campos por criação inline.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UIConstrutorPrompt,
  UValores;

type
  TPromptFactory = class(TInterfacedObject, IPromptFactory)
  private
    FCirurgico: IConstrutorPrompt;
    FVarredura: IConstrutorPrompt;
  public
    constructor Create;
    destructor Destroy; override;

    function ParaModo(const AModo: TModoEnvio): IConstrutorPrompt;
  end;

implementation

uses
  UPromptCirurgico,
  UPromptVarredura;

{ TPromptFactory }

constructor TPromptFactory.Create;
begin
  inherited Create;
  FCirurgico := TPromptCirurgico.Create;
  FVarredura := TPromptVarredura.Create;
end;

destructor TPromptFactory.Destroy;
begin
  // Interfaces são liberadas automaticamente quando as
  // referências saem de escopo. Nada a fazer aqui, mas
  // mantemos o destructor para deixar explícito que a classe
  // gerencia esses objetos.
  inherited;
end;

function TPromptFactory.ParaModo(
  const AModo: TModoEnvio): IConstrutorPrompt;
begin
  case AModo of
    meCirurgico: Result := FCirurgico;
    meVarredura: Result := FVarredura;
  else
    // Enum ganhou valor novo e o case não foi atualizado —
    // falha explícita em vez de devolver nil silencioso.
    raise EValorInvalido.CreateFmt(
      'Modo de envio sem construtor de prompt: %d.', [Ord(AModo)]);
  end;
end;

end.
