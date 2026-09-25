unit UGatilhoLocal;

{
  UIGatilhoLocal.pas
  ─────────────────────────────────────────────────────────────
  Contrato de gatilho local e do registro central de gatilhos.

  Revisão em relação à Fase 2: TGatilhoResultado agora carrega
  VicioID. Sem isso, AvaliarTodos devolveria resultados órfãos
  — o chamador não saberia a qual vício cada um pertence.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UManuscrito;

type
  /// <summary>
  ///   Contexto global do manuscrito, disponível para gatilhos
  ///   que precisam comparar entre cenas.
  /// </summary>
  TContextoGlobal = class
  private
    FManuscrito: TManuscrito;
  public
    constructor Create(const AManuscrito: TManuscrito);
    property Manuscrito: TManuscrito read FManuscrito;
  end;

  /// <summary>
  ///   Resultado da avaliação de um gatilho sobre um parágrafo.
  ///   Carrega o VicioID do gatilho que o produziu — sem isso,
  ///   o array de resultados seria ambíguo.
  /// </summary>
  TGatilhoResultado = record
    VicioID: string;
    Disparou: Boolean;
    Confianca: Double;      // 0.0 a 1.0
    Trechos: TArray<string>;
  end;

  IGatilhoLocal = interface
    ['{A1B2C3D4-0010-4000-8000-000000000001}']

    /// <summary>ID do vício que este gatilho detecta.</summary>
    function VicioID: string;

    /// <summary>
    ///   True se o gatilho precisa de TContextoGlobal para
    ///   funcionar (ex: padrão descritivo repetido).
    /// </summary>
    function PrecisaContexto: Boolean;

    /// <summary>
    ///   Avalia o parágrafo. Sempre chamado com contexto não-nil
    ///   quando PrecisaContexto = True.
    /// </summary>
    function Avaliar(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TGatilhoResultado;
  end;

  IGatilhoRegistry = interface
    ['{C0EC88AE-784F-4F5C-88A1-49C64C215594}']

    /// <summary>
    ///   Registra um gatilho. Se já existir um gatilho com o
    ///   mesmo VicioID, o novo é ignorado (primeiro ganha).
    /// </summary>
    procedure Registrar(const AGatilho: IGatilhoLocal);

    /// <summary>
    ///   Avalia todos os gatilhos sobre um parágrafo. Retorna
    ///   apenas os que dispararam, ordenados por confiança
    ///   decrescente.
    /// </summary>
    function AvaliarTodos(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TArray<TGatilhoResultado>;

    /// <summary>IDs de vícios cobertos por pelo menos um gatilho.</summary>
    function ViciosCobertos: TArray<string>;

    /// <summary>True se há gatilho registrado para esse vício.</summary>
    function TemGatilhoPara(const AVicioID: string): Boolean;
  end;

implementation

constructor TContextoGlobal.Create(const AManuscrito: TManuscrito);
begin
  inherited Create;
  FManuscrito := AManuscrito;
end;

end.
