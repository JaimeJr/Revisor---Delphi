unit UCacheMemoria;

{
  UCacheMemoria.pas
  ─────────────────────────────────────────────────────────────
  Cache em memória de respostas da IA, indexado por hash de
  payload. Evita reenvios idênticos à API.

  Comportamento:
    • Guardar armazena uma CÓPIA da resposta. O chamador não
      precisa se preocupar com ownership — pode alterar a
      resposta original à vontade.
    • Recuperar devolve uma CÓPIA também. Mutações do chamador
      não afetam o cache.
    • Se o mesmo hash for guardado duas vezes, a entrada
      anterior é substituída (mais recente ganha).
    • Sem TTL, sem persistência. Vive durante a sessão.

  Complexidade:
    • Guardar / Recuperar / Contem: O(1) amortizado.
    • Total: O(1).
    • Invalidar / Limpar: O(k) onde k é o número de entradas
      removidas (Limpar) ou 1 (Invalidar).

  Decisão de clone:
    • A cópia profunda é feita via TResposta.Clonar — método
      adicionado à classe especificamente para este uso.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UICacheChamadas,
  UEdicaoSugerida;

type
  TCacheMemoria = class(TInterfacedObject, ICacheChamadas)
  private
    FEntradas: TObjectDictionary<string, TResposta>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Guardar(const AHashPayload: string;
      const AResposta: TResposta);

    function Recuperar(const AHashPayload: string): TResposta;

    function Contem(const AHashPayload: string): Boolean;

    procedure Invalidar(const AHashPayload: string);

    procedure Limpar;

    function TotalEntradas: Integer;
  end;

implementation

uses
  UValores;

{ TCacheMemoria }

constructor TCacheMemoria.Create;
begin
  inherited;
  // doOwnsValues: TObjectDictionary libera as TResposta guardadas
  // quando substituídas ou no Destroy.
  FEntradas := TObjectDictionary<string, TResposta>.Create([doOwnsValues]);
end;

destructor TCacheMemoria.Destroy;
begin
  FEntradas.Free;
  inherited;
end;

procedure TCacheMemoria.Guardar(const AHashPayload: string;
  const AResposta: TResposta);
begin
  if AHashPayload = '' then
    raise EValorInvalido.Create('Hash de payload não pode ser vazio.');
  if AResposta = nil then
    raise EValorInvalido.Create('Resposta não pode ser nil.');

  // Guarda uma cópia — desacopla o cache do ciclo de vida do
  // objeto do chamador. AddOrSetValue com doOwnsValues libera
  // a entrada anterior automaticamente.
  FEntradas.AddOrSetValue(AHashPayload, AResposta.Clonar);
end;

function TCacheMemoria.Recuperar(const AHashPayload: string): TResposta;
var
  Guardada: TResposta;
begin
  if not FEntradas.TryGetValue(AHashPayload, Guardada) then
    Exit(nil);

  Result := Guardada.Clonar;
end;

function TCacheMemoria.Contem(const AHashPayload: string): Boolean;
begin
  Result := FEntradas.ContainsKey(AHashPayload);
end;

procedure TCacheMemoria.Invalidar(const AHashPayload: string);
begin
  FEntradas.Remove(AHashPayload);
end;

procedure TCacheMemoria.Limpar;
begin
  FEntradas.Clear;
end;

function TCacheMemoria.TotalEntradas: Integer;
begin
  Result := FEntradas.Count;
end;

end.
