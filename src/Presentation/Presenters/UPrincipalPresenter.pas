unit UPrincipalPresenter;

{
  UPrincipalPresenter.pas
  ─────────────────────────────────────────────────────────────
  Presenter da tela principal.

  Modelo:
    • Árvore: Ato > Capítulo > Cena. Só cena carrega o painel.
    • Painel direito: uma cena por vez, com checkbox por
      parágrafo.
    • Revisão: usa os marcados; se nenhum, todos da cena.
    • Marcar revisados: mesma regra.

  Caminhos da sessão:
    • FCaminhoAntes, FCaminhoNovo, FCaminhoVicios,
      FCaminhoParseLog, FCaminhoEnvio, FCaminhoResposta.
    • Envio e Resposta são derivados do Antes na importação.
    • Todos são propagados para TChamada e TContextoRevisao.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UIPrincipalView,
  UIMediadorApp,
  UImportarManuscritoUseCase,
  UExportarManuscritoUseCase,
  URevisarCenaUseCase,
  UManterVicioUseCase,
  UMarcarRevisadoManualUseCase,
  UCommandStack,
  UINovoRepository,
  UIRespostaRepository,
  UIViciosRepository,
  UManuscrito,
  UVicio,
  UEdicaoSugerida,
  UAnomaliaParse,
  UTiposUI,
  UValores;

type
  TPrincipalPresenter = class
  private
    FView: IPrincipalView;
    FMediador: IMediadorApp;

    FImportarUC: TImportarManuscritoUseCase;
    FExportarUC: TExportarManuscritoUseCase;
    FRevisarUC: TRevisarCenaUseCase;
    FManterVicioUC: TManterVicioUseCase;
    FMarcarRevisadoUC: TMarcarRevisadoManualUseCase;

    FNovoRepo: INovoRepository;
    FRespostaRepo: IRespostaRepository;
    FViciosRepo: IViciosRepository;
    FCommandStack: TCommandStack;

    FManuscrito: TManuscrito;
    FParseLog: TParseLog;
    FCaminhoAntes: string;
    FCaminhoNovo: string;
    FCaminhoVicios: string;
    FCaminhoParseLog: string;
    FCaminhoEnvio: string;
    FCaminhoResposta: string;
    FCenaSelecionadaAtual: TID;
    FModoAtual: TModoEnvio;

    procedure OnImportar;
    procedure OnExportar;
    procedure OnAbrirVicios;
    procedure OnSelecionarCena(const ACenaID: TID);
    procedure OnMarcarParagrafo(const AParagrafoID: TID;
      const AMarcado: Boolean);
    procedure OnSelecionarVicio;
    procedure OnRevisar;
    procedure OnDesfazer;
    procedure OnMarcarRevisados;
    procedure OnFechar;

    procedure PopularViewAPartirDoManuscrito;
    procedure PopularComboViciosDoCatalogo;
    procedure AtualizarBotoes;
    procedure AtualizarCustoAcumulado;
    procedure RecarregarCenaEmFoco;

    function ConstruirArvore: TArray<TNoArvoreUI>;
    procedure ConstruirNo(const Ato: TAto; out ANo: TNoArvoreUI);
    function ConstruirCenaUI(const ACena: TCena): TCenaUI;
    function EncontrarCapituloDoNo(const AID: TID): TCapitulo;
    function CapituloTemAnomalia(const ACapitulo: TCapitulo;
      out ASeveridade: TSeveridadeAnomalia): Boolean;
    function TituloDaCena(const ACena: TCena): string;

    function PedirConfirmacaoRevisadosJaMarcados(
      const ASelecoes: TArray<TSelecaoUsuario>): Boolean;
    function ResolverParagrafosAlvo(const ACena: TCena): TArray<TID>;

    function DerivarCaminhoVicios(const APastaDestino: string): string;
    function DerivarCaminhoEnvio(const ACaminhoAntes: string): string;
    function DerivarCaminhoResposta(const ACaminhoAntes: string): string;

    procedure LimparSessao;
    procedure EncerrarSessaoAtual;
  public
    constructor Create(const AView: IPrincipalView;
      const AMediador: IMediadorApp;
      const AImportarUC: TImportarManuscritoUseCase;
      const AExportarUC: TExportarManuscritoUseCase;
      const ARevisarUC: TRevisarCenaUseCase;
      const AManterVicioUC: TManterVicioUseCase;
      const AMarcarRevisadoUC: TMarcarRevisadoManualUseCase;
      const ANovoRepo: INovoRepository;
      const ARespostaRepo: IRespostaRepository;
      const AViciosRepo: IViciosRepository;
      const ACommandStack: TCommandStack);

    destructor Destroy; override;

    procedure Iniciar;
  end;

implementation

uses
  System.IOUtils;

{ TPrincipalPresenter }

constructor TPrincipalPresenter.Create(const AView: IPrincipalView;
  const AMediador: IMediadorApp;
  const AImportarUC: TImportarManuscritoUseCase;
  const AExportarUC: TExportarManuscritoUseCase;
  const ARevisarUC: TRevisarCenaUseCase;
  const AManterVicioUC: TManterVicioUseCase;
  const AMarcarRevisadoUC: TMarcarRevisadoManualUseCase;
  const ANovoRepo: INovoRepository;
  const ARespostaRepo: IRespostaRepository;
  const AViciosRepo: IViciosRepository;
  const ACommandStack: TCommandStack);
begin
  inherited Create;

  if not Assigned(AView) then
    raise EValorInvalido.Create('IPrincipalView não pode ser nil.');
  if not Assigned(AMediador) then
    raise EValorInvalido.Create('IMediadorApp não pode ser nil.');
  if not Assigned(AImportarUC) then
    raise EValorInvalido.Create('TImportarManuscritoUseCase não pode ser nil.');
  if not Assigned(AExportarUC) then
    raise EValorInvalido.Create('TExportarManuscritoUseCase não pode ser nil.');
  if not Assigned(ARevisarUC) then
    raise EValorInvalido.Create('TRevisarCenaUseCase não pode ser nil.');
  if not Assigned(AManterVicioUC) then
    raise EValorInvalido.Create('TManterVicioUseCase não pode ser nil.');
  if not Assigned(AMarcarRevisadoUC) then
    raise EValorInvalido.Create('TMarcarRevisadoManualUseCase não pode ser nil.');
  if not Assigned(ANovoRepo) then
    raise EValorInvalido.Create('INovoRepository não pode ser nil.');
  if not Assigned(ARespostaRepo) then
    raise EValorInvalido.Create('IRespostaRepository não pode ser nil.');
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');
  if not Assigned(ACommandStack) then
    raise EValorInvalido.Create('TCommandStack não pode ser nil.');

  FView := AView;
  FMediador := AMediador;
  FImportarUC := AImportarUC;
  FExportarUC := AExportarUC;
  FRevisarUC := ARevisarUC;
  FManterVicioUC := AManterVicioUC;
  FMarcarRevisadoUC := AMarcarRevisadoUC;
  FNovoRepo := ANovoRepo;
  FRespostaRepo := ARespostaRepo;
  FViciosRepo := AViciosRepo;
  FCommandStack := ACommandStack;

  FCenaSelecionadaAtual := '';
  FModoAtual := meCirurgico;
end;

destructor TPrincipalPresenter.Destroy;
begin
  FreeAndNil(FParseLog);
  FreeAndNil(FManuscrito);
  inherited;
end;

procedure TPrincipalPresenter.Iniciar;
begin
  FView.AoImportar := OnImportar;
  FView.AoExportar := OnExportar;
  FView.AoAbrirVicios := OnAbrirVicios;
  FView.AoSelecionarCena := OnSelecionarCena;
  FView.AoMarcarParagrafo := OnMarcarParagrafo;
  FView.AoSelecionarVicio := OnSelecionarVicio;
  FView.AoRevisar := OnRevisar;
  FView.AoClicarDesfazer := OnDesfazer;
  FView.AoMarcarRevisados := OnMarcarRevisados;
  FView.AoFechar := OnFechar;

  FView.AtualizarTitulo('(nenhum manuscrito)');
  FView.LimparArvore;
  FView.LimparCena;
  AtualizarBotoes;
  AtualizarCustoAcumulado;
  FView.AtualizarBarraStatus(
    'Pronto. Importe um manuscrito .docx para começar.');
end;

// ────────────────────────────────────────────────────────────
// Handlers
// ────────────────────────────────────────────────────────────

procedure TPrincipalPresenter.OnImportar;
var
  CaminhoDocx, PastaDestino: string;
  Importacao: TImportacao;
begin
  CaminhoDocx := FView.PerguntarCaminhoDocx;
  if CaminhoDocx = '' then
    Exit;

  PastaDestino := TPath.Combine(
    TPath.GetDirectoryName(CaminhoDocx), 'EditorManuscrito_dados');

  Importacao := nil;
  try
    EncerrarSessaoAtual;

    FMediador.ExecutarComLoading('Importando manuscrito...',
      procedure
      begin
        Importacao := FImportarUC.Executar(
          CaminhoDocx, PastaDestino, DerivarCaminhoVicios(PastaDestino));
      end);

    if Importacao = nil then
      Exit;

    try
      FCaminhoAntes := Importacao.CaminhoAntes;
      FCaminhoNovo := Importacao.CaminhoNovo;
      FCaminhoVicios := Importacao.CaminhoVicios;
      FCaminhoParseLog := Importacao.CaminhoParseLog;
      FCaminhoEnvio := DerivarCaminhoEnvio(FCaminhoAntes);
      FCaminhoResposta := DerivarCaminhoResposta(FCaminhoAntes);

      FManuscrito := Importacao.ResultadoParse.DetachManuscrito;
      FParseLog := Importacao.ResultadoParse.DetachLog;
    finally
      Importacao.Free;
    end;

    PopularViewAPartirDoManuscrito;
    PopularComboViciosDoCatalogo;
    AtualizarBotoes;
    AtualizarCustoAcumulado;

    FView.ExibirInfo(Format(
      'Manuscrito importado.' + sLineBreak +
      'Antes: %s' + sLineBreak +
      'Novo: %s',
      [ExtractFileName(FCaminhoAntes),
       ExtractFileName(FCaminhoNovo)]));
  except
    on E: Exception do
    begin
      EncerrarSessaoAtual;
      FView.ExibirErro('Falha ao importar: ' + E.Message);
    end;
  end;
end;

procedure TPrincipalPresenter.OnExportar;
var
  CaminhoSaida: string;
  Exportacao: TExportacao;
  Sugestao: string;
begin
  if FManuscrito = nil then
  begin
    FView.ExibirAviso('Nenhum manuscrito carregado.');
    Exit;
  end;

  Sugestao := ChangeFileExt(ExtractFileName(FCaminhoAntes), '') +
    '_revisado.docx';
  CaminhoSaida := FView.PerguntarCaminhoSaidaDocx(Sugestao);
  if CaminhoSaida = '' then
    Exit;

  Exportacao := nil;
  try
    FNovoRepo.SalvarAuto(FManuscrito, FCaminhoNovo);

    FMediador.ExecutarComLoading('Exportando manuscrito...',
      procedure
      begin
        Exportacao := FExportarUC.Executar(FCaminhoNovo, CaminhoSaida);
      end);

    if Exportacao = nil then
      Exit;

    try
      FView.ExibirInfo(Exportacao.ResumoTextual);
    finally
      Exportacao.Free;
    end;
  except
    on E: Exception do
      FView.ExibirErro('Falha ao exportar: ' + E.Message);
  end;
end;

procedure TPrincipalPresenter.OnAbrirVicios;
begin
  if FCaminhoVicios = '' then
  begin
    FView.ExibirAviso(
      'Nenhum catálogo de vícios disponível ainda. ' +
      'Importe um manuscrito primeiro.');
    Exit;
  end;

  FMediador.AbrirVicios(FCaminhoVicios,
    procedure
    begin
      PopularComboViciosDoCatalogo;
      AtualizarBotoes;
    end);
end;

procedure TPrincipalPresenter.OnSelecionarCena(const ACenaID: TID);
var
  Cena: TCena;
  CenaUI: TCenaUI;
begin
  if FManuscrito = nil then
    Exit;

  Cena := FManuscrito.CenaPorID(ACenaID);
  if not Assigned(Cena) then
    Exit;

  FCenaSelecionadaAtual := ACenaID;

  CenaUI := ConstruirCenaUI(Cena);
  try
    FView.ExibirCena(CenaUI, TituloDaCena(Cena));
  finally
    CenaUI.Free;
  end;

  AtualizarBotoes;
end;

procedure TPrincipalPresenter.OnMarcarParagrafo(const AParagrafoID: TID;
  const AMarcado: Boolean);
begin
  AtualizarBotoes;
end;

procedure TPrincipalPresenter.OnSelecionarVicio;
begin
  AtualizarBotoes;
end;

procedure TPrincipalPresenter.OnRevisar;
var
  Selecoes: TArray<TSelecaoUsuario>;
  Params: TParametrosRevisao;
  Resposta: TResposta;
  Contexto: TContextoRevisao;
  Cena: TCena;
  Vicio: string;
  Lista: TList<TSelecaoUsuario>;
  IDs: TArray<TID>;
  ID: TID;
begin
  if FManuscrito = nil then
  begin
    FView.ExibirAviso('Nenhum manuscrito carregado.');
    Exit;
  end;

  if FCenaSelecionadaAtual = '' then
  begin
    FView.ExibirAviso('Selecione uma cena na árvore antes de revisar.');
    Exit;
  end;

  Cena := FManuscrito.CenaPorID(FCenaSelecionadaAtual);
  if not Assigned(Cena) then
  begin
    FView.ExibirAviso('Cena não encontrada.');
    Exit;
  end;

  Vicio := FView.VicioSelecionado;
  if Vicio = '' then
  begin
    FView.ExibirAviso('Escolha um vício no seletor antes de revisar.');
    Exit;
  end;

  IDs := ResolverParagrafosAlvo(Cena);

  Lista := TList<TSelecaoUsuario>.Create;
  try
    for ID in IDs do
      Lista.Add(TSelecaoUsuario.Create(ID, Vicio));
    Selecoes := Lista.ToArray;
  finally
    Lista.Free;
  end;

  if Length(Selecoes) = 0 then
  begin
    FView.ExibirAviso('A cena não tem parágrafos.');
    Exit;
  end;

  if not PedirConfirmacaoRevisadosJaMarcados(Selecoes) then
    Exit;

  Params.CaminhoNovo := FCaminhoNovo;
  Params.CaminhoVicios := FCaminhoVicios;
  Params.CaminhoEnvio := FCaminhoEnvio;
  Params.CaminhoResposta := FCaminhoResposta;
  Params.CenaID := FCenaSelecionadaAtual;
  Params.Modo := meCirurgico;
  Params.Selecoes := Selecoes;
  Params.Observacao := '';

  Resposta := nil;
  try
    FMediador.ExecutarComLoading('Consultando IA...',
      procedure
      begin
        Resposta := FRevisarUC.Executar(Params);
      end);
  except
    on E: Exception do
    begin
      FView.ExibirErro('Falha na revisão: ' + E.Message);
      Exit;
    end;
  end;

  if Resposta = nil then
    Exit;

  Contexto := TContextoRevisao.Create(
    FManuscrito,
    Resposta,
    FCaminhoNovo,
    FCaminhoVicios,
    FCaminhoEnvio,
    FCaminhoResposta,
    FCenaSelecionadaAtual,
    meCirurgico,
    Resposta.IDChamada,
    False);

  FMediador.AbrirRevisao(Contexto,
    procedure
    begin
      RecarregarCenaEmFoco;
      AtualizarBotoes;
      AtualizarCustoAcumulado;
    end);
end;

procedure TPrincipalPresenter.OnDesfazer;
begin
  if FManuscrito = nil then
    Exit;
  if not FCommandStack.PodeDesfazer then
    Exit;

  FCommandStack.DesfazerUltimo;
  FNovoRepo.SalvarAuto(FManuscrito, FCaminhoNovo);

  RecarregarCenaEmFoco;
  AtualizarBotoes;
end;

procedure TPrincipalPresenter.OnMarcarRevisados;
var
  Cena: TCena;
  IDs: TArray<TID>;
  Alterados: Integer;
begin
  if FManuscrito = nil then
    Exit;
  if FCenaSelecionadaAtual = '' then
    Exit;

  Cena := FManuscrito.CenaPorID(FCenaSelecionadaAtual);
  if not Assigned(Cena) then
    Exit;

  IDs := ResolverParagrafosAlvo(Cena);

  if Length(IDs) = 0 then
    Exit;

  Alterados := FMarcarRevisadoUC.ExecutarLote(
    FManuscrito, FCaminhoNovo, IDs);

  if Alterados = 0 then
  begin
    FView.ExibirInfo(
      'Nenhum parágrafo alterado. Só é possível alternar entre ' +
      '"pendente" e "revisado manual" — parágrafos já revisados ' +
      'pela IA não são alterados por esta ação.');
    Exit;
  end;

  RecarregarCenaEmFoco;
  AtualizarBotoes;
  FView.AtualizarBarraStatus(Format('%d parágrafo(s) alterado(s).',
    [Alterados]));
end;

procedure TPrincipalPresenter.OnFechar;
begin
  // V2: checar autosave pendente.
end;

// ────────────────────────────────────────────────────────────
// Auxiliares — popular View
// ────────────────────────────────────────────────────────────

procedure TPrincipalPresenter.PopularViewAPartirDoManuscrito;
var
  Arvore: TArray<TNoArvoreUI>;
begin
  if FManuscrito = nil then
  begin
    FView.LimparArvore;
    FView.LimparCena;
    FView.AtualizarTitulo('(nenhum manuscrito)');
    FCenaSelecionadaAtual := '';
    Exit;
  end;

  FView.AtualizarTitulo(FManuscrito.Titulo);

  Arvore := ConstruirArvore;
  FView.ExibirArvore(Arvore);

  FView.LimparCena;
end;

procedure TPrincipalPresenter.RecarregarCenaEmFoco;
var
  Cena: TCena;
  CenaUI: TCenaUI;
begin
  if FManuscrito = nil then
  begin
    FView.LimparCena;
    Exit;
  end;

  if FCenaSelecionadaAtual = '' then
  begin
    FView.LimparCena;
    Exit;
  end;

  Cena := FManuscrito.CenaPorID(FCenaSelecionadaAtual);
  if not Assigned(Cena) then
  begin
    FCenaSelecionadaAtual := '';
    FView.LimparCena;
    Exit;
  end;

  CenaUI := ConstruirCenaUI(Cena);
  try
    FView.ExibirCena(CenaUI, TituloDaCena(Cena));
  finally
    CenaUI.Free;
  end;
end;

procedure TPrincipalPresenter.PopularComboViciosDoCatalogo;
var
  Catalogo: TCatalogoVicios;
  IDs: TArray<string>;
  V: TVicio;
  Lista: TList<string>;
begin
  if FCaminhoVicios = '' then
    Exit;

  Catalogo := FViciosRepo.Carregar(FCaminhoVicios);
  try
    Lista := TList<string>.Create;
    try
      for V in Catalogo.Categorias do
        Lista.Add(V.ID);
      IDs := Lista.ToArray;
    finally
      Lista.Free;
    end;
  finally
    Catalogo.Free;
  end;

  FView.PopularComboVicios(IDs);
end;

procedure TPrincipalPresenter.AtualizarBotoes;
var
  Cena: TCena;
  TemCena, TemVicio: Boolean;
begin
  Cena := nil;
  if (FManuscrito <> nil) and (FCenaSelecionadaAtual <> '') then
    Cena := FManuscrito.CenaPorID(FCenaSelecionadaAtual);

  TemCena := Assigned(Cena) and (Cena.Paragrafos.Count > 0);
  TemVicio := FView.VicioSelecionado <> '';

  FView.HabilitarImportar(True);
  FView.HabilitarRevisar(TemCena and TemVicio);
  FView.HabilitarMarcarRevisados(TemCena);
  FView.HabilitarExportar(FManuscrito <> nil);
  FView.HabilitarDesfazer(
    (FManuscrito <> nil) and FCommandStack.PodeDesfazer,
    FCommandStack.DescricaoUltimo);
end;

procedure TPrincipalPresenter.AtualizarCustoAcumulado;
var
  CaminhoResp: string;
  Custo: Double;
begin
  if FCaminhoAntes = '' then
  begin
    FView.AtualizarCustoAcumulado('');
    Exit;
  end;

  try
    CaminhoResp := DerivarCaminhoResposta(FCaminhoAntes);
    Custo := FRespostaRepo.CustoAcumulado(CaminhoResp);
    FView.AtualizarCustoAcumulado(Format('Custo acumulado: $%.4f', [Custo]));
  except
    FView.AtualizarCustoAcumulado('');
  end;
end;

// ────────────────────────────────────────────────────────────
// Construção de tipos UI
// ────────────────────────────────────────────────────────────

function TPrincipalPresenter.ConstruirArvore: TArray<TNoArvoreUI>;
var
  Lista: TList<TNoArvoreUI>;
  Ato: TAto;
  NoAto: TNoArvoreUI;
begin
  Lista := TList<TNoArvoreUI>.Create;
  try
    for Ato in FManuscrito.Atos do
    begin
      ConstruirNo(Ato, NoAto);
      Lista.Add(NoAto);
    end;
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

procedure TPrincipalPresenter.ConstruirNo(const Ato: TAto;
  out ANo: TNoArvoreUI);
var
  Cap: TCapitulo;
  NoCap, NoCena: TNoArvoreUI;
  Cena: TCena;
  ListaCaps, ListaCenas: TList<TNoArvoreUI>;
  Severidade: TSeveridadeAnomalia;
begin
  ANo := TNoArvoreUI.Create;
  ANo.ID := Ato.ID;
  ANo.Tipo := naAto;
  ANo.Nome := Format('Ato %d', [Ato.Numero]);

  ListaCaps := TList<TNoArvoreUI>.Create;
  try
    for Cap in Ato.Capitulos do
    begin
      NoCap := TNoArvoreUI.Create;
      NoCap.ID := Cap.ID;
      NoCap.Tipo := naCapitulo;
      NoCap.Nome := Format('Cap. %d — %s', [Cap.Numero, Cap.Titulo]);

      NoCap.TemAnomalia := CapituloTemAnomalia(Cap, Severidade);
      NoCap.Severidade := Severidade;

      ListaCenas := TList<TNoArvoreUI>.Create;
      try
        for Cena in Cap.Cenas do
        begin
          NoCena := TNoArvoreUI.Create;
          NoCena.ID := Cena.ID;
          NoCena.Tipo := naCena;
          NoCena.Nome := Format('Cena %d.%d', [Cap.Numero, Cena.Numero]);
          ListaCenas.Add(NoCena);
        end;
        NoCap.Filhos := ListaCenas.ToArray;
      finally
        ListaCenas.Free;
      end;

      ListaCaps.Add(NoCap);
    end;
    ANo.Filhos := ListaCaps.ToArray;
  finally
    ListaCaps.Free;
  end;
end;

function TPrincipalPresenter.ConstruirCenaUI(const ACena: TCena): TCenaUI;
var
  Par: TParagrafo;
  ParUI: TParagrafoUI;
begin
  Result := TCenaUI.Create;
  Result.CenaID := ACena.ID;
  Result.Numero := ACena.Numero;

  for Par in ACena.Paragrafos do
  begin
    ParUI := TParagrafoUI.Create;
    ParUI.ParagrafoID := Par.ID;
    ParUI.Ordem := Par.Ordem;
    ParUI.Texto := Par.Texto;
    ParUI.HashParagrafo := Par.Hash;
    ParUI.Status := Par.Status;
    ParUI.NumChunks := Par.NumChunks;
    ParUI.VicioMarcado := '';
    Result.Paragrafos.Add(ParUI);
  end;
end;

function TPrincipalPresenter.TituloDaCena(const ACena: TCena): string;
var
  Cap: TCapitulo;
begin
  Cap := EncontrarCapituloDoNo(ACena.ID);
  if Assigned(Cap) then
    Result := Format('Cap. %d — Cena %d.%d',
      [Cap.Numero, Cap.Numero, ACena.Numero])
  else
    Result := Format('Cena %d', [ACena.Numero]);
end;

function TPrincipalPresenter.EncontrarCapituloDoNo(
  const AID: TID): TCapitulo;
var
  Ato: TAto;
  Cap: TCapitulo;
  Cena: TCena;
begin
  for Ato in FManuscrito.Atos do
    for Cap in Ato.Capitulos do
    begin
      if Cap.ID = AID then
        Exit(Cap);
      for Cena in Cap.Cenas do
        if Cena.ID = AID then
          Exit(Cap);
    end;
  Result := nil;
end;

function TPrincipalPresenter.CapituloTemAnomalia(
  const ACapitulo: TCapitulo;
  out ASeveridade: TSeveridadeAnomalia): Boolean;
var
  A: TAnomaliaParse;
  Maior: TSeveridadeAnomalia;
begin
  Result := False;
  Maior := saInfo;
  ASeveridade := saInfo;

  if FParseLog = nil then
    Exit;

  for A in FParseLog.Anomalias do
  begin
    if (A.Localizacao = ACapitulo.ID) or
       (A.Localizacao = 'cap-' + IntToStr(ACapitulo.Numero)) then
    begin
      Result := True;
      if A.Severidade = saErro then
        Maior := saErro
      else if (A.Severidade = saAviso) and (Maior <> saErro) then
        Maior := saAviso;
    end;
  end;

  ASeveridade := Maior;
end;

// ────────────────────────────────────────────────────────────
// Validação
// ────────────────────────────────────────────────────────────

function TPrincipalPresenter.ResolverParagrafosAlvo(
  const ACena: TCena): TArray<TID>;
var
  IDsMarcados: TArray<TID>;
  Lista: TList<TID>;
  Par: TParagrafo;
  ID: TID;
begin
  IDsMarcados := FView.ParagrafosSelecionadosIDs;

  if Length(IDsMarcados) > 0 then
  begin
    Lista := TList<TID>.Create;
    try
      for ID in IDsMarcados do
        if Assigned(ACena.ParagrafoPorID(ID)) then
          Lista.Add(ID);
      Result := Lista.ToArray;
    finally
      Lista.Free;
    end;
    Exit;
  end;

  Lista := TList<TID>.Create;
  try
    for Par in ACena.Paragrafos do
      Lista.Add(Par.ID);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TPrincipalPresenter.PedirConfirmacaoRevisadosJaMarcados(
  const ASelecoes: TArray<TSelecaoUsuario>): Boolean;
var
  S: TSelecaoUsuario;
  Par: TParagrafo;
  JaRevisados: Integer;
begin
  JaRevisados := 0;
  for S in ASelecoes do
  begin
    Par := FManuscrito.ParagrafoPorID(S.ParagrafoID);
    if Assigned(Par) and (Par.Status <> spPendente) then
      Inc(JaRevisados);
  end;

  if JaRevisados = 0 then
    Exit(True);

  Result := FView.Confirmar(Format(
    '%d dos %d parágrafos selecionados já foram revisados. ' +
    'Revisar mesmo assim (custo extra de IA)?',
    [JaRevisados, Length(ASelecoes)]));
end;

// ────────────────────────────────────────────────────────────
// Sessão
// ────────────────────────────────────────────────────────────

function TPrincipalPresenter.DerivarCaminhoVicios(
  const APastaDestino: string): string;
begin
  Result := TPath.Combine(APastaDestino, 'vicios.json');
end;

function TPrincipalPresenter.DerivarCaminhoEnvio(
  const ACaminhoAntes: string): string;
begin
  Result := TPath.Combine(
    TPath.GetDirectoryName(ACaminhoAntes),
    TPath.GetFileNameWithoutExtension(ACaminhoAntes) + '_envio.json');
end;

function TPrincipalPresenter.DerivarCaminhoResposta(
  const ACaminhoAntes: string): string;
begin
  Result := TPath.Combine(
    TPath.GetDirectoryName(ACaminhoAntes),
    TPath.GetFileNameWithoutExtension(ACaminhoAntes) + '_resposta.json');
end;

procedure TPrincipalPresenter.LimparSessao;
begin
  FCaminhoAntes := '';
  FCaminhoNovo := '';
  FCaminhoVicios := '';
  FCaminhoParseLog := '';
  FCaminhoEnvio := '';
  FCaminhoResposta := '';
  FCenaSelecionadaAtual := '';
  FreeAndNil(FManuscrito);
  FreeAndNil(FParseLog);
end;

procedure TPrincipalPresenter.EncerrarSessaoAtual;
begin
  LimparSessao;
  FCommandStack.Limpar;
  FView.LimparArvore;
  FView.LimparCena;
end;

end.
