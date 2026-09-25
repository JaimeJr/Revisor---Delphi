unit URevisarCenaUseCase;

{
  URevisarCenaUseCase.pas
  ─────────────────────────────────────────────────────────────
  Caso de uso que orquestra uma revisão de cena.

  Fluxo:
    1. Carrega Novo.JSON (para pegar os textos atuais dos
       parágrafos) e Vicios.JSON (para injetar dicas).
    2. Monta a TChamada:
       • Modo cirúrgico: usa as seleções do usuário
         (ParagrafoID + VicioID por item).
       • Modo varredura: pega todos os parágrafos da cena.
         VicioID := VICIO_VARREDURA.
    3. Aplica chunking em parágrafos > LIMITE_PARAGRAFO_PALAVRAS.
    4. Deriva ViciosInjetados (cirúrgico: únicos das seleções;
       varredura: catálogo inteiro).
    5. Estima tokens.
    6. Chama IRevisorIA.Revisar (síncrono).
    7. Devolve a TResposta (ownership transferido).

  Unificação:
    • Cobre também o reenvio. Se Observacao vier preenchida,
      é uma reanálise com instrução adicional. Não há UseCase
      separado para reenvio.

  O que NÃO faz:
    • Não aceita nem recusa edições. Isso é o UseCase de aceite.
    • Não persiste nada além do que o revisor já persiste
      (Envio/Resposta.JSON são anexados lá dentro).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UChamada,
  UEdicaoSugerida,
  UManuscrito,
  UVicio,
  UIRevisorIA,
  UINovoRepository,
  UIViciosRepository,
  UServicosDominio,
  UValores;

type
  /// <summary>
  ///   Item de seleção do usuário: um parágrafo com UM vício.
  ///   O texto e o hash são preenchidos pelo UseCase.
  /// </summary>
  TSelecaoUsuario = record
    ParagrafoID: TID;
    VicioID: string;
    constructor Create(const AParagrafoID: TID; const AVicioID: string);
  end;

  /// <summary>Parâmetros completos de uma revisão.</summary>
  TParametrosRevisao = record
    CaminhoNovo: string;
    CaminhoVicios: string;
    CenaID: TID;
    Modo: TModoEnvio;
    Selecoes: TArray<TSelecaoUsuario>;
    Observacao: string;
  end;

  TRevisarCenaUseCase = class
  private
    FRevisor: IRevisorIA;
    FNovoRepo: INovoRepository;
    FViciosRepo: IViciosRepository;

    function LocalizarCena(const AManuscrito: TManuscrito;
      const ACenaID: TID): TCena;

    procedure PreencherChunksCirurgico(const AChamada: TChamada;
      const ACena: TCena; const ASelecoes: TArray<TSelecaoUsuario>);

    procedure PreencherChunksVarredura(const AChamada: TChamada;
      const ACena: TCena);

    procedure AdicionarChunksDoParagrafo(const AChamada: TChamada;
      const APar: TParagrafo; const AVicioID: string);

    procedure AplicarViciosInjetados(const AChamada: TChamada;
      const ACatalogo: TCatalogoVicios);
  public
    constructor Create(const ARevisor: IRevisorIA;
      const ANovoRepo: INovoRepository;
      const AViciosRepo: IViciosRepository);

    /// <summary>
    ///   Executa a revisão. Devolve a TResposta (o chamador é
    ///   responsável por liberá-la).
    /// </summary>
    function Executar(const AParams: TParametrosRevisao): TResposta;
  end;

implementation

{ TSelecaoUsuario }

constructor TSelecaoUsuario.Create(const AParagrafoID: TID;
  const AVicioID: string);
begin
  ParagrafoID := AParagrafoID;
  VicioID := AVicioID;
end;

{ TRevisarCenaUseCase }

constructor TRevisarCenaUseCase.Create(const ARevisor: IRevisorIA;
  const ANovoRepo: INovoRepository; const AViciosRepo: IViciosRepository);
begin
  inherited Create;

  if not Assigned(ARevisor) then
    raise EValorInvalido.Create('IRevisorIA não pode ser nil.');
  if not Assigned(ANovoRepo) then
    raise EValorInvalido.Create('INovoRepository não pode ser nil.');
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');

  FRevisor := ARevisor;
  FNovoRepo := ANovoRepo;
  FViciosRepo := AViciosRepo;
end;

function TRevisarCenaUseCase.LocalizarCena(const AManuscrito: TManuscrito;
  const ACenaID: TID): TCena;
begin
  Result := AManuscrito.CenaPorID(ACenaID);
  if not Assigned(Result) then
    raise EOperacaoInvalida.CreateFmt(
      'Cena "%s" não encontrada no Novo.JSON.', [ACenaID]);
end;

procedure TRevisarCenaUseCase.AdicionarChunksDoParagrafo(
  const AChamada: TChamada; const APar: TParagrafo;
  const AVicioID: string);
var
  Chunks: TArray<string>;
  I: Integer;
  Sel: TParagrafoSelecionado;
  Total: Integer;
begin
  Chunks := TCompressorPayload.DividirEmChunks(APar.Texto);
  Total := Length(Chunks);
  if Total = 0 then
    raise EOperacaoInvalida.CreateFmt(
      'Parágrafo "%s" não produziu nenhum chunk.', [APar.ID]);

  for I := 0 to Total - 1 do
  begin
    Sel := TParagrafoSelecionado.Create;
    Sel.ParagrafoID := APar.ID;
    Sel.VicioID := AVicioID;
    Sel.HashParagrafo := APar.Hash;
    Sel.Texto := Chunks[I];
    Sel.ChunkIndex := I + 1;
    Sel.ChunksTotais := Total;
    AChamada.AdicionarSelecao(Sel);
  end;
end;

procedure TRevisarCenaUseCase.PreencherChunksCirurgico(
  const AChamada: TChamada; const ACena: TCena;
  const ASelecoes: TArray<TSelecaoUsuario>);
var
  Selecao: TSelecaoUsuario;
  Par: TParagrafo;
begin
  for Selecao in ASelecoes do
  begin
    Par := ACena.ParagrafoPorID(Selecao.ParagrafoID);
    if not Assigned(Par) then
      raise EOperacaoInvalida.CreateFmt(
        'Parágrafo "%s" não pertence à cena "%s".',
        [Selecao.ParagrafoID, ACena.ID]);

    AdicionarChunksDoParagrafo(AChamada, Par, Selecao.VicioID);
  end;
end;

procedure TRevisarCenaUseCase.PreencherChunksVarredura(
  const AChamada: TChamada; const ACena: TCena);
var
  Par: TParagrafo;
begin
  for Par in ACena.Paragrafos do
    AdicionarChunksDoParagrafo(AChamada, Par, VICIO_VARREDURA);
end;

procedure TRevisarCenaUseCase.AplicarViciosInjetados(
  const AChamada: TChamada; const ACatalogo: TCatalogoVicios);
var
  V: TVicio;
begin
  case AChamada.Modo of
    meCirurgico:
      // Deriva das seleções — vícios únicos efetivamente marcados.
      AChamada.DerivarViciosInjetados;

    meVarredura:
      // Injeta o catálogo inteiro.
      for V in ACatalogo.Categorias do
        AChamada.AdicionarVicioInjetado(V.ID);
  end;
end;

function TRevisarCenaUseCase.Executar(
  const AParams: TParametrosRevisao): TResposta;
var
  Novo: TManuscrito;
  Catalogo: TCatalogoVicios;
  Cena: TCena;
  Chamada: TChamada;
begin
  // ─── Validações de entrada ───
  if AParams.CaminhoNovo = '' then
    raise EValorInvalido.Create('CaminhoNovo não pode ser vazio.');
  if AParams.CaminhoVicios = '' then
    raise EValorInvalido.Create('CaminhoVicios não pode ser vazio.');
  if AParams.CenaID = '' then
    raise EValorInvalido.Create('CenaID não pode ser vazio.');

  if (AParams.Modo = meCirurgico) and (Length(AParams.Selecoes) = 0) then
    raise EOperacaoInvalida.Create(
      'Modo cirúrgico exige pelo menos uma seleção de parágrafo.');

  // ─── Carrega Novo.JSON e Vicios.JSON ───
  Novo := FNovoRepo.Carregar(AParams.CaminhoNovo);
  if Novo = nil then
    raise EOperacaoInvalida.CreateFmt(
      'Novo.JSON não encontrado em "%s".', [AParams.CaminhoNovo]);

  try
    Catalogo := FViciosRepo.Carregar(AParams.CaminhoVicios);
    try
      Cena := LocalizarCena(Novo, AParams.CenaID);

      if Cena.Paragrafos.Count = 0 then
        raise EOperacaoInvalida.CreateFmt(
          'Cena "%s" não tem parágrafos.', [Cena.ID]);

      // ─── Monta a TChamada ───
      Chamada := TChamada.Create;
      try
        Chamada.CenaID := AParams.CenaID;
        Chamada.Modo := AParams.Modo;
        Chamada.ObservacaoUsuario := AParams.Observacao.Trim;

        case AParams.Modo of
          meCirurgico:
            PreencherChunksCirurgico(Chamada, Cena, AParams.Selecoes);
          meVarredura:
            PreencherChunksVarredura(Chamada, Cena);
        end;

        AplicarViciosInjetados(Chamada, Catalogo);
        Chamada.EstimarTokensInput;

        // ─── Chama o revisor ───
        // O revisor calcula o hash, checa cache, anexa a Envio.JSON,
        // monta o payload, chama a API, parseia, anexa a Resposta.JSON
        // e devolve uma cópia.
        Result := FRevisor.Revisar(Chamada);
      finally
        Chamada.Free;
      end;
    finally
      Catalogo.Free;
    end;
  finally
    Novo.Free;
  end;
end;

end.
