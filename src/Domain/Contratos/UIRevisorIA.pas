unit UIRevisorIA;

{
  UIRevisorIA.pas
  ─────────────────────────────────────────────────────────────
  Contrato do revisor IA.

  Revisado em relação à Fase 2: apenas o método síncrono
  Revisar. A decisão de UX é usar tela de loading modal em
  vez de thread + callbacks — o usuário não tem nada a fazer
  enquanto a chamada está em voo, então bloquear é aceitável.

  O revisor:
    • Anexa a chamada ao Envio.JSON (atribui IDChamada).
    • Consulta cache; se houver hit, devolve cópia e NÃO
      chama a API.
    • Monta o payload via IPromptFactory.
    • Chama a API DeepSeek.
    • Parseia a resposta com fallback para parse_error.
    • Anexa a resposta ao Resposta.JSON.
    • Guarda no cache.
    • Devolve a TResposta (ownership transferido ao chamador).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UChamada,
  UEdicaoSugerida;

type
  IRevisorIA = interface
    ['{8587D6B6-F9B4-4C16-A93B-956E0D1731F6}']

    /// <summary>
    ///   Executa a revisão. Bloqueia a thread chamadora até a
    ///   resposta chegar ou o timeout estourar.
    /// </summary>
    /// <remarks>
    ///   A TChamada NÃO tem ownership transferido — o chamador
    ///   continua dono. A TResposta devolvida SIM — quem chama
    ///   é responsável por liberar.
    /// </remarks>
    function Revisar(const AChamada: TChamada): TResposta;
  end;

implementation

end.
