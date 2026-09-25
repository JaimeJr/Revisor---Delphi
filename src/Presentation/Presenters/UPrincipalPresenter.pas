unit UPrincipalPresenter;

{
  UPrincipalPresenter.pas
  ─────────────────────────────────────────────────────────────
  Presenter da tela principal.

  Modelo atual (após simplificação do painel direito):
    • Seleção é por CENA, exclusivamente via árvore.
    • O painel direito só exibe o capítulo (um TMemo por cena).
    • Não há checkbox por parágrafo.

  Estado da sessão no Presenter:
    • FManuscrito            — Novo.JSON em memória
    • FParseLog              — log de anomalias do parse
    • FCaminho*              — caminhos dos JSONs da sessão
    • FCenaSelecionadaAtual  — cena em foco (vazio = nenhuma)

  Ownership:
    • FManuscrito e FParseLog: do Presenter (desanexados do
      TImportacao no OnImportar).
    • Não é dono do CommandStack (compartilhado).
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

    // ─── UseCases ───
    FImportarUC: TImportarManuscritoUseCase;
    FExportarUC: TExportarManuscritoUseCase;
    FRevisarUC: TRevisarCenaUseCase;
    FManterVicioUC: TManterVicioUseCase;
    FMarcarRevisadoUC: TMarcarRevisadoManualUseCase;

    // ─── Infra mínima ───
    FNovoRepo: INovoRepository;
    FRespostaRepo: IRespostaRepository;
    FViciosRepo: IViciosRepository;
    FCommandStack: TCommandStack;

    // ─── Estado da sessão ───
    FManuscrito: TManuscrito;
    FParseLog: TParseLog;
    FCaminhoAntes: string;
    FCaminhoNovo: string;
    FCaminhoVicios: string;
    FCaminhoParseLog: string;
    FCenaSelecionadaAtual: TID;
    FModoAtual: TModoEnvio;

    // ─── Handlers dos eventos da View ───
    procedure OnImportar;
    procedure OnExportar;
    procedure OnAbrirVicios;
    procedure OnSelecionarCena(const ACenaID: TID);
    procedure OnSelecionarVicio;
    procedure OnRevisar;
    procedure OnDesfazer;
    procedure OnMarcarRevisados;
    procedure OnFechar;

    // ─── Auxiliares — popular View ───
    procedure PopularViewAPartirDoManuscrito;
    procedure PopularComboViciosDoCatalogo;
    procedure AtualizarBotoes;
    procedure AtualizarCustoAcumulado;

    // ─── Auxiliares — construção de tipos UI ───
    function ConstruirArvore: TArray<TNoArvoreUI>;
    procedure ConstruirNo(const Ato: TAto; out ANo: TNoArvoreUI);
    procedure ConstruirCapitulo(const ACapitulo: TCapitulo;
      out ACapituloUI: TCapituloUI);
    function EncontrarCapituloDoNo(const AID: TID): TCapitulo;
    function CapituloTemAnomalia(const ACapitulo: TCapitulo;
      out ASeveridade: TSeveridadeAnomalia): Boolean;

    // ─── Auxiliares — validação e conversão ───
    function PedirConfirmacaoRevisadosJaMarcados(
      const ASelecoes: TArray<TSelecaoUsuario>): Boolean;
    function ConverterRespostaParaUI(const AResposta: TResposta): TRevisaoUI;

    // ─── Auxiliares — sessão ───
    function DerivarCaminhoVicios(const APastaDestino: string): string;
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
  FView.AoSelecionarVicio := OnSelecionarVicio;
  FView.AoRevisar := OnRevisar;
  FView.AoClicarDesfazer := OnDesfazer;
  FView.AoMarcarRevisados := OnMarcarRevisados;
  FView.AoFechar := OnFechar;

  FView.AtualizarTitulo('(nenhum manuscrito)');
  FView.LimparArvore;
  FView.LimparCapitulo;
  AtualizarBotoes;
  AtualizarCustoAcumulado;
  FView.AtualizarBarraStatus(
    'Pronto. Importe um manuscrito .docx para começar.');
end;

// ────────────────────────────────────────────────────────────
// Handlers dos eventos
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
      // Recarrega o combo — o usuário pode ter adicionado vícios.
      PopularComboViciosDoCatalogo;
      AtualizarBotoes;
    end);
