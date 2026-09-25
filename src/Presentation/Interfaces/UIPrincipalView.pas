unit UIPrincipalView;

{
  UIPrincipalView.pas
  ─────────────────────────────────────────────────────────────
  Contrato da tela principal.

  Seleção é feita exclusivamente na árvore (Ato > Capítulo >
  Cena). Não há checkbox por parágrafo. O painel direito só
  exibe o capítulo — um TMemo por cena.

  Eventos:
    • AoSelecionarCena  → usuário clicou na árvore
    • AoSelecionarVicio → usuário trocou o combo
    • AoRevisar         → revisa a cena selecionada
    • AoMarcarRevisados → marca/desmarca os parágrafos da cena
    • AoClicarDesfazer, AoImportar, AoExportar, AoAbrirVicios,
      AoFechar
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UTiposUI,
  UValores;

type
  TProcCenaID = procedure(const ACenaID: TID) of object;
  TProcSimplesPrincipal = procedure of object;

  IPrincipalView = interface
    ['{A1B2C3D4-0020-4000-8000-000000000001}']

    // ─── Consultas ───
    function CenaSelecionadaID: TID;
    function VicioSelecionado: string;
    function ModoSelecionado: TModoEnvio;

    // ─── Renderização ───
    procedure ExibirArvore(const ARaiz: TArray<TNoArvoreUI>);
    procedure LimparArvore;
    procedure ExibirCapitulo(const ACapitulo: TCapituloUI);
    procedure LimparCapitulo;

    procedure AtualizarTitulo(const ATitulo: string);
    procedure AtualizarResumo(const AResumo: TResumoUI);
    procedure AtualizarBarraStatus(const ATexto: string);
    procedure AtualizarCustoAcumulado(const ATexto: string);

    // ─── Habilitar/desabilitar ───
    procedure HabilitarImportar(const AHabilitado: Boolean);
    procedure HabilitarRevisar(const AHabilitado: Boolean);
    procedure HabilitarVarredura(const AHabilitado: Boolean);
    procedure HabilitarExportar(const AHabilitado: Boolean);
    procedure HabilitarMarcarRevisados(const AHabilitado: Boolean);
    procedure HabilitarDesfazer(const AHabilitado: Boolean;
      const ADescricao: string);

    // ─── Diálogos e ciclo de vida ───
    function PerguntarCaminhoDocx: string;
    function PerguntarCaminhoSaidaDocx(const ASugestao: string): string;
    procedure ExibirErro(const AMensagem: string);
    procedure ExibirInfo(const AMensagem: string);
    procedure ExibirAviso(const AMensagem: string);
    function Confirmar(const AMensagem: string): Boolean;

    procedure MostrarProgresso(const AMensagem: string);
    procedure OcultarProgresso;
    procedure FecharAplicacao;

    // ─── Eventos ───
    function GetAoImportar: TProcSimplesPrincipal;
    procedure SetAoImportar(const Value: TProcSimplesPrincipal);
    property AoImportar: TProcSimplesPrincipal
      read GetAoImportar write SetAoImportar;

    function GetAoExportar: TProcSimplesPrincipal;
    procedure SetAoExportar(const Value: TProcSimplesPrincipal);
    property AoExportar: TProcSimplesPrincipal
      read GetAoExportar write SetAoExportar;

    function GetAoAbrirVicios: TProcSimplesPrincipal;
    procedure SetAoAbrirVicios(const Value: TProcSimplesPrincipal);
    property AoAbrirVicios: TProcSimplesPrincipal
      read GetAoAbrirVicios write SetAoAbrirVicios;

    function GetAoSelecionarCena: TProcCenaID;
    procedure SetAoSelecionarCena(const Value: TProcCenaID);
    property AoSelecionarCena: TProcCenaID
      read GetAoSelecionarCena write SetAoSelecionarCena;

    function GetAoSelecionarVicio: TProcSimplesPrincipal;
    procedure SetAoSelecionarVicio(const Value: TProcSimplesPrincipal);
    property AoSelecionarVicio: TProcSimplesPrincipal
      read GetAoSelecionarVicio write SetAoSelecionarVicio;

    function GetAoRevisar: TProcSimplesPrincipal;
    procedure SetAoRevisar(const Value: TProcSimplesPrincipal);
    property AoRevisar: TProcSimplesPrincipal
      read GetAoRevisar write SetAoRevisar;

    function GetAoMarcarRevisados: TProcSimplesPrincipal;
    procedure SetAoMarcarRevisados(const Value: TProcSimplesPrincipal);
    property AoMarcarRevisados: TProcSimplesPrincipal
      read GetAoMarcarRevisados write SetAoMarcarRevisados;

    function GetAoClicarDesfazer: TProcSimplesPrincipal;
    procedure SetAoClicarDesfazer(const Value: TProcSimplesPrincipal);
    property AoClicarDesfazer: TProcSimplesPrincipal
      read GetAoClicarDesfazer write SetAoClicarDesfazer;

    function GetAoFechar: TProcSimplesPrincipal;
    procedure SetAoFechar(const Value: TProcSimplesPrincipal);
    property AoFechar: TProcSimplesPrincipal
      read GetAoFechar write SetAoFechar;
  end;

implementation

end.
