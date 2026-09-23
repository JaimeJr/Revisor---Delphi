unit UVicio;

{
  UVicio.pas
  ─────────────────────────────────────────────────────────────
  Entidades do catálogo de vícios editoriais.

  O catálogo é a memória editorial do autor: cada vício tem
  sua definição, dica de correção, gatilho local (heurística)
  e exemplos extraídos do próprio manuscrito.

  Regras:
    • Apenas composição via TObjectList<T>.
    • Nenhuma lógica de I/O, HTTP, VCL ou JSON.
    • TVicio é imutável em seus campos de identidade (ID, Nome,
      Origem). Frequência e exemplos crescem ao longo do uso.
    • TCatalogoVicios é versionado — cada edição incrementa
      Versao, que entra na chave de cache do payload.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  UValores;

type
  // ────────────────────────────────────────────────────────────
  // Exemplo de ocorrência no manuscrito
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Registro de uma ocorrência real de um vício no manuscrito.
  ///   Alimentado quando o usuário aceita uma edição.
  /// </summary>
  TExemploManuscrito = class
  private
    FCenaID: TID;
    FParagrafoID: TID;
    FTrecho: string;
    FIDChamada: string;
    FTimestamp: TDateTime;
  public
    property CenaID: TID read FCenaID write FCenaID;
    property ParagrafoID: TID read FParagrafoID write FParagrafoID;
    property Trecho: string read FTrecho write FTrecho;
    property IDChamada: string read FIDChamada write FIDChamada;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;
  end;

  // ────────────────────────────────────────────────────────────
  // Vício
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Definição de um vício editorial no catálogo.
  /// </summary>
  TVicio = class
  private
    FID: string;
    FNome: string;
    FOrigem: TOrigemVicio;
    FDescricao: string;
    FDicaCorrecao: string;
    FGatilhoLocal: string;
    FPrecisaCrossCena: Boolean;
    FExemplos: TObjectList<TExemploManuscrito>;
    FFrequenciaNoManuscrito: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property ID: string read FID write FID;
    property Nome: string read FNome write FNome;
    property Origem: TOrigemVicio read FOrigem write FOrigem;
    property Descricao: string read FDescricao write FDescricao;
    property DicaCorrecao: string read FDicaCorrecao write FDicaCorrecao;
    property GatilhoLocal: string read FGatilhoLocal write FGatilhoLocal;
    property PrecisaCrossCena: Boolean
      read FPrecisaCrossCena write FPrecisaCrossCena;
    property Exemplos: TObjectList<TExemploManuscrito> read FExemplos;
    property FrequenciaNoManuscrito: Integer
      read FFrequenciaNoManuscrito write FFrequenciaNoManuscrito;

    /// <summary>
    ///   Registra um exemplo de ocorrência e incrementa a
    ///   frequência em 1. Atômico — não chamar os dois separado.
    /// </summary>
    procedure RegistrarExemplo(const AExemplo: TExemploManuscrito);

    /// <summary>
    ///   True se este vício é uma semente do sistema (não
    ///   adicionado pelo autor).
    /// </summary>
    function EhGenerico: Boolean;

    /// <summary>Lista dos trechos já registrados (para diagnóstico/UI).</summary>
    function Trechos: TArray<string>;
  end;

  // ────────────────────────────────────────────────────────────
  // Catálogo de vícios
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Coleção completa de vícios. Uma instância por sessão.
  /// </summary>
  TCatalogoVicios = class
  private
    FVersaoSchema: Integer;
    FVersao: Integer;
    FAtualizadoEm: TDateTime;
    FCategorias: TObjectList<TVicio>;
    FIndicePorID: TDictionary<string, TVicio>;
  public
    constructor Create;
    destructor Destroy; override;

    property VersaoSchema: Integer read FVersaoSchema write FVersaoSchema;
    property Versao: Integer read FVersao write FVersao;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
    property Categorias: TObjectList<TVicio> read FCategorias;

    /// <summary>
    ///   Adiciona um vício ao catálogo. Incrementa Versao
    ///   automaticamente. Lança se já existir ID igual.
    /// </summary>
    procedure Adicionar(const AVicio: TVicio);

    /// <summary>
    ///   Remove o vício pelo ID. Incrementa Versao se removeu.
    ///   Retorna False se não encontrado.
    /// </summary>
    function Remover(const AID: string): Boolean;

    /// <summary>Busca por ID. Retorna nil se não existir.</summary>
    function VicioPorID(const AID: string): TVicio;

    /// <summary>True se existe vício com esse ID.</summary>
    function Existe(const AID: string): Boolean;

    /// <summary>
    ///   Registra uma ocorrência no vício indicado e incrementa
    ///   a frequência. Incrementa Versao do catálogo.
    ///   Retorna False se o vício não existir.
    /// </summary>
    function RegistrarOcorrencia(const AVicioID: string;
      const AExemplo: TExemploManuscrito): Boolean;

    /// <summary>IDs de todos os vícios, na ordem de cadastro.</summary>
    function IDs: TArray<string>;

    /// <summary>Soma de todas as frequências no manuscrito.</summary>
    function TotalOcorrencias: Integer;

    /// <summary>
    ///   Retorna as categorias ordenadas por frequência
    ///   decrescente. Útil para a UI mostrar "seus pontos
    ///   fracos recorrentes".
    /// </summary>
    function CategoriasPorFrequencia: TArray<TVicio>;

    /// <summary>Notifica que o catálogo foi alterado (bump de versão).</summary>
    procedure MarcarAlterado;
  end;

implementation

// ────────────────────────────────────────────────────────────
// TVicio
// ────────────────────────────────────────────────────────────

constructor TVicio.Create;
begin
  inherited;
  FOrigem := ovGenerico;
  FPrecisaCrossCena := False;
  FFrequenciaNoManuscrito := 0;
  FExemplos := TObjectList<TExemploManuscrito>.Create;
end;

destructor TVicio.Destroy;
begin
  FExemplos.Free;
  inherited;
end;

procedure TVicio.RegistrarExemplo(const AExemplo: TExemploManuscrito);
begin
  if AExemplo = nil then
    raise EValorInvalido.Create('Exemplo não pode ser nil.');
  FExemplos.Add(AExemplo);
  Inc(FFrequenciaNoManuscrito);
end;

function TVicio.EhGenerico: Boolean;
begin
  Result := FOrigem = ovGenerico;
end;

function TVicio.Trechos: TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, FExemplos.Count);
  for I := 0 to FExemplos.Count - 1 do
    Result[I] := FExemplos[I].Trecho;
