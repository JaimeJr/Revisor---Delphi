unit UTiposUI;

{
  UTiposUI.pas
  ─────────────────────────────────────────────────────────────
  Tipos de dados que circulam entre Presenter e View.

  São classes "burras" — só dados, sem lógica de negócio.
  Nenhuma delas conhece VCL, HTTP, JSON ou repositórios.

  Ownership:
    • O Presenter cria e libera.
    • A View consome durante a renderização.
    • O Presenter nunca libera enquanto a View ainda pode
      estar mostrando o objeto.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores;

type
  // ────────────────────────────────────────────────────────────
  // Árvore principal
  // ────────────────────────────────────────────────────────────

  TNoArvoreTipo = (naAto, naCapitulo, naCena);

  TNoArvoreUI = class
  public
    ID: TID;
    Tipo: TNoArvoreTipo;
    Nome: string;
    Filhos: TArray<TNoArvoreUI>;
    TemAnomalia: Boolean;
    Severidade: TSeveridadeAnomalia;
    constructor Create;
    destructor Destroy; override;
  end;

  // ────────────────────────────────────────────────────────────
  // Parágrafo na tela principal
  // ────────────────────────────────────────────────────────────

  TParagrafoUI = class
  public
    ParagrafoID: TID;
    Ordem: Integer;
    Texto: string;
    HashParagrafo: string;
    Status: TStatusParagrafo;
    VicioMarcado: string;   // vazio = nenhum
    NumChunks: Integer;
    function EhGrande: Boolean;
  end;

  // ────────────────────────────────────────────────────────────
  // Resumo do parse (barra de status)
  // ────────────────────────────────────────────────────────────

  TResumoUI = class
  public
    Atos: Integer;
    Capitulos: Integer;
    Cenas: Integer;
    Paragrafos: Integer;
    Palavras: Integer;
    Avisos: Integer;
    Erros: Integer;
    function TextoFormatado: string;
  end;

  // ────────────────────────────────────────────────────────────
  // Tela de revisão
  // ────────────────────────────────────────────────────────────

  TEdicaoUI = class
  public
    Chave: string;              // estável: paragrafo|chunk|vicio
    ParagrafoID: TID;
    ChunkIndex: Integer;
    VicioID: string;
    NomeVicio: string;          // resolvido do catálogo
    TextoAntigo: string;        // resolvido do Envio.JSON
    TextoSugerido: string;
    Motivo: string;
    DentroEscopo: Boolean;      // false → não pode ser aceita
    Selecionada: Boolean;
    Aplicada: Boolean;
  end;

  TRevisaoUI = class
  public
    CenaID: TID;
    Modo: TModoEnvio;
    IDChamada: string;
    StatusParse: TStatusParse;
    VicioGeral: string;
    ErroParse: string;
    RespostaBruta: string;
    TokensPrompt: Integer;
    TokensResposta: Integer;
    CustoEstimado: Double;
    Observacao: string;         // observação usada no reenvio, se houver
    Edicoes: TObjectList<TEdicaoUI>;

    constructor Create;
    destructor Destroy; override;

    function TemEdicoesAplicaveis: Boolean;
    function TotalAplicaveis: Integer;
  end;

  // ────────────────────────────────────────────────────────────
  // Catálogo de vícios
  // ────────────────────────────────────────────────────────────

  TVicioUI = class
  public
    ID: string;
    Nome: string;
    Origem: TOrigemVicio;
    Descricao: string;
    DicaCorrecao: string;
    GatilhoLocal: string;
    PrecisaCrossCena: Boolean;
    FrequenciaNoManuscrito: Integer;
    function EhGenerico: Boolean;
  end;

  TCenaUI = class
  public
    CenaID: TID;
    Numero: Integer;
    Paragrafos: TObjectList<TParagrafoUI>;
    constructor Create;
    destructor Destroy; override;
  end;

  TCapituloUI = class
  public
    CapituloID: TID;
    Numero: Integer;
    Titulo: string;
    Cenas: TObjectList<TCenaUI>;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TNoArvoreUI }

constructor TNoArvoreUI.Create;
begin
  inherited;
  TemAnomalia := False;
  Severidade := saInfo;
end;

destructor TNoArvoreUI.Destroy;
var
  Filho: TNoArvoreUI;
begin
  for Filho in Filhos do
    Filho.Free;
  inherited;
end;

{ TParagrafoUI }

function TParagrafoUI.EhGrande: Boolean;
begin
  Result := NumChunks > 1;
end;

{ TResumoUI }

function TResumoUI.TextoFormatado: string;
begin
  Result := Format(
    '%d atos, %d capítulos, %d cenas, %d parágrafos, %d palavras ' +
    '(%d avisos, %d erros)',
    [Atos, Capitulos, Cenas, Paragrafos, Palavras, Avisos, Erros]);
end;

{ TRevisaoUI }

constructor TRevisaoUI.Create;
begin
  inherited;
  Edicoes := TObjectList<TEdicaoUI>.Create;
  StatusParse := spOK;
end;

destructor TRevisaoUI.Destroy;
begin
  Edicoes.Free;
  inherited;
end;

function TRevisaoUI.TemEdicoesAplicaveis: Boolean;
begin
  Result := TotalAplicaveis > 0;
end;

function TRevisaoUI.TotalAplicaveis: Integer;
var
  E: TEdicaoUI;
begin
  Result := 0;
  for E in Edicoes do
    if E.DentroEscopo then
      Inc(Result);
end;

{ TVicioUI }

function TVicioUI.EhGenerico: Boolean;
begin
  Result := Origem = ovGenerico;
end;

{ TCenaUI }

constructor TCenaUI.Create;
begin
  inherited;
  Paragrafos := TObjectList<TParagrafoUI>.Create;
end;

destructor TCenaUI.Destroy;
begin
  Paragrafos.Free;
  inherited;
end;

constructor TCapituloUI.Create;
begin
  inherited;
  Cenas := TObjectList<TCenaUI>.Create;
end;

destructor TCapituloUI.Destroy;
begin
  Cenas.Free;
  inherited;
end;

end.
