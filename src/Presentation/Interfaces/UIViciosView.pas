unit UIViciosView;

interface

uses
  System.SysUtils,
  UTiposUI,
  UValores;

type
  // ─── Tipos de eventos específicos desta View ───

  TProcVicioID = procedure(const AID: string) of object;

  TProcSalvarVicio = procedure(const AID, ANome, ADescricao,
    ADica, AGatilho: string; const APrecisaCrossCena: Boolean) of object;

  TProcSimplesVicios = procedure of object;

  IUViciosView = interface
    ['{65587A37-501B-4647-B666-202D235051DD}']

    // ════════════════════════════════════════════════════════
    //  RENDERIZAÇÃO
    // ════════════════════════════════════════════════════════

    /// <summary>Exibe a lista de vícios. A View assume os TVicioUI.</summary>
    procedure ExibirCatalogo(const AVicios: TArray<TVicioUI>);

    /// <summary>
    ///   Preenche o formulário com os dados do vício selecionado.
    ///   AVicio pode ser nil — só limpa.
    /// </summary>
    procedure ExibirDetalhe(const AVicio: TVicioUI);

    /// <summary>
    ///   Limpa o formulário e entra em modo "novo vício"
    ///   (ID editável, sem nada selecionado na lista).
    /// </summary>
    procedure EntrarModoNovo;

    /// <summary>Marca o vício indicado como selecionado na lista.</summary>
    procedure SelecionarNaLista(const AID: string);

    // ─── Habilitar / desabilitar ───
    procedure HabilitarRemover(const AHabilitado: Boolean;
      const AMotivo: string);
    procedure HabilitarSalvar(const AHabilitado: Boolean);
    procedure HabilitarIDEditavel(const AEditavel: Boolean);

    // ════════════════════════════════════════════════════════
    //  DIÁLOGOS E CICLO DE VIDA
    // ════════════════════════════════════════════════════════

    procedure ExibirErro(const AMensagem: string);
    procedure ExibirInfo(const AMensagem: string);
    function Confirmar(const AMensagem: string): Boolean;

    procedure MostrarProgresso(const AMensagem: string);
    procedure OcultarProgresso;
    procedure FecharTela;

    // ════════════════════════════════════════════════════════
    //  CONSULTAS DO FORMULÁRIO
    // ════════════════════════════════════════════════════════

    function IDEmEdicao: string;
    function NomeEmEdicao: string;
    function DescricaoEmEdicao: string;
    function DicaEmEdicao: string;
    function GatilhoEmEdicao: string;
    function CrossCenaEmEdicao: Boolean;

    // ════════════════════════════════════════════════════════
    //  EVENTOS
    // ════════════════════════════════════════════════════════

    function GetAoSelecionarVicio: TProcVicioID;
    procedure SetAoSelecionarVicio(const Value: TProcVicioID);
    property AoSelecionarVicio: TProcVicioID
      read GetAoSelecionarVicio write SetAoSelecionarVicio;

    function GetAoNovoVicio: TProcSimplesVicios;
    procedure SetAoNovoVicio(const Value: TProcSimplesVicios);
    property AoNovoVicio: TProcSimplesVicios
      read GetAoNovoVicio write SetAoNovoVicio;

    function GetAoSalvarVicio: TProcSalvarVicio;
    procedure SetAoSalvarVicio(const Value: TProcSalvarVicio);
    property AoSalvarVicio: TProcSalvarVicio
      read GetAoSalvarVicio write SetAoSalvarVicio;

    function GetAoRemoverVicio: TProcVicioID;
    procedure SetAoRemoverVicio(const Value: TProcVicioID);
    property AoRemoverVicio: TProcVicioID
      read GetAoRemoverVicio write SetAoRemoverVicio;

    function GetAoFechar: TProcSimplesVicios;
    procedure SetAoFechar(const Value: TProcSimplesVicios);
    property AoFechar: TProcSimplesVicios
      read GetAoFechar write SetAoFechar;
  end;

implementation

end.
