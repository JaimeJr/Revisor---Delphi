unit UIConstrutorPrompt;

{
  UIConstrutorPrompt.pas
  ─────────────────────────────────────────────────────────────
  Contrato dos construtores de prompt. Cada modo (cirúrgico,
  varredura) tem sua estratégia. A versão do prompt entra na
  chave de cache do payload.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UChamada,
  UValores,
  UVicio;

type
  TPayload = record
    System: string;
    User: string;
    Modelo: string;
    Temperature: Double;
    MaxTokens: Integer;
    ResponseFormat: string;
    Versao: string;
  end;

  IConstrutorPrompt = interface
    ['{A1B2C3D4-0011-4000-8000-000000000001}']

    /// <summary>Versão deste template (ex: "v1", "v2").</summary>
    function Versao: string;

    /// <summary>
    ///   Monta o payload completo a partir da chamada e do
    ///   catálogo de vícios (para injetar dicas de correção).
    /// </summary>
    function Montar(const AChamada: TChamada;
      const ACatalogo: TCatalogoVicios): TPayload;
  end;

  /// <summary>
  ///   Fábrica de construtores. O UseCase pede por modo e
  ///   recebe o construtor correto.
  /// </summary>
  IPromptFactory = interface
    ['{C9478222-F71B-4EF5-BFA8-BF1A1EB48B46}']
    function ParaModo(const AModo: TModoEnvio): IConstrutorPrompt;
  end;

implementation

end.
