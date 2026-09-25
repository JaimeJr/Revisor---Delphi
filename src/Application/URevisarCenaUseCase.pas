unit URevisarCenaUseCase;

{
  URevisarCenaUseCase.pas
  ─────────────────────────────────────────────────────────────
  Caso de uso que orquestra uma revisão de cena.

  TParametrosRevisao agora carrega também CaminhoEnvio e
  CaminhoResposta, que são propagados para a TChamada. Assim
  o revisor sabe onde gravar os logs.
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
  TSelecaoUsuario = record
    ParagrafoID: TID;
    VicioID: string;
    constructor Create(const AParagrafoID: TID; const AVicioID: string);
  end;

  TParametrosRevisao = record
    CaminhoNovo: string;
    CaminhoVicios: string;
    CaminhoEnvio: string;
    CaminhoResposta: string;
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

    function Executar(const AParams: TParametrosRevisao): TResposta;
  end;

implementation

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
  I, Total: Integer;
  Sel: TParagrafoSelecionado;
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
      AChamada.DerivarViciosInjetados;

    meVarredura:
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
  if AParams.CaminhoNovo = '' then
    raise EValorInvalido.Create('CaminhoNovo não pode ser vazio.');
  if AParams.CaminhoVicios = '' then
    raise EValorInvalido.Create('CaminhoVicios não pode ser vazio.');
  if AParams.CaminhoEnvio = '' then
    raise EValorInvalido.Create('CaminhoEnvio não pode ser vazio.');
  if AParams.CaminhoResposta = '' then
    raise EValorInvalido.Create('CaminhoResposta não pode ser vazio.');
  if AParams.CenaID = '' then
    raise EValorInvalido.Create('CenaID não pode ser vazio.');

  if (AParams.Modo = meCirurgico) and (Length(AParams.Selecoes) = 0) then
    raise EOperacaoInvalida.Create(
      'Modo cirúrgico exige pelo menos uma seleção de parágrafo.');

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

      Chamada := TChamada.Create;
      try
        Chamada.CenaID := AParams.CenaID;
        Chamada.Modo := AParams.Modo;
        Chamada.ObservacaoUsuario := AParams.Observacao.Trim;
        Chamada.CaminhoNovo := AParams.CaminhoNovo;
        Chamada.CaminhoEnvio := AParams.CaminhoEnvio;
        Chamada.CaminhoResposta := AParams.CaminhoResposta;

        case AParams.Modo of
          meCirurgico:
            PreencherChunksCirurgico(Chamada, Cena, AParams.Selecoes);
          meVarredura:
            PreencherChunksVarredura(Chamada, Cena);
        end;

        AplicarViciosInjetados(Chamada, Catalogo);
        Chamada.EstimarTokensInput;

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