end;

procedure TPrincipalPresenter.OnSelecionarCena(const ACenaID: TID);
var
  Cena: TCena;
  Capitulo: TCapitulo;
  CapituloUI: TCapituloUI;
begin
  if FManuscrito = nil then
    Exit;

  // O ID pode ser de cena ou de capítulo.
  // Tenta como cena primeiro; se falhar, tenta como capítulo.
  Cena := FManuscrito.CenaPorID(ACenaID);
  if Assigned(Cena) then
  begin
    FCenaSelecionadaAtual := ACenaID;
    Capitulo := EncontrarCapituloDoNo(ACenaID);
  end
  else
  begin
    FCenaSelecionadaAtual := '';
    Capitulo := FManuscrito.CapituloPorID(ACenaID);
  end;

  if not Assigned(Capitulo) then
    Exit;

  ConstruirCapitulo(Capitulo, CapituloUI);
  try
    FView.ExibirCapitulo(CapituloUI);
  finally
    CapituloUI.Free;
  end;

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
  Par: TParagrafo;
  Vicio: string;
  Lista: TList<TSelecaoUsuario>;
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

  // Monta a seleção a partir dos parágrafos da cena.
  Lista := TList<TSelecaoUsuario>.Create;
  try
    for Par in Cena.Paragrafos do
      Lista.Add(TSelecaoUsuario.Create(Par.ID, Vicio));
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
    FCenaSelecionadaAtual,
    meCirurgico,
    Resposta.IDChamada,
    False);

  FMediador.AbrirRevisao(Contexto,
    procedure
    begin
      PopularViewAPartirDoManuscrito;
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

  PopularViewAPartirDoManuscrito;
  AtualizarBotoes;
end;

procedure TPrincipalPresenter.OnMarcarRevisados;
var
  Cena: TCena;
  IDs: TArray<TID>;
  Lista: TList<TID>;
  Par: TParagrafo;
  Alterados: Integer;
begin
  if FManuscrito = nil then
    Exit;
  if FCenaSelecionadaAtual = '' then
    Exit;

  Cena := FManuscrito.CenaPorID(FCenaSelecionadaAtual);
  if not Assigned(Cena) then
    Exit;

  Lista := TList<TID>.Create;
  try
    for Par in Cena.Paragrafos do
      Lista.Add(Par.ID);
    IDs := Lista.ToArray;
  finally
    Lista.Free;
  end;

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

  PopularViewAPartirDoManuscrito;
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
  Cena: TCena;
  Capitulo: TCapitulo;
  CapituloUI: TCapituloUI;
begin
  if FManuscrito = nil then
  begin
    FView.LimparArvore;
    FView.LimparCapitulo;
    FView.AtualizarTitulo('(nenhum manuscrito)');
    FCenaSelecionadaAtual := '';
    Exit;
  end;

  FView.AtualizarTitulo(FManuscrito.Titulo);

  // Reconstrói a árvore. A View assume os TNoArvoreUI.
  Arvore := ConstruirArvore;
  FView.ExibirArvore(Arvore);

  // Recarrega o capítulo da cena selecionada, se houver.
  if FCenaSelecionadaAtual = '' then
  begin
    FView.LimparCapitulo;
    Exit;
  end;

  Cena := FManuscrito.CenaPorID(FCenaSelecionadaAtual);
  if not Assigned(Cena) then
  begin
    FCenaSelecionadaAtual := '';
    FView.LimparCapitulo;
    Exit;
  end;

  Capitulo := EncontrarCapituloDoNo(FCenaSelecionadaAtual);
  if not Assigned(Capitulo) then
  begin
    FView.LimparCapitulo;
    Exit;
  end;

  ConstruirCapitulo(Capitulo, CapituloUI);
  try
    FView.ExibirCapitulo(CapituloUI);
  finally
    CapituloUI.Free;
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

  //FView.PopularComboVicios(IDs);
end;

procedure TPrincipalPresenter.AtualizarBotoes;
var
  Cena: TCena;
  TemCena: Boolean;
  TemVicio: Boolean;
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
// Auxiliares — construção de tipos UI
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

procedure TPrincipalPresenter.ConstruirCapitulo(const ACapitulo: TCapitulo;
  out ACapituloUI: TCapituloUI);
var
  Cena: TCena;
  Par: TParagrafo;
  CenaUI: TCenaUI;
  ParUI: TParagrafoUI;
begin
  ACapituloUI := TCapituloUI.Create;
  ACapituloUI.CapituloID := ACapitulo.ID;
  ACapituloUI.Numero := ACapitulo.Numero;
  ACapituloUI.Titulo := ACapitulo.Titulo;

  for Cena in ACapitulo.Cenas do
  begin
    CenaUI := TCenaUI.Create;
    CenaUI.CenaID := Cena.ID;
    CenaUI.Numero := Cena.Numero;

    for Par in Cena.Paragrafos do
    begin
      ParUI := TParagrafoUI.Create;
      ParUI.ParagrafoID := Par.ID;
      ParUI.Ordem := Par.Ordem;
      ParUI.Texto := Par.Texto;
      ParUI.HashParagrafo := Par.Hash;
      ParUI.Status := Par.Status;
      ParUI.NumChunks := Par.NumChunks;
      ParUI.VicioMarcado := '';
      CenaUI.Paragrafos.Add(ParUI);
    end;

    ACapituloUI.Cenas.Add(CenaUI);
  end;
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
// Auxiliares — validação e conversão
// ────────────────────────────────────────────────────────────

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
    '%d dos %d parágrafos da cena já foram revisados. ' +
    'Revisar mesmo assim (custo extra de IA)?',
    [JaRevisados, Length(ASelecoes)]));