end;

// ────────────────────────────────────────────────────────────
// TCatalogoVicios
// ────────────────────────────────────────────────────────────

constructor TCatalogoVicios.Create;
begin
  inherited;
  FVersaoSchema := 1;
  FVersao := 1;
  FAtualizadoEm := Now;
  FCategorias := TObjectList<TVicio>.Create;
  FIndicePorID := TDictionary<string, TVicio>.Create;
end;

destructor TCatalogoVicios.Destroy;
begin
  FIndicePorID.Free;
  FCategorias.Free;
  inherited;
end;

procedure TCatalogoVicios.Adicionar(const AVicio: TVicio);
begin
  if AVicio = nil then
    raise EValorInvalido.Create('Vício não pode ser nil.');
  if AVicio.ID = '' then
    raise EValorInvalido.Create('Vício precisa ter ID.');
  if FIndicePorID.ContainsKey(AVicio.ID) then
    raise EOperacaoInvalida.CreateFmt(
      'Já existe vício com ID "%s" no catálogo.', [AVicio.ID]);

  FCategorias.Add(AVicio);
  FIndicePorID.Add(AVicio.ID, AVicio);
  MarcarAlterado;
end;

function TCatalogoVicios.Remover(const AID: string): Boolean;
var
  V: TVicio;
begin
  V := VicioPorID(AID);
  if not Assigned(V) then
    Exit(False);

  FIndicePorID.Remove(AID);
  FCategorias.Remove(V);  // TObjectList com OwnsObjects libera o objeto
  MarcarAlterado;
  Result := True;
end;

function TCatalogoVicios.VicioPorID(const AID: string): TVicio;
begin
  if not FIndicePorID.TryGetValue(AID, Result) then
    Result := nil;
end;

function TCatalogoVicios.Existe(const AID: string): Boolean;
begin
  Result := FIndicePorID.ContainsKey(AID);
end;

function TCatalogoVicios.RegistrarOcorrencia(const AVicioID: string;
  const AExemplo: TExemploManuscrito): Boolean;
var
  V: TVicio;
begin
  V := VicioPorID(AVicioID);
  if not Assigned(V) then
    Exit(False);

  V.RegistrarExemplo(AExemplo);
  MarcarAlterado;
  Result := True;
end;

function TCatalogoVicios.IDs: TArray<string>;
var
  I: Integer;
begin
  SetLength(Result, FCategorias.Count);
  for I := 0 to FCategorias.Count - 1 do
    Result[I] := FCategorias[I].ID;
end;

function TCatalogoVicios.TotalOcorrencias: Integer;
var
  V: TVicio;
begin
  Result := 0;
  for V in FCategorias do
    Inc(Result, V.FrequenciaNoManuscrito);
end;

function TCatalogoVicios.CategoriasPorFrequencia: TArray<TVicio>;
var
  Lista: TArray<TVicio>;
  I: Integer;
begin
  Lista := FCategorias.ToArray;
  TArray.Sort<TVicio>(Lista,
    TComparer<TVicio>.Construct(
      function(const A, B: TVicio): Integer
      begin
        Result := B.FrequenciaNoManuscrito - A.FrequenciaNoManuscrito;
      end));
  SetLength(Result, Length(Lista));
  for I := 0 to High(Lista) do
    Result[I] := Lista[I];
end;

procedure TCatalogoVicios.MarcarAlterado;
begin
  Inc(FVersao);
  FAtualizadoEm := Now;
end;

end.
