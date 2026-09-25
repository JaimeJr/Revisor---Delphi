unit UIParserManuscrito;

{
  UIParserManuscrito.pas
  ─────────────────────────────────────────────────────────────
  Contrato do parser de manuscrito + agregado TParseResultado.

  TParseResultado encapsula Manuscrito + Log. Ownership:

    • Criado pelo parser, com posse do Manuscrito e do Log.
    • Destroy libera ambos automaticamente.
    • DetachManuscrito / DetachLog permitem ao chamador
      "roubar" um dos dois sem que sejam liberados pelo
      TParseResultado.

  Isso é usado pelo Presenter principal, que desanexa
  Manuscrito e Log do TImportacao logo após importar, para
  mantê-los vivos durante toda a sessão sem depender do
  ciclo de vida do TImportacao.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UManuscrito,
  UAnomaliaParse;

type
  /// <summary>
  ///   Resultado completo do parse: o manuscrito extraído e o
  ///   log de anomalias. Sempre os dois — o log pode estar limpo.
  /// </summary>
  TParseResultado = class
  private
    FManuscrito: TManuscrito;
    FLog: TParseLog;
  public
    constructor Create(const AManuscrito: TManuscrito;
      const ALog: TParseLog);
    destructor Destroy; override;

    property Manuscrito: TManuscrito read FManuscrito;
    property Log: TParseLog read FLog;

    /// <summary>
    ///   Devolve o Manuscrito e o remove do ownership interno.
    ///   Após esta chamada, TParseResultado.Destroy não o libera
    ///   mais. Quem chamar assume a responsabilidade.
    ///   Retorna nil se já foi desanexado antes.
    /// </summary>
    function DetachManuscrito: TManuscrito;

    /// <summary>
    ///   Devolve o Log e o remove do ownership interno.
    ///   Após esta chamada, TParseResultado.Destroy não o libera
    ///   mais. Quem chamar assume a responsabilidade.
    ///   Retorna nil se já foi desanexado antes.
    /// </summary>
    function DetachLog: TParseLog;
  end;

  /// <summary>
  ///   Parser de manuscrito. Uma implementação por biblioteca
  ///   de leitura (.docx via OfficeXML4D, fake para testes, etc.).
  /// </summary>
  IParserManuscrito = interface
    ['{A1B2C3D4-0001-4000-8000-000000000001}']

    /// <summary>
    ///   Lê o arquivo e devolve o manuscrito + log.
    ///   Lança exceção apenas em falhas fatais (arquivo não
    ///   encontrado, formato inválido, .docx corrompido).
    /// </summary>
    function Parsear(const ACaminho: string): TParseResultado;
  end;

implementation

{ TParseResultado }

constructor TParseResultado.Create(const AManuscrito: TManuscrito;
  const ALog: TParseLog);
begin
  inherited Create;
  FManuscrito := AManuscrito;
  FLog := ALog;
end;

destructor TParseResultado.Destroy;
begin
  // FManuscrito e FLog podem ser nil se já foram desanexados.
  // TObject.Free aceita nil — nada a proteger.
  FManuscrito.Free;
  FLog.Free;
  inherited;
end;

function TParseResultado.DetachManuscrito: TManuscrito;
begin
  Result := FManuscrito;
  FManuscrito := nil;
end;

function TParseResultado.DetachLog: TParseLog;
begin
  Result := FLog;
  FLog := nil;
end;

end.
