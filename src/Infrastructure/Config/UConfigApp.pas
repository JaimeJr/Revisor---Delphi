unit UConfigApp;

{
  UConfigApp.pas
  ─────────────────────────────────────────────────────────────
  Configuração global da aplicação. Singleton, instanciado no
  boot, com a chave da API carregada do disco.

  A chave NÃO é hardcoded nem passada por parâmetro — vem de
  TKeyLoader no construtor. Se o arquivo não existir, a
  instanciação falha e o erro aparece no boot (não na primeira
  chamada de API).

  Todos os valores têm default sensato. Nenhum precisa de
  configuração para o sistema funcionar — só a chave.

  Propriedades são read-only exceto as que o usuário pode
  ajustar em tela de configuração (Temperature, MaxTokens).
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
    FPrecoInputPorMilhao: Double;
    FPrecoOutputPorMilhao: Double;
    FTemperature: Double;
    FMaxTokens: Integer;
    FLimiteParagrafoPalavras: Integer;
    FTamanhoChunkPalavras: Integer;
    FPastaDados: string;
    FPastaManuscritos: string;
    FPastaLogs: string;
  public
    constructor Create;
    destructor Destroy; override;

    // ─── Singleton ───
    class function Instancia: TConfigApp;
    class procedure Destruir;

    // ─── API ───
    /// <summary>Chave DeepSeek carregada do disco. Read-only.</summary>
    property ApiKey: string read FApiKey;

    // ─── Modelo / parâmetros ───
    property Modelo: string read FModelo write FModelo;
    property Temperature: Double read FTemperature write FTemperature;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens;
    property Endpoint: string read FEndpoint write FEndpoint;
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

    /// <summary>
    ///   Caminho do Vicios.JSON padrão. Vive em /data/.
    /// </summary>
    function CaminhoViciosJSON: string;

    /// <summary>
    ///   Dado o caminho de um Antes.JSON, retorna o caminho
    ///   do Novo.JSON correspondente (mesmo diretório, sufixo
    ///   "_novo").
    /// </summary>
    function CaminhoNovoPara(const ACaminhoAntes: string): string;

    /// <summary>
    ///   Dado o caminho de um Antes.JSON, retorna o caminho
    ///   do Envio.JSON correspondente.
    /// </summary>
    function CaminhoEnvioPara(const ACaminhoAntes: string): string;

    /// <summary>
    ///   Dado o caminho de um Antes.JSON, retorna o caminho
    ///   do Resposta.JSON correspondente.
    /// </summary>
    function CaminhoRespostaPara(const ACaminhoAntes: string): string;

    /// <summary>
    ///   Dado o caminho de um Antes.JSON, retorna o caminho
    ///   do parse.log correspondente.
    /// </summary>
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

  // Falha rápido se a chave não existir — erro no boot, não
  // na primeira chamada de API.
  FApiKey := TKeyLoader.CarregarDeepSeekKey;

  // Defaults — ajustáveis em tela de configuração futura.
  FModelo := 'deepseek-chat';
  FTemperature := 0.3;
  FMaxTokens := 1500;
  FLimiteParagrafoPalavras := 600;
  FTamanhoChunkPalavras := 300;

  // Pastas de dados (relativas ao diretório do executável).
  FPastaDados := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data');
  FPastaManuscritos := TPath.Combine(FPastaDados, 'manuscritos');
  FPastaLogs := TPath.Combine(FPastaDados, 'logs');
  FEndpoint := 'https://api.deepseek.com/chat/completions';
  FPrecoInputPorMilhao := 0.27;   // USD por 1M tokens de input
  FPrecoOutputPorMilhao := 1.10;  // USD por 1M tokens de output
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
