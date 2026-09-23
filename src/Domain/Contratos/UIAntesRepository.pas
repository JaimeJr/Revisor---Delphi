unit UIAntesRepository;

{
  UIAntesRepository.pas
  ─────────────────────────────────────────────────────────────
  Persistência do Antes.JSON — fonte da verdade imutável.
  Depois de gravado, nunca é sobrescrito pela aplicação.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UManuscrito,
  UAnomaliaParse;

type
  IAntesRepository = interface
    ['{2883AC2D-B6B3-4107-BFC6-73B1CDB73602}']

    /// <summary>Grava o Antes.JSON no caminho indicado.</summary>
    procedure Salvar(const AManuscrito: TManuscrito;
      const ACaminho: string);

    /// <summary>Carrega um Antes.JSON existente.</summary>
    function Carregar(const ACaminho: string): TManuscrito;

    /// <summary>True se já existe um Antes.JSON válido no caminho.</summary>
    function Existe(const ACaminho: string): Boolean;

    /// <summary>
    ///   Grava o parse.log ao lado do Antes.JSON.
    ///   Arquivo separado, mesmo diretório.
    /// </summary>
    procedure SalvarLog(const ALog: TParseLog; const ACaminhoAntes: string);

    /// <summary>Carrega o parse.log associado.</summary>
    function CarregarLog(const ACaminhoAntes: string): TParseLog;
  end;

implementation

end.
