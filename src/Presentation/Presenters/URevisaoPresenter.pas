unit URevisaoPresenter;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Classes,
  UIRevisaoView,
  UIMediadorApp,
  URevisarCenaUseCase,
  UAceitarEdicaoUseCase,
  URecusarEdicaoUseCase,
  UManuscrito,
  UEdicaoSugerida,
  UTiposUI,
  UValores;

type
  TRevisaoPresenter = class
  private
    FView: IRevisaoView;
    FMediador: IMediadorApp;

    FAceitarUC: TAceitarEdicaoUseCase;
    FRecusarUC: TRecusarEdicaoUseCase;
    FRevisarUC: TRevisarCenaUseCase;

    FContexto: TContextoRevisao;   // não owned
    FRevisaoUI: TRevisaoUI;         // owned
    FOnFechada: TProcRevisaoFechada;

    // ─── Handlers dos eventos ───
    procedure OnMarcarEdicao(const AChave: string; const AMarcada: Boolean);
    procedure OnSelecionarEdicao(const AChave: string);
    procedure OnMarcarParagrafo(const AParagrafoID: TID;
      const AMarcada: Boolean);
    procedure OnAceitarSelecionadas;
    procedure OnAceitarTudo;
    procedure OnRecusarTudo;
    procedure OnReenviar;
    procedure OnFecharTela;

    // ─── Auxiliares ───
    function AcharEdicaoPorChave(const AChave: string): TEdicaoUI;
    function AcharEdicaoPorParagrafo(const AParagrafoID: TID): TEdicaoUI;
    function AcharTextoAtualDoParagrafo(const AParagrafoID: TID): string;
    function ReconstruirEdicaoParaUseCase(
      const AEdicaoUI: TEdicaoUI): TEdicaoSugerida;
    function ReconstruirSelecoes: TArray<TSelecaoUsuario>;

    procedure ReconstruirRevisaoUI(const AResposta: TResposta;
      const ACenaID: TID);
    procedure ExibirTextosDe(const AEdicao: TEdicaoUI);
    procedure AtualizarBotoes;

    procedure AceitarLote(const AChaves: TArray<string>);
  public
    constructor Create(const AView: IRevisaoView;
      const AMediador: IMediadorApp;
      const AAceitarUC: TAceitarEdicaoUseCase;
      const ARecusarUC: TRecusarEdicaoUseCase;
      const ARevisarUC: TRevisarCenaUseCase;
      const AContexto: TContextoRevisao;
      const AOnFechada: TProcRevisaoFechada);

    destructor Destroy; override;

    procedure Iniciar;
  end;

implementation

{ TRevisaoPresenter }

constructor TRevisaoPresenter.Create(const AView: IRevisaoView;
  const AMediador: IMediadorApp;
  const AAceitarUC: TAceitarEdicaoUseCase;
  const ARecusarUC: TRecusarEdicaoUseCase;
  const ARevisarUC: TRevisarCenaUseCase;
  const AContexto: TContextoRevisao;
  const AOnFechada: TProcRevisaoFechada);
begin
  inherited Create;

  if not Assigned(AView) then
    raise EValorInvalido.Create('IRevisaoView não pode ser nil.');
  if not Assigned(AMediador) then
    raise EValorInvalido.Create('IMediadorApp não pode ser nil.');
  if not Assigned(AAceitarUC) then
    raise EValorInvalido.Create('TAceitarEdicaoUseCase não pode ser nil.');
  if not Assigned(ARecusarUC) then
    raise EValorInvalido.Create('TRecusarEdicaoUseCase não pode ser nil.');
  if not Assigned(ARevisarUC) then
    raise EValorInvalido.Create('TRevisarCenaUseCase não pode ser nil.');
  if not Assigned(AContexto) then
    raise EValorInvalido.Create('TContextoRevisao não pode ser nil.');

  FView := AView;
  FMediador := AMediador;
  FAceitarUC := AAceitarUC;
  FRecusarUC := ARecusarUC;
  FRevisarUC := ARevisarUC;
  FContexto := AContexto;
  FOnFechada := AOnFechada;
end;

destructor TRevisaoPresenter.Destroy;
begin
  FRevisaoUI.Free;
  inherited;
end;

