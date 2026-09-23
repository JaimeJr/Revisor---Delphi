unit UJsonMigrador;

{
  UJsonMigrador.pas
  ─────────────────────────────────────────────────────────────
  Versionamento de schema dos JSONs persistidos.

  Ideia:
    • Cada arquivo (Antes, Novo, Envio, Resposta, Vicios) tem
      um campo versao_schema no topo.
    • Ao carregar, o repositório chama o migrador antes de
      interpretar o conteúdo. Se a versão for a atual, é no-op.
    • Se for antiga, o migrador aplica transformações em cadeia
      (V1 → V2 → V3 → ...) até chegar à versão de destino.
    • Se for futura, ou se não houver migrador registrado para
      o salto necessário, lança EOperacaoInvalida com mensagem
      clara.

  Estado na v1:
    • Nenhum migrador registrado (schema ainda é v1 em tudo).
    • Migrar só valida que a versão atual é igual à de destino.
    • O ponto de extensão já existe, pronto para a v2.

  Como estender (exemplo futuro):
    • Criar TMigradorV1ParaV2 = class(TInterfacedObject, IMigradorJson)
        VersaoOrigem  := 1
        VersaoDestino := 2
        Migrar altera o TJSONObject (move campo, renomeia chave, etc.)
    • Registrar no CompositionRoot:
        Migrador.Registrar(TMigradorV1ParaV2.Create)
    • Nada mais muda nos repositórios.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON,
  UValores;

type
  /// <summary>
  ///   Migrador de uma versão para a próxima. Recebe o JSON
  ///   já parseado (TJSONObject) e o transforma in-place.
  /// </summary>
  IMigradorJson = interface
    ['{A1B2C3D4-0015-4000-8000-000000000001}']

    /// <summary>Versão de origem que este migrador aceita.</summary>
    function VersaoOrigem: Integer;

    /// <summary>Versão de destino após a migração.</summary>
    function VersaoDestino: Integer;

    /// <summary>
    ///   Transforma o JSON de VersaoOrigem para VersaoDestino.
    ///   Modifica o objeto in-place. Lança EOperacaoInvalida
    ///   se o JSON não estiver no formato esperado.
    /// </summary>
    procedure Migrar(const AJson: TJSONObject);

    /// <summary>Descrição curta para log ("v1 → v2: campo X renomeado").</summary>
    function Descricao: string;
  end;

  /// <summary>
  ///   Orquestrador de migrações. Registra migradores e aplica
  ///   a cadeia necessária para um JSON chegar à versão alvo.
  /// </summary>
  TJsonMigrador = class
  private
    FMigradores: TObjectList<IMigradorJson>;
    function EncontrarMigrador(const AVersaoOrigem: Integer): IMigradorJson;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Registra um migrador. IDs duplicados são ignorados.
    /// </summary>
    procedure Registrar(const AMigrador: IMigradorJson);

    /// <summary>
    ///   Verifica se a versão do JSON precisa de migração para
    ///   chegar à versão alvo. Retorna True se já está na versão
    ///   alvo (nenhuma migração necessária).
    /// </summary>
    function JaNaVersao(const AJson: TJSONObject;
      const AVersaoAlvo: Integer): Boolean;

    /// <summary>
    ///   Aplica migrações em cadeia até AJson atingir AVersaoAlvo.
    ///   Lança EOperacaoInvalida se o JSON tiver versão futura,
    ///   ou se faltar migrador para algum salto intermediário.
    /// </summary>
    procedure Migrar(const AJson: TJSONObject; const AVersaoAlvo: Integer);

    /// <summary>Quantidade de migradores registrados.</summary>
    function TotalMigradores: Integer;

    /// <summary>
    ///   Retorna um migrador vazio — sem migradores registrados.
    ///   Útil na v1, onde o schema ainda é único.
    /// </summary>
    class function Vazio: TJsonMigrador;
  end;

implementation

const
  CHAVE_VERSAO_SCHEMA = 'versao_schema';

{ TJsonMigrador }

constructor TJsonMigrador.Create;
begin
  inherited;
  FMigradores := TObjectList<IMigradorJson>.Create;
end;

destructor TJsonMigrador.Destroy;
begin
  FMigradores.Free;
  inherited;
end;

procedure TJsonMigrador.Registrar(const AMigrador: IMigradorJson);
begin
  if AMigrador = nil then
    raise EValorInvalido.Create('Migrador não pode ser nil.');

  if AMigrador.VersaoDestino <> (AMigrador.VersaoOrigem + 1) then
    raise EValorInvalido.CreateFmt(
      'Migrador "%s" deve avançar exatamente 1 versão ' +
      '(origem %d, destino %d).',
      [AMigrador.Descricao, AMigrador.VersaoOrigem, AMigrador.VersaoDestino]);

  // Evita duplicata da mesma origem.
  if Assigned(EncontrarMigrador(AMigrador.VersaoOrigem)) then
    raise EOperacaoInvalida.CreateFmt(
      'Já existe migrador registrado para a versão %d.',
      [AMigrador.VersaoOrigem]);

  FMigradores.Add(AMigrador);
end;

function TJsonMigrador.EncontrarMigrador(
  const AVersaoOrigem: Integer): IMigradorJson;
var
  M: IMigradorJson;
begin
  for M in FMigradores do
    if M.VersaoOrigem = AVersaoOrigem then
      Exit(M);
  Result := nil;
end;

function TJsonMigrador.JaNaVersao(const AJson: TJSONObject;
  const AVersaoAlvo: Integer): Boolean;
begin
  if AJson = nil then
    raise EValorInvalido.Create('JSON não pode ser nil.');

  var VersaoAtual := AJson.GetValue<Integer>(CHAVE_VERSAO_SCHEMA);
  Result := VersaoAtual = AVersaoAlvo;
end;

procedure TJsonMigrador.Migrar(const AJson: TJSONObject;
  const AVersaoAlvo: Integer);
var
  VersaoAtual: Integer;
  Migrador: IMigradorJson;
  Passos: Integer;
begin
  if AJson = nil then
    raise EValorInvalido.Create('JSON não pode ser nil.');

  VersaoAtual := AJson.GetValue<Integer>(CHAVE_VERSAO_SCHEMA);

  // Já na versão alvo — nada a fazer.
  if VersaoAtual = AVersaoAlvo then
    Exit;

  // Versão futura — não é possível retroceder.
  if VersaoAtual > AVersaoAlvo then
    raise EOperacaoInvalida.CreateFmt(
      'JSON está na versão %d, mas o alvo é %d. ' +
      'Migração reversa não é suportada.',
      [VersaoAtual, AVersaoAlvo]);

  // Aplica migrações em cadeia.
  Passos := 0;
  while VersaoAtual < AVersaoAlvo do
  begin
    Migrador := EncontrarMigrador(VersaoAtual);

    if not Assigned(Migrador) then
      raise EOperacaoInvalida.CreateFmt(
        'Não há migrador registrado para converter da versão %d ' +
        'para %d. Registre um IMigradorJson com VersaoOrigem = %d ' +
        'ou ajuste a versão alvo.',
        [VersaoAtual, AVersaoAlvo, VersaoAtual]);

    Migrador.Migrar(AJson);

    // Atualiza a versão no JSON para refletir o avanço.
    AJson.RemovePair(CHAVE_VERSAO_SCHEMA);
    AJson.AddPair(CHAVE_VERSAO_SCHEMA,
      TJSONNumber.Create(Migrador.VersaoDestino));

    VersaoAtual := Migrador.VersaoDestino;
    Inc(Passos);

    // Guarda contra loop infinito — no cenário normal, o
    // Registrador já impede, mas defensivo é melhor.
    if Passos > 100 then
      raise EOperacaoInvalida.Create(
        'Migração em cadeia excedeu 100 passos. ' +
        'Verifique os migradores registrados.');
  end;
end;

function TJsonMigrador.TotalMigradores: Integer;
begin
  Result := FMigradores.Count;
end;

class function TJsonMigrador.Vazio: TJsonMigrador;
begin
  Result := TJsonMigrador.Create;
  // Nenhum migrador registrado — só valida a versão.
end;

end.
