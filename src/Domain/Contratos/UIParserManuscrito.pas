unit UIParserManuscrito;

{
  UIParserManuscrito.pas
  ─────────────────────────────────────────────────────────────
  Contrato do parser de manuscrito. Lê um .docx e devolve o
  manuscrito estruturado + o log de anomalias detectadas.

  Decisão: o parser NUNCA falha. Ele processa o que consegue e
  registra anomalias tipadas em TParseLog. Erros fatais (arquivo
  inexistente, .docx corrompido) são a única exceção.
  ─────────────────────────────────────────────────────────────
}

interface

uses
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
  end;

  /// <summary>
  ///   Parser de manuscrito. Uma implementação por biblioteca
  ///   de leitura (.docx via OfficeXML4D, fake para testes, etc.).
  /// </summary>
  IParserManuscrito = interface
    ['{0787E190-4655-45AB-A793-59FA4D7430B0}']

    /// <summary>
    ///   Lê o arquivo e devolve o manuscrito + log.
    ///   Lança exceção apenas em falhas fatais (arquivo não
    ///   encontrado, formato inválido, .docx corrompido).
    /// </summary>
    function Parsear(const ACaminho: string): TParseResultado;
  end;

implementation

constructor TParseResultado.Create(const AManuscrito: TManuscrito;
  const ALog: TParseLog);
begin
  inherited Create;
  FManuscrito := AManuscrito;
  FLog := ALog;
end;

destructor TParseResultado.Destroy;
begin
  FManuscrito.Free;
  FLog.Free;
  inherited;
end;

end.