procedure TRevisaoPresenter.Iniciar;
begin
  // Atribuições diretas — os tipos são `procedure of object`,
  // compatíveis com os métodos do Presenter.
  FView.AoMarcarEdicao := OnMarcarEdicao;
  FView.AoSelecionarEdicao := OnSelecionarEdicao;
  FView.AoMarcarParagrafo := OnMarcarParagrafo;
  FView.AoAceitarSelecionadas := OnAceitarSelecionadas;
  FView.AoAceitarTudo := OnAceitarTudo;
  FView.AoRecusarTudo := OnRecusarTudo;
  FView.AoReenviar := OnReenviar;

  FView.SetOnClose(OnFecharTela);

  FView.AtualizarTitulo(FContexto.CenaID, FContexto.Modo);
  ReconstruirRevisaoUI(FContexto.Resposta, FContexto.CenaID);
  FView.ExibirRevisao(FRevisaoUI);
  AtualizarBotoes;
end;

// ────────────────────────────────────────────────────────────
// Conversão domínio → UI
// ────────────────────────────────────────────────────────────

procedure TRevisaoPresenter.ReconstruirRevisaoUI(
  const AResposta: TResposta; const ACenaID: TID);
var
  Ed: TEdicaoSugerida;
  UI: TEdicaoUI;
begin
  FreeAndNil(FRevisaoUI);
  FRevisaoUI := TRevisaoUI.Create;

  FRevisaoUI.CenaID := ACenaID;
  FRevisaoUI.Modo := FContexto.Modo;
  FRevisaoUI.IDChamada := AResposta.IDChamada;
  FRevisaoUI.StatusParse := AResposta.StatusParse;
  FRevisaoUI.VicioGeral := AResposta.VicioGeral;
  FRevisaoUI.ErroParse := AResposta.ErroParse;
  FRevisaoUI.RespostaBruta := AResposta.RespostaBruta;
  FRevisaoUI.TokensPrompt := AResposta.TokensPrompt;
  FRevisaoUI.TokensResposta := AResposta.TokensResposta;
  FRevisaoUI.CustoEstimado := AResposta.CustoEstimado;

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
    UI.TextoAntigo := AcharTextoAtualDoParagrafo(Ed.ParagrafoID);
    FRevisaoUI.Edicoes.Add(UI);
  end;

  FView.HabilitarExibirRespostaBruta(AResposta.StatusParse = spParseError);
end;

function TRevisaoPresenter.AcharTextoAtualDoParagrafo(
  const AParagrafoID: TID): string;
var
  Par: TParagrafo;
begin
  if FContexto.Manuscrito = nil then
    Exit('');
  Par := FContexto.Manuscrito.ParagrafoPorID(AParagrafoID);
  if Assigned(Par) then
    Result := Par.Texto
  else
    Result := '';
end;

// ────────────────────────────────────────────────────────────
// Auxiliares
// ────────────────────────────────────────────────────────────

function TRevisaoPresenter.AcharEdicaoPorChave(
  const AChave: string): TEdicaoUI;
var
  E: TEdicaoUI;
begin
  for E in FRevisaoUI.Edicoes do
    if E.Chave = AChave then
      Exit(E);
  Result := nil;
end;

function TRevisaoPresenter.AcharEdicaoPorParagrafo(
  const AParagrafoID: TID): TEdicaoUI;
var
  E: TEdicaoUI;
begin
  for E in FRevisaoUI.Edicoes do
    if E.ParagrafoID = AParagrafoID then
      Exit(E);
  Result := nil;
end;

procedure TRevisaoPresenter.ExibirTextosDe(const AEdicao: TEdicaoUI);
begin
  if AEdicao = nil then
    Exit;
  FView.ExibirTextosDoParagrafo(AEdicao.TextoAntigo, AEdicao.TextoSugerido);
end;

procedure TRevisaoPresenter.AtualizarBotoes;
var
  TotalAplicaveis, TotalSelecionadas: Integer;
  E: TEdicaoUI;
begin
  TotalAplicaveis := 0;
  TotalSelecionadas := 0;

  for E in FRevisaoUI.Edicoes do
  begin
    if E.DentroEscopo and not E.Aplicada then
    begin
      Inc(TotalAplicaveis);
      if E.Selecionada then
        Inc(TotalSelecionadas);
    end;
  end;

  FView.HabilitarAceitarSelecionadas(TotalSelecionadas > 0);
  FView.HabilitarAceitarTudo(TotalAplicaveis > 0);
  FView.HabilitarRecusarTudo(FRevisaoUI.Edicoes.Count > 0);
  FView.HabilitarReenviar(True);
