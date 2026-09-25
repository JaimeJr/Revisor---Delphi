unit URevisorDeepSeek;

{
  URevisorDeepSeek.pas
  ─────────────────────────────────────────────────────────────
  Implementação síncrona de IRevisorIA usando a API DeepSeek.

  Nesta versão:
    • Não carrega caminhos de Envio/Resposta — eles vêm por
      AChamada.CaminhoEnvio e AChamada.CaminhoResposta.
    • Mantém apenas o CaminhoVicios, que é fixo por instalação
      e necessário para carregar o catálogo ao montar o prompt.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.URLClient,
  UIRevisorIA,
  UChamada,
  UEdicaoSugerida,
  UIConstrutorPrompt,
  UICacheChamadas,
  UIEnvioRepository,
  UIRespostaRepository,
  UIViciosRepository;

type
  TRevisorDeepSeek = class(TInterfacedObject, IRevisorIA)
  private
    FApiKey: string;
    FModelo: string;
    FEndpoint: string;
    FTimeoutMs: Integer;
    FPromptFactory: IPromptFactory;
    FCache: ICacheChamadas;
    FEnvioRepo: IEnvioRepository;
    FRespostaRepo: IRespostaRepository;
    FViciosRepo: IViciosRepository;
    FCaminhoVicios: string;
    FPrecoInputPorMilhao: Double;
    FPrecoOutputPorMilhao: Double;

    function ConsultarCache(const AHash: string): TResposta;
    function ExecutarHttp(const APayload: TPayload): string;
    function ParsearResposta(const ARespostaBruta: string;
      const AIDChamada: string): TResposta;
    function ExtrairConteudo(const AJsonResposta: TJSONObject): string;
    procedure PreencherUso(const AJsonResposta: TJSONObject;
      const AResposta: TResposta);
    procedure PreencherEdicoes(const AConteudoJson: string;
      const AResposta: TResposta);
    procedure AplicarEscopo(const AChamada: TChamada;
      const AResposta: TResposta);
    function EstimarCusto(const ATokensIn, ATokensOut: Integer): Double;
    procedure ConfigurarHttp(const AHttp: THTTPClient);
  public
    constructor Create(const AApiKey, AModelo, AEndpoint: string;
      const ATimeoutMs: Integer;
      const APromptFactory: IPromptFactory;
      const ACache: ICacheChamadas;
      const AEnvioRepo: IEnvioRepository;
      const ARespostaRepo: IRespostaRepository;
      const AViciosRepo: IViciosRepository;
      const ACaminhoVicios: string;
      const APrecoInputPorMilhao, APrecoOutputPorMilhao: Double);

    function Revisar(const AChamada: TChamada): TResposta;
  end;

implementation

uses
  UVicio,
  UValores;

constructor TRevisorDeepSeek.Create(const AApiKey, AModelo,
  AEndpoint: string; const ATimeoutMs: Integer;
  const APromptFactory: IPromptFactory; const ACache: ICacheChamadas;
  const AEnvioRepo: IEnvioRepository; const ARespostaRepo: IRespostaRepository;
  const AViciosRepo: IViciosRepository;
  const ACaminhoVicios: string;
  const APrecoInputPorMilhao, APrecoOutputPorMilhao: Double);
begin
  inherited Create;

  if AApiKey = '' then
    raise EValorInvalido.Create('ApiKey não pode ser vazia.');
  if not Assigned(APromptFactory) then
    raise EValorInvalido.Create('IPromptFactory não pode ser nil.');
  if not Assigned(ACache) then
    raise EValorInvalido.Create('ICacheChamadas não pode ser nil.');
  if not Assigned(AEnvioRepo) then
    raise EValorInvalido.Create('IEnvioRepository não pode ser nil.');
  if not Assigned(ARespostaRepo) then
    raise EValorInvalido.Create('IRespostaRepository não pode ser nil.');
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');
  if ACaminhoVicios = '' then
    raise EValorInvalido.Create('CaminhoVicios não pode ser vazio.');

  FApiKey := AApiKey;
  FModelo := AModelo;
  FEndpoint := AEndpoint;
  FTimeoutMs := ATimeoutMs;
  FPromptFactory := APromptFactory;
  FCache := ACache;
  FEnvioRepo := AEnvioRepo;
  FRespostaRepo := ARespostaRepo;
  FViciosRepo := AViciosRepo;
  FCaminhoVicios := ACaminhoVicios;
  FPrecoInputPorMilhao := APrecoInputPorMilhao;
  FPrecoOutputPorMilhao := APrecoOutputPorMilhao;
end;

function TRevisorDeepSeek.Revisar(const AChamada: TChamada): TResposta;
var
  Hash: string;
  Payload: TPayload;
  RespostaBruta: string;
  Resposta: TResposta;
  Catalogo: TCatalogoVicios;
begin
  if AChamada = nil then
    raise EValorInvalido.Create('Chamada não pode ser nil.');
  if AChamada.PayloadVazio then
    raise EOperacaoInvalida.Create(
      'Chamada sem parágrafos selecionados — nada a revisar.');
  if AChamada.CaminhoEnvio = '' then
    raise EOperacaoInvalida.Create(
      'TChamada.CaminhoEnvio não foi preenchido pelo UseCase.');
  if AChamada.CaminhoResposta = '' then
    raise EOperacaoInvalida.Create(
      'TChamada.CaminhoResposta não foi preenchido pelo UseCase.');

  Hash := AChamada.CalcularHashPayload;
  AChamada.HashPayload := Hash;

  Resposta := ConsultarCache(Hash);
  if Assigned(Resposta) then
    Exit(Resposta);

  // Persiste a chamada.
  FEnvioRepo.Append(AChamada, AChamada.CaminhoEnvio);

  // Monta o payload (precisa do catálogo para injetar dicas).
  Catalogo := FViciosRepo.Carregar(FCaminhoVicios);
  try
    Payload := FPromptFactory.ParaModo(AChamada.Modo)
      .Montar(AChamada, Catalogo);
  finally
    Catalogo.Free;
  end;

  // Executa HTTP. Falha de rede vira TResposta com parse_error.
  try
    RespostaBruta := ExecutarHttp(Payload);
  except
    on E: Exception do
    begin
      Resposta := TResposta.Create;
      Resposta.IDChamada := AChamada.IDChamada;
      Resposta.StatusParse := spParseError;
      Resposta.ErroParse := 'Falha de rede: ' + E.Message;
      FRespostaRepo.Append(Resposta, AChamada.CaminhoResposta);
      Exit(Resposta);
    end;
  end;

  Resposta := ParsearResposta(RespostaBruta, AChamada.IDChamada);
  AplicarEscopo(AChamada, Resposta);
  Resposta.ReclassificarStatus;

  FRespostaRepo.Append(Resposta, AChamada.CaminhoResposta);
  FCache.Guardar(Hash, Resposta);

  Result := Resposta.Clonar;
  Resposta.Free;
end;

function TRevisorDeepSeek.ConsultarCache(const AHash: string): TResposta;
begin
  if FCache.Contem(AHash) then
    Result := FCache.Recuperar(AHash)
  else
    Result := nil;
end;

function TRevisorDeepSeek.ExecutarHttp(const APayload: TPayload): string;
var
  Http: THTTPClient;
  Corpo: TStringStream;
  Resposta: IHTTPResponse;
  JsonBody: TJSONObject;
  Mensagens: TJSONArray;
  MsgSystem, MsgUser, ResponseFormat: TJSONObject;
  JsonTexto: string;
begin
  Http := THTTPClient.Create;
  try
    ConfigurarHttp(Http);

    JsonBody := TJSONObject.Create;
    Corpo := TStringStream.Create('', TEncoding.UTF8);
    try
      JsonBody.AddPair('model', FModelo);

      Mensagens := TJSONArray.Create;
      MsgSystem := TJSONObject.Create;
      MsgSystem.AddPair('role', 'system');
      MsgSystem.AddPair('content', APayload.System);
      Mensagens.AddElement(MsgSystem);

      MsgUser := TJSONObject.Create;
      MsgUser.AddPair('role', 'user');
      MsgUser.AddPair('content', APayload.User);
      Mensagens.AddElement(MsgUser);

      JsonBody.AddPair('messages', Mensagens);
      JsonBody.AddPair('temperature',
        TJSONNumber.Create(APayload.Temperature));
      JsonBody.AddPair('max_tokens',
        TJSONNumber.Create(APayload.MaxTokens));

      ResponseFormat := TJSONObject.Create;
      ResponseFormat.AddPair('type', APayload.ResponseFormat);
      JsonBody.AddPair('response_format', ResponseFormat);

      JsonTexto := JsonBody.ToJSON;
      Corpo.WriteString(JsonTexto);
      Corpo.Position := 0;
    finally
      JsonBody.Free;
    end;

    Resposta := Http.Post(FEndpoint, Corpo);
    Result := Resposta.ContentAsString(TEncoding.UTF8);
  finally
    Corpo.Free;
    Http.Free;
  end;
end;

procedure TRevisorDeepSeek.ConfigurarHttp(const AHttp: THTTPClient);
begin
  AHttp.ConnectionTimeout := FTimeoutMs;
  AHttp.ResponseTimeout := FTimeoutMs;
  AHttp.CustomHeaders['Authorization'] := 'Bearer ' + FApiKey;
  AHttp.CustomHeaders['Content-Type'] := 'application/json';
  AHttp.Accept := 'application/json';
end;

function TRevisorDeepSeek.ParsearResposta(const ARespostaBruta: string;
  const AIDChamada: string): TResposta;
var
  Json: TJSONValue;
  Conteudo: string;
begin
  Result := TResposta.Create;
  Result.IDChamada := AIDChamada;
  Result.RespostaBruta := ARespostaBruta;

  Json := TJSONObject.ParseJSONValue(ARespostaBruta);
  if not Assigned(Json) then
  begin
    Result.StatusParse := spParseError;
    Result.ErroParse := 'Resposta da API não é JSON válido.';
    Exit;
  end;

  try
    try
      Conteudo := ExtrairConteudo(Json as TJSONObject);
      PreencherUso(Json as TJSONObject, Result);
    except
      on E: Exception do
      begin
        Result.StatusParse := spParseError;
        Result.ErroParse := 'Estrutura da resposta da API inesperada: ' +
          E.Message;
        Exit;
      end;
    end;

    PreencherEdicoes(Conteudo, Result);
  finally
    Json.Free;
  end;
end;

function TRevisorDeepSeek.ExtrairConteudo(
  const AJsonResposta: TJSONObject): string;
var
  Choices: TJSONArray;
  Choice, Message: TJSONObject;
begin
  Choices := AJsonResposta.GetValue<TJSONArray>('choices');
  if Choices.Count = 0 then
    raise Exception.Create('Resposta sem choices.');

  Choice := Choices.Items[0] as TJSONObject;
  Message := Choice.GetValue<TJSONObject>('message');
  Result := Message.GetValue<string>('content');
end;

procedure TRevisorDeepSeek.PreencherUso(const AJsonResposta: TJSONObject;
  const AResposta: TResposta);
var
  Usage: TJSONObject;
begin
  if not AJsonResposta.TryGetValue<TJSONObject>('usage', Usage) then
    Exit;

  AResposta.TokensPrompt := Usage.GetValue<Integer>('prompt_tokens');
  AResposta.TokensResposta := Usage.GetValue<Integer>('completion_tokens');
  AResposta.CustoEstimado := EstimarCusto(
    AResposta.TokensPrompt, AResposta.TokensResposta);
end;

procedure TRevisorDeepSeek.PreencherEdicoes(const AConteudoJson: string;
  const AResposta: TResposta);
var
  Json: TJSONValue;
  Raiz: TJSONObject;
  Arranjo: TJSONArray;
  I: Integer;
  Item: TJSONObject;
  Edicao: TEdicaoSugerida;
  VicioGeral: string;
begin
  Json := TJSONObject.ParseJSONValue(AConteudoJson);
  if not Assigned(Json) then
  begin
    AResposta.StatusParse := spParseError;
    AResposta.ErroParse := 'Conteúdo da resposta não é JSON válido.';
    Exit;
  end;

  try
    if not (Json is TJSONObject) then
    begin
      AResposta.StatusParse := spParseError;
      AResposta.ErroParse := 'Conteúdo da resposta não é objeto JSON.';
      Exit;
    end;

    Raiz := Json as TJSONObject;

    if Raiz.TryGetValue<string>('vicio_geral', VicioGeral) then
      AResposta.VicioGeral := VicioGeral;

    if not Raiz.TryGetValue<TJSONArray>('edicoes', Arranjo) then
    begin
      AResposta.StatusParse := spParseError;
      AResposta.ErroParse := 'Campo "edicoes" ausente na resposta.';
      Exit;
    end;

    for I := 0 to Arranjo.Count - 1 do
    begin
      Item := Arranjo.Items[I] as TJSONObject;
      Edicao := TEdicaoSugerida.Create;
      try
        Edicao.ParagrafoID := Item.GetValue<string>('paragrafo_id');
        Edicao.ChunkIndex := Item.GetValue<Integer>('chunk_index');
        Edicao.VicioID := Item.GetValue<string>('id_vicio');
        Edicao.Sugerido := Item.GetValue<string>('sugerido');
        Edicao.Motivo := Item.GetValue<string>('motivo');
        AResposta.Edicoes.Add(Edicao);
      except
        Edicao.Free;
        raise;
      end;
    end;

    AResposta.StatusParse := spOK;
  finally
    Json.Free;
  end;
end;

procedure TRevisorDeepSeek.AplicarEscopo(const AChamada: TChamada;
  const AResposta: TResposta);
var
  ListaParagrafos: TList<TID>;
  ListaVicios: TList<string>;
  Sel: TParagrafoSelecionado;
  V: string;
begin
  ListaParagrafos := TList<TID>.Create;
  ListaVicios := TList<string>.Create;
  try
    for Sel in AChamada.Selecoes do
      ListaParagrafos.Add(Sel.ParagrafoID);

    for V in AChamada.ViciosInjetados do
      ListaVicios.Add(V);

    AResposta.DefinirParagrafosPermitidos(ListaParagrafos.ToArray);
    AResposta.DefinirViciosPermitidos(ListaVicios.ToArray);
  finally
    ListaParagrafos.Free;
    ListaVicios.Free;
  end;
end;

function TRevisorDeepSeek.EstimarCusto(const ATokensIn,
  ATokensOut: Integer): Double;
begin
  Result := (ATokensIn / 1000000.0) * FPrecoInputPorMilhao +
            (ATokensOut / 1000000.0) * FPrecoOutputPorMilhao;
end;

end.
