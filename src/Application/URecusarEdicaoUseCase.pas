unit URecusarEdicaoUseCase;

{
  URecusarEdicaoUseCase.pas
  ─────────────────────────────────────────────────────────────
  Caso de uso que recusa UMA edição da IA.

  Diferenças em relação ao aceite (9.5):
    • Não alimenta Vicios.JSON — recusa não vira exemplo.
    • Não altera o texto do parágrafo.
    • Só muda o status se o parágrafo estava pendente.

  Persiste Novo.JSON via SalvarAuto. Nada mais.

  Ownership:
    • O Manuscrito é do chamador.
    • O Comando é gerenciado pelo CommandStack.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UManuscrito,
  UEdicaoSugerida,
  URecusarEdicaoCommand,
  UCommandStack,
  UIComandoEditorial,
  UINovoRepository,
  UValores;

type
  TRecusarEdicaoUseCase = class
  private
    FNovoRepo: INovoRepository;
    FCommandStack: TCommandStack;
  public
    constructor Create(const ANovoRepo: INovoRepository;
      const ACommandStack: TCommandStack);

    /// <summary>
    ///   Executa a recusa. Retorna False se o parágrafo não
    ///   existir no manuscrito.
    /// </summary>
    function Executar(const AManuscrito: TManuscrito;
      const ACaminhoNovo: string;
      const AEdicao: TEdicaoSugerida;
      const AIDChamada: string): Boolean;
  end;

implementation

{ TRecusarEdicaoUseCase }

constructor TRecusarEdicaoUseCase.Create(const ANovoRepo: INovoRepository;
  const ACommandStack: TCommandStack);
begin
  inherited Create;

  if not Assigned(ANovoRepo) then
    raise EValorInvalido.Create('INovoRepository não pode ser nil.');
  if not Assigned(ACommandStack) then
    raise EValorInvalido.Create('TCommandStack não pode ser nil.');

  FNovoRepo := ANovoRepo;
  FCommandStack := ACommandStack;
end;

function TRecusarEdicaoUseCase.Executar(const AManuscrito: TManuscrito;
  const ACaminhoNovo: string; const AEdicao: TEdicaoSugerida;
  const AIDChamada: string): Boolean;
var
  Paragrafo: TParagrafo;
  Cmd: IComandoEditorial;
begin
  if not Assigned(AManuscrito) then
    raise EValorInvalido.Create('Manuscrito não pode ser nil.');
  if not Assigned(AEdicao) then
    raise EValorInvalido.Create('Edição não pode ser nil.');
  if AEdicao.VicioID = '' then
    raise EValorInvalido.Create('Edição precisa ter VicioID.');
  if ACaminhoNovo = '' then
    raise EValorInvalido.Create('CaminhoNovo não pode ser vazio.');

  Paragrafo := AManuscrito.ParagrafoPorID(AEdicao.ParagrafoID);
  if not Assigned(Paragrafo) then
    Exit(False);

  Cmd := TRecusarEdicaoCommand.Create(Paragrafo, AEdicao, AIDChamada);
  FCommandStack.Executar(Cmd);

  FNovoRepo.SalvarAuto(AManuscrito, ACaminhoNovo);

  Result := True;
end;

end.
