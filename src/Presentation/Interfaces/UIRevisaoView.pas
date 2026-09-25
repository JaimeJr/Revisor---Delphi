unit UIRevisaoView;

interface

uses
  System.SysUtils,
  UTiposUI,
  UValores;

type
  // ─── Tipos de eventos específicos desta View ───

  TProcEdicaoMarcada = procedure(const AChave: string;
    const AMarcada: Boolean) of object;

  TProcParagrafoMarcado = procedure(const AParagrafoID: TID;
    const AMarcada: Boolean) of object;

  TProcSelecionarEdicao = procedure(const AChave: string) of object;

  TProcSimples = procedure of object;

  TProcNotificacao = procedure of object;

  /// <summary>Contrato da tela de revisão.</summary>
  IRevisaoView = interface
    ['{B4E9F740-48D4-446E-943C-FB4D6B4E279D}']
    // ════════════════════════════════════════════════════════
    //  RENDERIZAÇÃO
    // ════════════════════════════════════════════════════════

    /// <summary>
    ///   Preenche toda a tela com o resultado da revisão.
    ///   Não libera ARevisao — o Presenter é dono.
    /// </summary>
    procedure ExibirRevisao(const ARevisao: TRevisaoUI);

    /// <summary>Mostra o texto antigo e o sugerido nos memos.</summary>
    procedure ExibirTextosDoParagrafo(const ATextoAntigo,
      ATextoNovo: string);

    /// <summary>Atualiza o estado visual de uma edição (checkbox).</summary>
    procedure AtualizarEdicaoMarcada(const AChave: string;
      const AMarcada: Boolean);

    /// <summary>Exibe a resposta bruta (usado em parse_error).</summary>
    procedure ExibirRespostaBruta(const ATexto: string);

    procedure AtualizarTitulo(const ACenaID: TID; const AModo: TModoEnvio);
    procedure AtualizarRodape(const ATokens: Integer; const ACusto: Double);
    procedure AtualizarStatusParse(const AStatus: TStatusParse;
      const AMensagem: string);

    // ─── Habilitar / desabilitar botões ───
    procedure HabilitarAceitarSelecionadas(const AHabilitado: Boolean);
    procedure HabilitarAceitarTudo(const AHabilitado: Boolean);
    procedure HabilitarRecusarTudo(const AHabilitado: Boolean);
    procedure HabilitarReenviar(const AHabilitado: Boolean);
    procedure HabilitarExibirRespostaBruta(const AHabilitado: Boolean);

    // ════════════════════════════════════════════════════════
    //  DIÁLOGOS E CICLO DE VIDA
    // ════════════════════════════════════════════════════════

    procedure ExibirErro(const AMensagem: string);
    procedure ExibirInfo(const AMensagem: string);
    function Confirmar(const AMensagem: string): Boolean;

    procedure MostrarProgresso(const AMensagem: string);
    procedure OcultarProgresso;
    procedure FecharTela;
    procedure SetOnClose(const AOnClose: TProcNotificacao);

    // ════════════════════════════════════════════════════════
    //  CONSULTAS
    // ════════════════════════════════════════════════════════

    /// <summary>Chaves das edições marcadas para aceite.</summary>
    function EdicoesSelecionadas: TArray<string>;

    // ════════════════════════════════════════════════════════
    //  EVENTOS
    // ════════════════════════════════════════════════════════

    function GetAoMarcarEdicao: TProcEdicaoMarcada;
    procedure SetAoMarcarEdicao(const Value: TProcEdicaoMarcada);
    property AoMarcarEdicao: TProcEdicaoMarcada
      read GetAoMarcarEdicao write SetAoMarcarEdicao;

    function GetAoMarcarParagrafo: TProcParagrafoMarcado;
    procedure SetAoMarcarParagrafo(const Value: TProcParagrafoMarcado);
    property AoMarcarParagrafo: TProcParagrafoMarcado
      read GetAoMarcarParagrafo write SetAoMarcarParagrafo;

    function GetAoSelecionarEdicao: TProcSelecionarEdicao;
    procedure SetAoSelecionarEdicao(const Value: TProcSelecionarEdicao);
    property AoSelecionarEdicao: TProcSelecionarEdicao
      read GetAoSelecionarEdicao write SetAoSelecionarEdicao;

    function GetAoAceitarSelecionadas: TProcSimples;
    procedure SetAoAceitarSelecionadas(const Value: TProcSimples);
    property AoAceitarSelecionadas: TProcSimples
      read GetAoAceitarSelecionadas write SetAoAceitarSelecionadas;

    function GetAoAceitarTudo: TProcSimples;
    procedure SetAoAceitarTudo(const Value: TProcSimples);
    property AoAceitarTudo: TProcSimples
      read GetAoAceitarTudo write SetAoAceitarTudo;

    function GetAoRecusarTudo: TProcSimples;
    procedure SetAoRecusarTudo(const Value: TProcSimples);
    property AoRecusarTudo: TProcSimples
      read GetAoRecusarTudo write SetAoRecusarTudo;

    function GetAoReenviar: TProcSimples;
    procedure SetAoReenviar(const Value: TProcSimples);
    property AoReenviar: TProcSimples
      read GetAoReenviar write SetAoReenviar;
  end;

implementation

end.
