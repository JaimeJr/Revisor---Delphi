unit UICacheChamadas;

{
  UICacheChamadas.pas
  ─────────────────────────────────────────────────────────────
  Cache de respostas por hash de payload. Evita reenvios
  idênticos à IA. Vive em memória na v1.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UEdicaoSugerida;

type
  ICacheChamadas = interface
    ['{A1B2C3D4-0012-4000-8000-000000000001}']

    /// <summary>
    ///   Guarda uma resposta associada ao hash do payload.
    /// </summary>
    procedure Guardar(const AHashPayload: string;
      const AResposta: TResposta);

    /// <summary>
    ///   Recupera a resposta em cache. Retorna nil se não houver.
    ///   A resposta retornada é uma cópia — o chamador é dono.
    /// </summary>
    function Recuperar(const AHashPayload: string): TResposta;

    /// <summary>True se existe entrada para esse hash.</summary>
    function Contem(const AHashPayload: string): Boolean;

    /// <summary>Remove uma entrada específica.</summary>
    procedure Invalidar(const AHashPayload: string);

    /// <summary>Limpa o cache inteiro.</summary>
    procedure Limpar;

    /// <summary>Total de entradas em cache.</summary>
    function TotalEntradas: Integer;
  end;

implementation

end.