end;

// ────────────────────────────────────────────────────────────
// Handlers dos eventos
// ────────────────────────────────────────────────────────────

procedure TRevisaoPresenter.OnMarcarEdicao(const AChave: string;
  const AMarcada: Boolean);
var
  Ed: TEdicaoUI;
begin
  Ed := AcharEdicaoPorChave(AChave);
  if Ed = nil then
    Exit;

  if Ed.Aplicada or not Ed.DentroEscopo then
  begin
    FView.AtualizarEdicaoMarcada(AChave, False);
    Exit;
  end;

  Ed.Selecionada := AMarcada;
  AtualizarBotoes;
end;

procedure TRevisaoPresenter.OnSelecionarEdicao(const AChave: string);
var
  Ed: TEdicaoUI;
begin
  Ed := AcharEdicaoPorChave(AChave);
  ExibirTextosDe(Ed);
end;

procedure TRevisaoPresenter.OnMarcarParagrafo(const AParagrafoID: TID;
  const AMarcada: Boolean);
var
  E: TEdicaoUI;
begin
  for E in FRevisaoUI.Edicoes do
    if (E.ParagrafoID = AParagrafoID) and
       E.DentroEscopo and not E.Aplicada then
    begin
      E.Selecionada := AMarcada;
      FView.AtualizarEdicaoMarcada(E.Chave, AMarcada);
    end;
  AtualizarBotoes;
end;

procedure TRevisaoPresenter.OnAceitarSelecionadas;
begin
  AceitarLote(FView.EdicoesSelecionadas);
end;

procedure TRevisaoPresenter.OnAceitarTudo;
var
  Lista: TList<string>;
  E: TEdicaoUI;
begin
  Lista := TList<string>.Create;
  try
    for E in FRevisaoUI.Edicoes do
      if E.DentroEscopo and not E.Aplicada then
        Lista.Add(E.Chave);
    AceitarLote(Lista.ToArray);
  finally
    Lista.Free;
  end;
end;

procedure TRevisaoPresenter.OnRecusarTudo;
var
  E: TEdicaoUI;
  Falhas: TStringList;
  Recusadas: Integer;
  Edicao: TEdicaoSugerida;
begin
  if FRevisaoUI.Edicoes.Count = 0 then
    Exit;

  if not FView.Confirmar(Format(
    'Recusar todas as %d edições propostas? ' +
    'O texto original permanece intacto.',
    [FRevisaoUI.Edicoes.Count])) then
    Exit;

  Falhas := TStringList.Create;
  Recusadas := 0;
  try
    for E in FRevisaoUI.Edicoes do
    begin
      if E.Aplicada then
        Continue;

      Edicao := ReconstruirEdicaoParaUseCase(E);
      try
        try
          if FRecusarUC.Executar(
            FContexto.Manuscrito,
            FContexto.CaminhoNovo,
            Edicao,
            FContexto.IDChamada) then
            Inc(Recusadas)
          else
            Falhas.Add(Format('%s: parágrafo não encontrado.',
              [E.ParagrafoID]));
        except
          on Ex: Exception do
            Falhas.Add(Format('%s: %s', [E.ParagrafoID, Ex.Message]));
        end;
      finally
        Edicao.Free;
      end;
    end;

    if Falhas.Count > 0 then
      FView.ExibirErro(Format(
        '%d edição(ões) recusada(s). Falhas:' + sLineBreak + '%s',
        [Recusadas, Falhas.Text]))
    else
      FView.ExibirInfo(Format('%d edição(ões) recusada(s).',
        [Recusadas]));
  finally
    Falhas.Free;
  end;

  FView.FecharTela;
end;

procedure TRevisaoPresenter.AceitarLote(const AChaves: TArray<string>);
var
  Chave: string;
  Ed: TEdicaoUI;
  Falhas: TStringList;
  Aceitas: Integer;
  Edicao: TEdicaoSugerida;
