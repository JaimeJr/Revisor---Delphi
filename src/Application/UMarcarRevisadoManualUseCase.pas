unit UMarcarRevisadoManualUseCase;

{
  UMarcarRevisadoManualUseCase.pas
  ─────────────────────────────────────────────────────────────
  Caso de uso que alterna o status "revisado manualmente" de
  um ou vários parágrafos.

  Regras:
    • Só alterna parágrafos em spPendente ou spRevisadoManual.
    • Parágrafos com status definido pela IA (spAceito,
      spRecusado) ou editados manualmente (spEditadoManual)
      ficam intocados.
    • Retorna a quantidade de parágrafos efetivamente alterados.

  Persiste Novo.JSON via SalvarAuto apenas se houve alteração.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UManuscrito,
  UMarcarRevisadoManualCommand,
  UCommandStack,
  UINovoRepository,
  UValores;

type
  TMarcarRevisadoManualUseCase = class
  private
    FNovoRepo: INovoRepository;
    FCommandStack: TCommandStack;

    function PodeTogglear(const AStatus: TStatusParagrafo): Boolean;
  public
    constructor Create(const ANovoRepo: INovoRepository;
      const ACommandStack: TCommandStack);

    /// <summary>
    ///   Alterna o status de um parágrafo.
    ///   Retorna True se houve alteração.
    /// </summary>
    function Executar(const AManuscrito: TManuscrito;
      const ACaminhoNovo, AParagrafoID: string): Boolean;

    /// <summary>
    ///   Alterna o status de vários parágrafos.
    ///   Retorna a quantidade efetivamente alterada.
    /// </summary>
    function ExecutarLote(const AManuscrito: TManuscrito;
      const ACaminhoNovo: string;
      const AParagrafosIDs: TArray<string>): Integer;
  end;

implementation

{ TMarcarRevisadoManualUseCase }

constructor TMarcarRevisadoManualUseCase.Create(const ANovoRepo: INovoRepository;
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

function TMarcarRevisadoManualUseCase.PodeTogglear(
  const AStatus: TStatusParagrafo): Boolean;
begin
  Result := (AStatus = spPendente) or (AStatus = spRevisadoManual);
end;

function TMarcarRevisadoManualUseCase.Executar(const AManuscrito: TManuscrito;
  const ACaminhoNovo, AParagrafoID: string): Boolean;
var
  Paragrafo: TParagrafo;
  Cmd: TMarcarRevisadoManualCommand;
begin
  if not Assigned(AManuscrito) then
    raise EValorInvalido.Create('Manuscrito não pode ser nil.');
  if AParagrafoID = '' then
    raise EValorInvalido.Create('ParagrafoID não pode ser vazio.');
  if ACaminhoNovo = '' then
    raise EValorInvalido.Create('CaminhoNovo não pode ser vazio.');

  Paragrafo := AManuscrito.ParagrafoPorID(AParagrafoID);
  if not Assigned(Paragrafo) then
    Exit(False);
  if not PodeTogglear(Paragrafo.Status) then
    Exit(False);

  Cmd := TMarcarRevisadoManualCommand.Create(Paragrafo);
  FCommandStack.Executar(Cmd);

  if not Cmd.Trocou then
    Exit(False);

  FNovoRepo.SalvarAuto(AManuscrito, ACaminhoNovo);
  Result := True;
end;

function TMarcarRevisadoManualUseCase.ExecutarLote(
  const AManuscrito: TManuscrito; const ACaminhoNovo: string;
  const AParagrafosIDs: TArray<string>): Integer;
var
  ID: string;
  Paragrafo: TParagrafo;
  Cmd: TMarcarRevisadoManualCommand;
  Alterados: Integer;
begin
  if not Assigned(AManuscrito) then
    raise EValorInvalido.Create('Manuscrito não pode ser nil.');
  if ACaminhoNovo = '' then
    raise EValorInvalido.Create('CaminhoNovo não pode ser vazio.');
  if Length(AParagrafosIDs) = 0 then
    Exit(0);

  Alterados := 0;
  for ID in AParagrafosIDs do
  begin
    Paragrafo := AManuscrito.ParagrafoPorID(ID);
    if not Assigned(Paragrafo) then
      Continue;
    if not PodeTogglear(Paragrafo.Status) then
      Continue;

    Cmd := TMarcarRevisadoManualCommand.Create(Paragrafo);
    FCommandStack.Executar(Cmd);

    if Cmd.Trocou then
      Inc(Alterados);
  end;

  if Alterados > 0 then
    FNovoRepo.SalvarAuto(AManuscrito, ACaminhoNovo);

  Result := Alterados;
end;

end.
