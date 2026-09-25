unit UConfigApp;

{
  UConfigApp.pas
  ─────────────────────────────────────────────────────────────
  Configuração global da aplicação. Singleton, instanciado no
  boot, com a chave da API carregada do disco.

  A chave NÃO é hardcoded — vem de TKeyLoader no construtor.
  Se o arquivo não existir, a instanciação falha no boot.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UKeyLoader;

type
  TConfigApp = class
  private
    class var FInstancia: TConfigApp;
  private
    FApiKey: string;
    FModelo: string;
    FEndpoint: string;
    FTemperature: Double;
    FMaxTokens: Integer;
    FLimiteParagrafoPalavras: Integer;
    FTamanhoChunkPalavras: Integer;
    FPrecoInputPorMilhao: Double;
    FPrecoOutputPorMilhao: Double;
    FPastaDados: string;
    FPastaManuscritos: string;
    FPastaLogs: string;
  public
    constructor Create;
    destructor Destroy; override;

    class function Instancia: TConfigApp;
    class procedure Destruir;

    // ─── API ───
    property ApiKey: string read FApiKey;
    property Modelo: string read FModelo write FModelo;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Temperature: Double read FTemperature write FTemperature;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens;

    // ─── Preços (USD por 1M tokens) ───
    property PrecoInputPorMilhao: Double
      read FPrecoInputPorMilhao write FPrecoInputPorMilhao;
    property PrecoOutputPorMilhao: Double
      read FPrecoOutputPorMilhao write FPrecoOutputPorMilhao;

    // ─── Regras de domínio ───
    property LimiteParagrafoPalavras: Integer
      read FLimiteParagrafoPalavras;
    property TamanhoChunkPalavras: Integer
      read FTamanhoChunkPalavras;

    // ─── Pastas de dados ───
    property PastaDados: string read FPastaDados;
    property PastaManuscritos: string read FPastaManuscritos;
    property PastaLogs: string read FPastaLogs;

    function CaminhoViciosJSON: string;
    function CaminhoNovoPara(const ACaminhoAntes: string): string;
    function CaminhoEnvioPara(const ACaminhoAntes: string): string;
    function CaminhoRespostaPara(const ACaminhoAntes: string): string;
    function CaminhoParseLogPara(const ACaminhoAntes: string): string;
  end;

implementation

uses
  System.IOUtils;

const
  SUFIXO_NOVO = '_novo';
  SUFIXO_ENVIO = '_envio';
  SUFIXO_RESPOSTA = '_resposta';
  SUFIXO_PARSE_LOG = '_parse';

{ TConfigApp }

constructor TConfigApp.Create;
begin
  inherited;

  // Falha rápido se a chave não existir.
  FApiKey := TKeyLoader.CarregarDeepSeekKey;

  // Defaults.
  FModelo := 'deepseek-chat';
  FEndpoint := 'https://api.deepseek.com/chat/completions';
  FTemperature := 0.3;
  FMaxTokens := 1500;
  FLimiteParagrafoPalavras := 600;
  FTamanhoChunkPalavras := 300;

  // Preços base (USD por 1M tokens).
  FPrecoInputPorMilhao := 0.27;
  FPrecoOutputPorMilhao := 1.10;

  // Pastas de dados.
  FPastaDados := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data');
  FPastaManuscritos := TPath.Combine(FPastaDados, 'manuscritos');
  FPastaLogs := TPath.Combine(FPastaDados, 'logs');
end;

destructor TConfigApp.Destroy;
begin
  inherited;
end;

class function TConfigApp.Instancia: TConfigApp;
begin
  if not Assigned(FInstancia) then
    FInstancia := TConfigApp.Create;
  Result := FInstancia;
end;

class procedure TConfigApp.Destruir;
begin
  FreeAndNil(FInstancia);
end;

function TConfigApp.CaminhoViciosJSON: string;
begin
  Result := TPath.Combine(FPastaDados, 'vicios.json');
end;

function TConfigApp.CaminhoNovoPara(const ACaminhoAntes: string): string;
begin
  Result := TPath.Combine(
    TPath.GetDirectoryName(ACaminhoAntes),
    TPath.GetFileNameWithoutExtension(ACaminhoAntes) +
      SUFIXO_NOVO + TPath.GetExtension(ACaminhoAntes));
end;

function TConfigApp.CaminhoEnvioPara(const ACaminhoAntes: string): string;
begin
  Result := TPath.Combine(
    TPath.GetDirectoryName(ACaminhoAntes),
    TPath.GetFileNameWithoutExtension(ACaminhoAntes) +
      SUFIXO_ENVIO + TPath.GetExtension(ACaminhoAntes));
end;

function TConfigApp.CaminhoRespostaPara(const ACaminhoAntes: string): string;
begin
  Result := TPath.Combine(
    TPath.GetDirectoryName(ACaminhoAntes),
    TPath.GetFileNameWithoutExtension(ACaminhoAntes) +
      SUFIXO_RESPOSTA + TPath.GetExtension(ACaminhoAntes));
end;

function TConfigApp.CaminhoParseLogPara(const ACaminhoAntes: string): string;
begin
  Result := TPath.Combine(
    TPath.GetDirectoryName(ACaminhoAntes),
    TPath.GetFileNameWithoutExtension(ACaminhoAntes) +
      SUFIXO_PARSE_LOG + '.log');
end;

end.
