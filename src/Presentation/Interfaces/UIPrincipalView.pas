unit UIPrincipalView;

{
  UIPrincipalView.pas
  ─────────────────────────────────────────────────────────────
  Contrato da tela principal.

  Modelo:
    • Árvore: Ato > Capítulo > Cena.
    • Clicar em CENA carrega a cena no painel direito.
    • Clicar em CAPÍTULO ou ATO não faz nada no painel.
    • Painel direito: 1 checkbox + texto + status por parágrafo.
    • Botões "Marcar todos" / "Desmarcar todos" na cena em foco.
    • Combo de vício no rodapé (aplica a todos os marcados).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UTiposUI,
  UValores;

type
  TProcCenaID = procedure(const ACenaID: TID) of object;
  TProcParagrafoMarcado = procedure(const AParagrafoID: TID;
    const AMarcado: Boolean) of object;
  TProcSimplesPrincipal = procedure of object;

  IPrincipalView = interface
    ['{598676F6-75E1-4B1D-8718-0E93320BFB3F}']

    // ─── Consultas ───
    function CenaSelecionadaID: TID;
    function ParagrafosSelecionadosIDs: TArray<TID>;
    function VicioSelecionado: string;
    function ModoSelecionado: TModoEnvio;

    // ─── Renderização ───
    procedure ExibirArvore(const ARaiz: TArray<TNoArvoreUI>);
    procedure LimparArvore;
    procedure ExibirCena(const ACena: TCenaUI; const ATitulo: string);
    procedure LimparCena;
    procedure PopularComboVicios(const AVicios: TArray<string>);

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

    function GetAoMarcarParagrafo: TProcParagrafoMarcado;
    procedure SetAoMarcarParagrafo(const Value: TProcParagrafoMarcado);
    property AoMarcarParagrafo: TProcParagrafoMarcado
      read GetAoMarcarParagrafo write SetAoMarcarParagrafo;

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

    function GetAoMarcarSuspeitos: TProcSimplesPrincipal;
    procedure SetAoMarcarSuspeitos(const Value: TProcSimplesPrincipal);
    property AoMarcarSuspeitos: TProcSimplesPrincipal
      read GetAoMarcarSuspeitos write SetAoMarcarSuspeitos;

    function TotalSuspeitosNaCena: Integer;
    procedure MarcarSuspeitos;
  end;

implementation

end.