end;

function TPrincipalPresenter.ConverterRespostaParaUI(
  const AResposta: TResposta): TRevisaoUI;
var
  Ed: TEdicaoSugerida;
  UI: TEdicaoUI;
  Par: TParagrafo;
begin
  Result := TRevisaoUI.Create;
  Result.CenaID := FCenaSelecionadaAtual;
  Result.Modo := meCirurgico;
  Result.IDChamada := AResposta.IDChamada;
  Result.StatusParse := AResposta.StatusParse;
  Result.VicioGeral := AResposta.VicioGeral;
  Result.ErroParse := AResposta.ErroParse;
  Result.RespostaBruta := AResposta.RespostaBruta;
  Result.TokensPrompt := AResposta.TokensPrompt;
  Result.TokensResposta := AResposta.TokensResposta;
  Result.CustoEstimado := AResposta.CustoEstimado;

  for Ed in AResposta.Edicoes do
  begin
    UI := TEdicaoUI.Create;
    UI.Chave := Ed.Chave;
    UI.ParagrafoID := Ed.ParagrafoID;
    UI.ChunkIndex := Ed.ChunkIndex;
    UI.VicioID := Ed.VicioID;
    UI.TextoSugerido := Ed.Sugerido;
    UI.Motivo := Ed.Motivo;
    UI.DentroEscopo := AResposta.EdicaoDentroDoEscopo(Ed);
    UI.Selecionada := False;
    UI.Aplicada := Ed.Aplicada;

    Par := FManuscrito.ParagrafoPorID(Ed.ParagrafoID);
    if Assigned(Par) then
      UI.TextoAntigo := Par.Texto
    else
      UI.TextoAntigo := '';

    Result.Edicoes.Add(UI);
  end;
end;

// ────────────────────────────────────────────────────────────
// Auxiliares — sessão
// ────────────────────────────────────────────────────────────

function TPrincipalPresenter.DerivarCaminhoVicios(
  const APastaDestino: string): string;
begin
  Result := TPath.Combine(APastaDestino, 'vicios.json');
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
  FCenaSelecionadaAtual := '';
  FreeAndNil(FManuscrito);
  FreeAndNil(FParseLog);
end;

procedure TPrincipalPresenter.EncerrarSessaoAtual;
begin
  LimparSessao;
  FCommandStack.Limpar;
  FView.LimparArvore;
  FView.LimparCapitulo;
end;

end.
