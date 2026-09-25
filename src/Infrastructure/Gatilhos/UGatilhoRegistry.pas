unit UGatilhoRegistry;

{
  UGatilhoRegistry.pas
  ─────────────────────────────────────────────────────────────
  Registro central de gatilhos locais.

  Responsabilidades:
    • Guardar os gatilhos registrados, sem duplicata de VicioID.
    • Avaliar todos sobre um parágrafo, devolvendo só os que
      dispararam, ordenados por confiança decrescente.
    • Responder quais VicioIDs têm cobertura.

  Decisões:
    • Primeiro gatilho com um VicioID ganha. Registrar de novo
      o mesmo ID é no-op, não erro — permite registro em lote
      no CompositionRoot sem checagem prévia.
    • Ordenação por confiança decrescente; em empate, mantém a
      ordem de registro (estabilidade).
    • Gatilhos que precisam de contexto são pulados se o
      contexto for nil — não é erro, só não avalia.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  UGatilhoLocal,
  UManuscrito,
  UValores;

type
  TGatilhoRegistry = class(TInterfacedObject, IGatilhoRegistry)
  private
    FGatilhos: TList<IGatilhoLocal>;
    FIndicePorVicio: TDictionary<string, Integer>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Registrar(const AGatilho: IGatilhoLocal);

    function AvaliarTodos(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TArray<TGatilhoResultado>;

    function ViciosCobertos: TArray<string>;

    function TemGatilhoPara(const AVicioID: string): Boolean;
  end;

implementation

{ TGatilhoRegistry }

constructor TGatilhoRegistry.Create;
begin
  inherited;
  FGatilhos := TList<IGatilhoLocal>.Create;
  FIndicePorVicio := TDictionary<string, Integer>.Create;
end;

destructor TGatilhoRegistry.Destroy;
begin
  FIndicePorVicio.Free;
  FGatilhos.Free;
  inherited;
end;

procedure TGatilhoRegistry.Registrar(const AGatilho: IGatilhoLocal);
var
  ID: string;
begin
  if not Assigned(AGatilho) then
    raise EValorInvalido.Create('Gatilho não pode ser nil.');

  ID := AGatilho.VicioID;
  if ID = '' then
    raise EValorInvalido.Create('Gatilho precisa ter VicioID.');

  // Já existe? Ignora silenciosamente — primeiro ganha.
  if FIndicePorVicio.ContainsKey(ID) then
    Exit;

  FIndicePorVicio.Add(ID, FGatilhos.Count);
  FGatilhos.Add(AGatilho);
end;

function TGatilhoRegistry.AvaliarTodos(const AParagrafo: TParagrafo;
  const AContexto: TContextoGlobal): TArray<TGatilhoResultado>;
var
  Lista: TList<TGatilhoResultado>;
  Gatilho: IGatilhoLocal;
  R: TGatilhoResultado;
begin
  if not Assigned(AParagrafo) then
    raise EValorInvalido.Create('Parágrafo não pode ser nil.');

  Lista := TList<TGatilhoResultado>.Create;
  try
    for Gatilho in FGatilhos do
    begin
      // Pula gatilhos que precisam de contexto quando ele não veio.
      if Gatilho.PrecisaContexto and not Assigned(AContexto) then
        Continue;

      R := Gatilho.Avaliar(AParagrafo, AContexto);

      // Garante que o VicioID veio preenchido (responsabilidade
      // do gatilho — defesa contra implementação esquecida).
      if R.VicioID = '' then
        R.VicioID := Gatilho.VicioID;

      if R.Disparou then
        Lista.Add(R);
    end;

    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;

  // Ordena por confiança decrescente. Em empate, mantém ordem
  // de inserção (ordenamento estável do TArray.Sort).
  TArray.Sort<TGatilhoResultado>(Result,
    TComparer<TGatilhoResultado>.Construct(
      function(const A, B: TGatilhoResultado): Integer
      begin
        if A.Confianca > B.Confianca then
          Result := -1
        else if A.Confianca < B.Confianca then
          Result := 1
        else
          Result := 0;
      end));
end;

function TGatilhoRegistry.ViciosCobertos: TArray<string>;
var
  Lista: TList<string>;
  Par: TPair<string, Integer>;
begin
  Lista := TList<string>.Create;
  try
    for Par in FIndicePorVicio do
      Lista.Add(Par.Key);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TGatilhoRegistry.TemGatilhoPara(const AVicioID: string): Boolean;
begin
  Result := FIndicePorVicio.ContainsKey(AVicioID);
end;

end.
