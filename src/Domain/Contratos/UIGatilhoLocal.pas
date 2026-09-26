unit UIGatilhoLocal;

{
  UIGatilhoLocal.pas
  ─────────────────────────────────────────────────────────────
  Contrato de gatilho local e do registro central.

  Nesta versão:
    • IGatilhoRegistry ganha GatilhoPorVicio, para permitir
      que o UseCase acesse um gatilho individual e decida se
      precisa reexecutá-lo.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UManuscrito;

type
  TContextoGlobal = class
  private
    FManuscrito: TManuscrito;
  public
    constructor Create(const AManuscrito: TManuscrito);
    property Manuscrito: TManuscrito read FManuscrito;
  end;

  TGatilhoResultado = record
    VicioID: string;
    Disparou: Boolean;
    Confianca: Double;
    Trechos: TArray<string>;
  end;

  IGatilhoLocal = interface
    ['{220E73FD-7C3F-4F01-A68D-F80B15914F89}']
    function VicioID: string;
    function PrecisaContexto: Boolean;
    function Avaliar(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TGatilhoResultado;
  end;

  IGatilhoRegistry = interface
    ['{744E6834-3DEB-4468-BE38-D1DD858ED1B8}']
    procedure Registrar(const AGatilho: IGatilhoLocal);

    function AvaliarTodos(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TArray<TGatilhoResultado>;

    function ViciosCobertos: TArray<string>;
    function TemGatilhoPara(const AVicioID: string): Boolean;

    /// <summary>
    ///   Devolve o gatilho registrado para o VicioID indicado,
    ///   ou nil se não houver.
    /// </summary>
    function GatilhoPorVicio(const AVicioID: string): IGatilhoLocal;
  end;

implementation

constructor TContextoGlobal.Create(const AManuscrito: TManuscrito);
begin
  inherited Create;
  FManuscrito := AManuscrito;
end;

end.
