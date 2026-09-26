unit UAvaliarGatilhosUseCase;

{
  UAvaliarGatilhosUseCase.pas
  ─────────────────────────────────────────────────────────────
  Caso de uso que roda os gatilhos locais sobre parágrafos e
  persiste os disparos no Novo.JSON.

  Regra de reexecução por (parágrafo, gatilho):
    • Nunca rodou → SIM
    • Hash do parágrafo mudou → SIM
    • Versão do gatilho mudou → SIM
    • Senão → NÃO

  Não reexecutar economiza tempo e mantém o resultado estável
  entre aberturas de cena.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UIGatilhoLocal,
  UManuscrito,
  UINovoRepository,
  UValores;

type
  TAvaliarGatilhosUseCase = class
  private
    FRegistry: IGatilhoRegistry;
    FNovoRepo: INovoRepository;

    function PrecisaReexecutar(const AParagrafo: TParagrafo;
      const AGatilho: IGatilhoLocal): Boolean;

    /// <summary>
    ///   Roda o gatilho e ajusta o estado do parágrafo.
    ///   Retorna True se houve alteração.
    /// </summary>
    function AvaliarParagrafoComGatilho(const AParagrafo: TParagrafo;
      const AGatilho: IGatilhoLocal;
      const AContexto: TContextoGlobal): Boolean;

    /// <summary>
    ///   Avalia todos os gatilhos sobre uma cena.
    ///   Retorna o número de alterações efetivas.
    /// </summary>
    function AvaliarCena(const ACena: TCena;
      const AContexto: TContextoGlobal): Integer;
  public
    constructor Create(const ARegistry: IGatilhoRegistry;
      const ANovoRepo: INovoRepository);

    /// <summary>
    ///   Executa a avaliação. ACenaIDs vazio = todas as cenas.
    ///   Retorna o número de alterações efetivas.
    /// </summary>
    function Executar(const AManuscrito: TManuscrito;
      const ACaminhoNovo: string;
      const ACenaIDs: TArray<TID>): Integer;
    destructor Destroy; override;
  end;

implementation

const
  VERSAO_ATUAL_DOS_GATILHOS = 'v1';

{ TAvaliarGatilhosUseCase }

constructor TAvaliarGatilhosUseCase.Create(const ARegistry: IGatilhoRegistry;
  const ANovoRepo: INovoRepository);
begin
  inherited Create;

  if not Assigned(ARegistry) then
    raise EValorInvalido.Create('IGatilhoRegistry não pode ser nil.');
  if not Assigned(ANovoRepo) then
    raise EValorInvalido.Create('INovoRepository não pode ser nil.');

  FRegistry := ARegistry;
  FNovoRepo := ANovoRepo;
end;

function TAvaliarGatilhosUseCase.PrecisaReexecutar(
  const AParagrafo: TParagrafo;
  const AGatilho: IGatilhoLocal): Boolean;
var
  Disparo: TDisparoGatilho;
begin
  Disparo := AParagrafo.DisparoDe(AGatilho.VicioID);

  if not Assigned(Disparo) then
    Exit(True);

  if Disparo.HashParagrafoNoDisparo <> AParagrafo.Hash then
    Exit(True);

  if Disparo.VersaoGatilho <> VERSAO_ATUAL_DOS_GATILHOS then
    Exit(True);

  Result := False;
end;

function TAvaliarGatilhosUseCase.AvaliarParagrafoComGatilho(
  const AParagrafo: TParagrafo; const AGatilho: IGatilhoLocal;
  const AContexto: TContextoGlobal): Boolean;
var
  Resultado: TGatilhoResultado;
  Disparo: TDisparoGatilho;
begin
  Result := False;

  Resultado := AGatilho.Avaliar(AParagrafo, AContexto);

  if Resultado.Disparou then
  begin
    Disparo := TDisparoGatilho.Create;
    try
      Disparo.GatilhoID := AGatilho.VicioID;
      Disparo.VersaoGatilho := VERSAO_ATUAL_DOS_GATILHOS;
      Disparo.Confianca := Resultado.Confianca;
      Disparo.Trechos := Resultado.Trechos;
      Disparo.HashParagrafoNoDisparo := AParagrafo.Hash;
      Disparo.Quando := Now;

      AParagrafo.RegistrarDisparo(Disparo);
      Result := True;
    except
      Disparo.Free;
      raise;
    end;
  end
  else
  begin
    if AParagrafo.TemDisparoDe(AGatilho.VicioID) then
    begin
      AParagrafo.RemoverDisparo(AGatilho.VicioID);
      Result := True;
    end;
  end;
end;

function TAvaliarGatilhosUseCase.AvaliarCena(const ACena: TCena;
  const AContexto: TContextoGlobal): Integer;
var
  Par: TParagrafo;
  VicioID: string;
  Gatilho: IGatilhoLocal;
begin
  Result := 0;

  if not Assigned(FRegistry) then
    raise EOperacaoInvalida.Create(
      'TAvaliarGatilhosUseCase: FRegistry está nil. ' +
      'Bug de ciclo de vida — verificar CompositionRoot.');

  for Par in ACena.Paragrafos do
    for VicioID in FRegistry.ViciosCobertos do
    begin
      Gatilho := FRegistry.GatilhoPorVicio(VicioID);
      if not Assigned(Gatilho) then
        Continue;

      if not PrecisaReexecutar(Par, Gatilho) then
        Continue;

      if AvaliarParagrafoComGatilho(Par, Gatilho, AContexto) then
        Inc(Result);
    end;
end;

function TAvaliarGatilhosUseCase.Executar(const AManuscrito: TManuscrito;
  const ACaminhoNovo: string; const ACenaIDs: TArray<TID>): Integer;
var
  Ato: TAto;
  Cap: TCapitulo;
  Cena: TCena;
  Contexto: TContextoGlobal;
  CenaAlvo: TID;
  Processar: Boolean;
  TotalAlteracoes: Integer;
begin
  if not Assigned(AManuscrito) then
    raise EValorInvalido.Create('Manuscrito não pode ser nil.');
  if ACaminhoNovo = '' then
    raise EValorInvalido.Create('CaminhoNovo não pode ser vazio.');

  TotalAlteracoes := 0;

  Contexto := TContextoGlobal.Create(AManuscrito);
  try
    for Ato in AManuscrito.Atos do
      for Cap in Ato.Capitulos do
        for Cena in Cap.Cenas do
        begin
          if Length(ACenaIDs) = 0 then
            Processar := True
          else
          begin
            Processar := False;
            for CenaAlvo in ACenaIDs do
              if CenaAlvo = Cena.ID then
              begin
                Processar := True;
                Break;
              end;
          end;

          if Processar then
            Inc(TotalAlteracoes, AvaliarCena(Cena, Contexto));
        end;
  finally
    Contexto.Free;
  end;

  if TotalAlteracoes > 0 then
    FNovoRepo.SalvarAuto(AManuscrito, ACaminhoNovo);

  Result := TotalAlteracoes;
end;

destructor TAvaliarGatilhosUseCase.Destroy;
begin
  inherited;
end;

end.
