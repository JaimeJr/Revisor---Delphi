unit UINovoRepository;

{
  UINovoRepository.pas
  ─────────────────────────────────────────────────────────────
  Persistência do Novo.JSON — estado de trabalho.
  AutoSave a cada operação que mude o estado.

  Não é append-only: cada SalvarAuto sobrescreve o arquivo.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UManuscrito;

type
  INovoRepository = interface
    ['{E81EE46E-E83B-452C-AF1B-BE95CEF1F5B5}']

    /// <summary>Salva sobrescrevendo. Usado pelo AutoSave.</summary>
    procedure SalvarAuto(const AManuscrito: TManuscrito;
      const ACaminho: string);

    /// <summary>Carrega o Novo.JSON. Retorna nil se não existir.</summary>
    function Carregar(const ACaminho: string): TManuscrito;

    /// <summary>True se existe Novo.JSON no caminho.</summary>
    function Existe(const ACaminho: string): Boolean;

    /// <summary>Remove o Novo.JSON (ex: descartar sessão).</summary>
    procedure Apagar(const ACaminho: string);
  end;

implementation

end.
