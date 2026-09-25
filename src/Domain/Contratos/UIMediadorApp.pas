unit UIMediadorApp;

interface

uses
  System.SysUtils,
  UManuscrito,
  UEdicaoSugerida,
  UTiposUI,
  UValores;

type
  /// <summary>
  ///   Contexto que a frmRevisao precisa para operar:
  ///   o manuscrito em memória, caminhos e a resposta da IA.
  /// </summary>
  TContextoRevisao = class
  private
    FManuscrito: TManuscrito;
    FResposta: TResposta;
    FCaminhoNovo: string;
    FCaminhoVicios: string;
    FCenaID: TID;
    FModo: TModoEnvio;
    FIDChamada: string;
    FOwnedManuscrito: Boolean;
  public
    constructor Create(const AManuscrito: TManuscrito;
      const AResposta: TResposta;
      const ACaminhoNovo, ACaminhoVicios: string;
      const ACenaID: TID; const AModo: TModoEnvio;
      const AIDChamada: string;
      const AOwnedManuscrito: Boolean = False);
    destructor Destroy; override;

    procedure SubstituirResposta(const ANova: TResposta);
    property Manuscrito: TManuscrito read FManuscrito;
    property Resposta: TResposta read FResposta;
    property CaminhoNovo: string read FCaminhoNovo;
    property CaminhoVicios: string read FCaminhoVicios;
    property CenaID: TID read FCenaID;
    property Modo: TModoEnvio read FModo;
    property IDChamada: string read FIDChamada;
  end;

  /// <summary>
  ///   Callback que o Mediador invoca quando a frmRevisao fecha,
  ///   para o Presenter principal atualizar a tela.
  /// </summary>
  TProcRevisaoFechada = reference to procedure;

  IMediadorApp = interface
    ['{67797E9B-9F9B-42AD-8C81-4140880E7936}']

    /// <summary>
    ///   Abre a frmRevisao com o contexto. O Mediador assume o
    ///   ownership do AContexto e o libera quando a tela fechar.
    ///   AOnFechada é chamada depois do fechamento.
    /// </summary>
    procedure AbrirRevisao(const AContexto: TContextoRevisao;
      const AOnFechada: TProcRevisaoFechada);

    /// <summary>
    ///   Abre a frmVicios. O Presenter principal repassa o
    ///   caminho do Vicios.JSON via contexto.
    /// </summary>
    procedure AbrirVicios(const ACaminhoVicios: string;
      const AOnFechada: TProcRevisaoFechada);

    /// <summary>
    ///   Abre a frmReenvio e devolve a observação digitada
    ///   (ou '' se o usuário cancelou).
    /// </summary>
    function PerguntarObservacaoReenvio: string;
    procedure ExecutarComLoading(const AMensagem: string;
      const AOperacao: TProc);
  end;

implementation

{ TContextoRevisao }

constructor TContextoRevisao.Create(const AManuscrito: TManuscrito;
  const AResposta: TResposta;
  const ACaminhoNovo, ACaminhoVicios: string;
  const ACenaID: TID; const AModo: TModoEnvio;
  const AIDChamada: string;
  const AOwnedManuscrito: Boolean);
begin
  inherited Create;
  FManuscrito := AManuscrito;
  FResposta := AResposta;
  FCaminhoNovo := ACaminhoNovo;
  FCaminhoVicios := ACaminhoVicios;
  FCenaID := ACenaID;
  FModo := AModo;
  FIDChamada := AIDChamada;
  FOwnedManuscrito := AOwnedManuscrito;
end;

destructor TContextoRevisao.Destroy;
begin
  FResposta.Free;
  if FOwnedManuscrito then
    FManuscrito.Free;
  inherited;
end;
procedure TContextoRevisao.SubstituirResposta(const ANova: TResposta);
begin
  if ANova = FResposta then
    Exit;
  FResposta.Free;
  FResposta := ANova;
end;

end.
