unit UTiposUI;

{
  UTiposUI.pas
  ─────────────────────────────────────────────────────────────
  Tipos de dados que circulam entre Presenter e View.

  Nesta versão:
    • TDisparoUI — resumo de um disparo de gatilho para a View.
    • TParagrafoUI ganha Disparos[].
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores;

type
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

  TDisparoUI = class
  public
    GatilhoID: string;
    Confianca: Double;
    Trechos: TArray<string>;
  end;

  TParagrafoUI = class
  public
    ParagrafoID: TID;
    Ordem: Integer;
    Texto: string;
    HashParagrafo: string;
    Status: TStatusParagrafo;
    VicioMarcado: string;
    NumChunks: Integer;
    Disparos: TObjectList<TDisparoUI>;

    constructor Create;
    destructor Destroy; override;

    function EhGrande: Boolean;
    function TemDisparo: Boolean;
    function ResumoDisparos: string;
  end;

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

  TEdicaoUI = class
  public
    Chave: string;
    ParagrafoID: TID;
    ChunkIndex: Integer;
    VicioID: string;
    NomeVicio: string;
    TextoAntigo: string;
    TextoSugerido: string;
    Motivo: string;
    DentroEscopo: Boolean;
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
    Observacao: string;
    Edicoes: TObjectList<TEdicaoUI>;

    constructor Create;
    destructor Destroy; override;

    function TemEdicoesAplicaveis: Boolean;
    function TotalAplicaveis: Integer;
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

constructor TParagrafoUI.Create;
begin
  inherited;
  Disparos := TObjectList<TDisparoUI>.Create;
end;

destructor TParagrafoUI.Destroy;
begin
  Disparos.Free;
  inherited;
end;

function TParagrafoUI.EhGrande: Boolean;
begin
  Result := NumChunks > 1;
end;

function TParagrafoUI.TemDisparo: Boolean;
begin
  Result := Disparos.Count > 0;
end;

function TParagrafoUI.ResumoDisparos: string;
var
  D: TDisparoUI;
  Lista: TStringBuilder;
begin
  Lista := TStringBuilder.Create;
  try
    for D in Disparos do
    begin
      if Lista.Length > 0 then
        Lista.Append(', ');
      Lista.Append(D.GatilhoID);
    end;
    Result := Lista.ToString;
  finally
    Lista.Free;
  end;
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

{ TCapituloUI }

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

{ TVicioUI }

function TVicioUI.EhGenerico: Boolean;
begin
  Result := Origem = ovGenerico;
end;

end.
