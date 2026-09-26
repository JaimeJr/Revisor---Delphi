unit UGatilhoRegistry;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  UIGatilhoLocal,
  UManuscrito,
  UValores;

type
  TGatilhoRegistry = class(TInterfacedObject, IGatilhoRegistry)
  private
    FGatilhos: TList<IGatilhoLocal>;
    FIndicePorVicio: TDictionary<string, IGatilhoLocal>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Registrar(const AGatilho: IGatilhoLocal);
    function AvaliarTodos(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TArray<TGatilhoResultado>;
    function ViciosCobertos: TArray<string>;
    function TemGatilhoPara(const AVicioID: string): Boolean;
    function GatilhoPorVicio(const AVicioID: string): IGatilhoLocal;
  end;

implementation

constructor TGatilhoRegistry.Create;
begin
  inherited;
  FGatilhos := TList<IGatilhoLocal>.Create;
  FIndicePorVicio := TDictionary<string, IGatilhoLocal>.Create;
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

  if FIndicePorVicio.ContainsKey(ID) then
    Exit;

  FIndicePorVicio.Add(ID, AGatilho);
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
      if Gatilho.PrecisaContexto and not Assigned(AContexto) then
        Continue;

      R := Gatilho.Avaliar(AParagrafo, AContexto);

      if R.VicioID = '' then
        R.VicioID := Gatilho.VicioID;

      if R.Disparou then
        Lista.Add(R);
    end;

    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;

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
  Par: TPair<string, IGatilhoLocal>;
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

function TGatilhoRegistry.GatilhoPorVicio(
  const AVicioID: string): IGatilhoLocal;
begin
  if not FIndicePorVicio.TryGetValue(AVicioID, Result) then
    Result := nil;
end;

end.
