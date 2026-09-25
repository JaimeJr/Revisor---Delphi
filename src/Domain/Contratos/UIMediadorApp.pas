unit UIMediadorApp;


interface

uses
  System.SysUtils,
  UManuscrito,
  UEdicaoSugerida,
  UTiposUI,
  UValores;

type
  TContextoRevisao = class
  private
    FManuscrito: TManuscrito;
    FResposta: TResposta;
    FCaminhoNovo: string;
    FCaminhoVicios: string;
    FCaminhoEnvio: string;
    FCaminhoResposta: string;
    FCenaID: TID;
    FModo: TModoEnvio;
    FIDChamada: string;
    FOwnedManuscrito: Boolean;
  public
    constructor Create(const AManuscrito: TManuscrito;
      const AResposta: TResposta;
      const ACaminhoNovo, ACaminhoVicios,
      ACaminhoEnvio, ACaminhoResposta: string;
      const ACenaID: TID; const AModo: TModoEnvio;
      const AIDChamada: string;
      const AOwnedManuscrito: Boolean = False);
    destructor Destroy; override;

    property Manuscrito: TManuscrito read FManuscrito;
    property Resposta: TResposta read FResposta;
    property CaminhoNovo: string read FCaminhoNovo;
    property CaminhoVicios: string read FCaminhoVicios;
    property CaminhoEnvio: string read FCaminhoEnvio;
    property CaminhoResposta: string read FCaminhoResposta;
    property CenaID: TID read FCenaID;
    property Modo: TModoEnvio read FModo;
    property IDChamada: string read FIDChamada;

    procedure SubstituirResposta(const ANova: TResposta);
  end;

  TProcRevisaoFechada = reference to procedure;

  IMediadorApp = interface
    ['{3CC8D896-C788-4ABF-99D5-19EC92851831}']
    procedure AbrirRevisao(const AContexto: TContextoRevisao;
      const AOnFechada: TProcRevisaoFechada);

    procedure AbrirVicios(const ACaminhoVicios: string;
      const AOnFechada: TProcRevisaoFechada);

    function PerguntarObservacaoReenvio: string;

    procedure ExecutarComLoading(const AMensagem: string;
      const AOperacao: TProc);
  end;

implementation

constructor TContextoRevisao.Create(const AManuscrito: TManuscrito;
  const AResposta: TResposta;
  const ACaminhoNovo, ACaminhoVicios,
  ACaminhoEnvio, ACaminhoResposta: string;
  const ACenaID: TID; const AModo: TModoEnvio;
  const AIDChamada: string;
  const AOwnedManuscrito: Boolean);
begin
  inherited Create;
  FManuscrito := AManuscrito;
  FResposta := AResposta;
  FCaminhoNovo := ACaminhoNovo;
  FCaminhoVicios := ACaminhoVicios;
  FCaminhoEnvio := ACaminhoEnvio;
  FCaminhoResposta := ACaminhoResposta;
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
