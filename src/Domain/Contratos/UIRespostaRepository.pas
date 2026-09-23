unit UIRespostaRepository;

{
  UIRespostaRepository.pas
  ─────────────────────────────────────────────────────────────
  Log append-only das respostas da IA. Cada resposta aponta
  para uma chamada via IDChamada.

  Caminho passado em cada método — mesma convenção dos outros
  repositórios.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UEdicaoSugerida;

type
  IRespostaRepository = interface
    ['{5D59D812-0BE6-42F4-87DA-FEDC5B2B4362}']

    /// <summary>Anexa uma resposta ao log.</summary>
    procedure Append(const AResposta: TResposta; const ACaminho: string);

    /// <summary>
    ///   Busca a resposta mais recente de uma chamada. Retorna
    ///   nil se não existir.
    /// </summary>
    function BuscarPorChamada(const AIDChamada,
      ACaminho: string): TResposta;

    /// <summary>
    ///   Todas as respostas de uma chamada (reenvios geram
    ///   múltiplas). Ordem cronológica crescente.
    /// </summary>
    function TodasDaChamada(const AIDChamada,
      ACaminho: string): TArray<TResposta>;

    /// <summary>Total de respostas registradas.</summary>
    function TotalRespostas(const ACaminho: string): Integer;

    /// <summary>Soma do custo acumulado de todas as respostas.</summary>
    function CustoAcumulado(const ACaminho: string): Double;
  end;

implementation

end.