begin
  if Length(AChaves) = 0 then
    Exit;

  Falhas := TStringList.Create;
  Aceitas := 0;
  try
    for Chave in AChaves do
    begin
      Ed := AcharEdicaoPorChave(Chave);
      if (Ed = nil) or Ed.Aplicada or not Ed.DentroEscopo then
        Continue;

      Edicao := ReconstruirEdicaoParaUseCase(Ed);
      try
        try
        if FAceitarUC.Executar(
          FContexto.Manuscrito,
          FContexto.CaminhoNovo,
          FContexto.CaminhoVicios,
          Edicao,
          FContexto.IDChamada) then
        begin
          Ed.Aplicada := True;
          Ed.Selecionada := False;
          Inc(Aceitas);
        end
        else
          Falhas.Add(Format('%s: parágrafo não encontrado no manuscrito.',
          [Ed.ParagrafoID]));
        except
        on Ex: Exception do
          Falhas.Add(Format('%s: %s', [Ed.ParagrafoID, Ex.Message]));
        end;
      finally
        Edicao.Free;
      end;
    end;

    // Atualiza checkboxes das aplicadas.
    for Chave in AChaves do
    begin
      Ed := AcharEdicaoPorChave(Chave);
      if (Ed <> nil) and Ed.Aplicada then
        FView.AtualizarEdicaoMarcada(Chave, False);
    end;

    AtualizarBotoes;
  finally
    Falhas.Free;
  end;

  if Falhas.Count > 0 then
    FView.ExibirErro(Format(
      '%d edição(ões) aplicada(s). Falhas:' + sLineBreak + '%s',
      [Aceitas, Falhas.Text]))
  else
    FView.ExibirInfo(Format('%d edição(ões) aplicada(s) com sucesso.',
      [Aceitas]));
end;

function TRevisaoPresenter.ReconstruirEdicaoParaUseCase(
  const AEdicaoUI: TEdicaoUI): TEdicaoSugerida;
begin
  Result := TEdicaoSugerida.Create;
  Result.ParagrafoID := AEdicaoUI.ParagrafoID;
  Result.ChunkIndex := AEdicaoUI.ChunkIndex;
  Result.VicioID := AEdicaoUI.VicioID;
  Result.Sugerido := AEdicaoUI.TextoSugerido;
  Result.Motivo := AEdicaoUI.Motivo;
end;

function TRevisaoPresenter.ReconstruirSelecoes: TArray<TSelecaoUsuario>;
var
  Lista: TList<TSelecaoUsuario>;
  Vistos: TDictionary<string, Boolean>;
  E: TEdicaoUI;
  Chave: string;
begin
  Lista := TList<TSelecaoUsuario>.Create;
  Vistos := TDictionary<string, Boolean>.Create;
  try
    for E in FRevisaoUI.Edicoes do
    begin
      Chave := E.ParagrafoID + '|' + E.VicioID;
      if Vistos.ContainsKey(Chave) then
        Continue;
      Vistos.Add(Chave, True);
      Lista.Add(TSelecaoUsuario.Create(E.ParagrafoID, E.VicioID));
    end;
    Result := Lista.ToArray;
  finally
    Vistos.Free;
    Lista.Free;
  end;
end;

// ────────────────────────────────────────────────────────────
// Reenvio
// ────────────────────────────────────────────────────────────

procedure TRevisaoPresenter.OnReenviar;
var
  Obs: string;
  Params: TParametrosRevisao;
  NovaResposta: TResposta;
begin
  Obs := FMediador.PerguntarObservacaoReenvio;
  if Obs.Trim = '' then
    Exit;

  Params.CaminhoNovo := FContexto.CaminhoNovo;
  Params.CaminhoVicios := FContexto.CaminhoVicios;
  Params.CenaID := FContexto.CenaID;
  Params.Modo := FContexto.Modo;
  Params.Selecoes := ReconstruirSelecoes;
  Params.Observacao := Obs;

  FView.MostrarProgresso('Reenviando à IA...');
  try
    try
      NovaResposta := FRevisarUC.Executar(Params);
    except
      on E: Exception do
      begin
        FView.OcultarProgresso;
        FView.ExibirErro('Falha no reenvio: ' + E.Message);
        Exit;
      end;
    end;

    // Substitui a resposta no contexto (libera a antiga).
    FContexto.SubstituirResposta(NovaResposta);
    ReconstruirRevisaoUI(FContexto.Resposta, FContexto.CenaID);
    FView.ExibirRevisao(FRevisaoUI);
    AtualizarBotoes;
  finally
    FView.OcultarProgresso;
  end;
end;

// ────────────────────────────────────────────────────────────
// Fechamento
// ────────────────────────────────────────────────────────────

procedure TRevisaoPresenter.OnFecharTela;
begin
  if Assigned(FOnFechada) then
    FOnFechada();
end;

end.
