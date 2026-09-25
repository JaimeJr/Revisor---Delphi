unit UViciosPresenter;

{
  UViciosPresenter.pas
  ─────────────────────────────────────────────────────────────
  Presenter da tela de catálogo de vícios.

  Responsabilidades:
    • Carregar o catálogo via IViciosRepository.
    • Converter TVicio em TVicioUI para a View.
    • Rotear operações (adicionar/atualizar/remover) no UseCase.
    • Recarregar a lista após cada operação bem-sucedida.

  Estado:
    • FModoNovo: quando o usuário clica Novo, guardamos isso
      aqui. No Salvar, decidimos entre Adicionar e Atualizar.
    • FSelecionadoID: qual vício está selecionado na lista.

  Ownership:
    • O Presenter é dono dos TVicioUI que constrói (FCacheVicios).
    • A View recebe a lista em ExibirCatalogo apenas para ler
      os IDs — NÃO assume ownership.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UIViciosView,
  UManterVicioUseCase,
  UIViciosRepository,
  UVicio,
  UTiposUI,
  UValores;

type
  TViciosPresenter = class
  private
    FView: IUViciosView;
    FUseCase: TManterVicioUseCase;
    FViciosRepo: IViciosRepository;
    FCaminhoVicios: string;

    FCacheVicios: TObjectList<TVicioUI>;
    FModoNovo: Boolean;
    FSelecionadoID: string;

    // ─── Handlers ───
    procedure OnSelecionarVicio(const AID: string);
    procedure OnNovoVicio;
    procedure OnSalvarVicio(const AID, ANome, ADescricao,
      ADica, AGatilho: string; const APrecisaCrossCena: Boolean);
    procedure OnRemoverVicio(const AID: string);
    procedure OnFechar;

    // ─── Auxiliares ───
    procedure RecarregarCatalogo(const AManterSelecao: Boolean);
    function AcharVicioUI(const AID: string): TVicioUI;
    function ConverterVicio(const AVicio: TVicio): TVicioUI;
  public
    constructor Create(const AView: IUViciosView;
      const AUseCase: TManterVicioUseCase;
      const AViciosRepo: IViciosRepository;
      const ACaminhoVicios: string);

    destructor Destroy; override;

    procedure Iniciar;
  end;

implementation

{ TViciosPresenter }

constructor TViciosPresenter.Create(const AView: IUViciosView;
  const AUseCase: TManterVicioUseCase;
  const AViciosRepo: IViciosRepository;
  const ACaminhoVicios: string);
begin
  inherited Create;

  if not Assigned(AView) then
    raise EValorInvalido.Create('IUViciosView não pode ser nil.');
  if not Assigned(AUseCase) then
    raise EValorInvalido.Create('TManterVicioUseCase não pode ser nil.');
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');
  if ACaminhoVicios = '' then
    raise EValorInvalido.Create('CaminhoVicios não pode ser vazio.');

  FView := AView;
  FUseCase := AUseCase;
  FViciosRepo := AViciosRepo;
  FCaminhoVicios := ACaminhoVicios;
  FCacheVicios := TObjectList<TVicioUI>.Create;
end;

destructor TViciosPresenter.Destroy;
begin
  FCacheVicios.Free;
  inherited;
end;

procedure TViciosPresenter.Iniciar;
begin
  FView.AoSelecionarVicio := OnSelecionarVicio;
  FView.AoNovoVicio := OnNovoVicio;
  FView.AoSalvarVicio := OnSalvarVicio;
  FView.AoRemoverVicio := OnRemoverVicio;
  FView.AoFechar := OnFechar;

  RecarregarCatalogo(False);
  FView.ExibirDetalhe(nil);
end;

// ────────────────────────────────────────────────────────────
// Handlers
// ────────────────────────────────────────────────────────────

procedure TViciosPresenter.OnSelecionarVicio(const AID: string);
var
  V: TVicioUI;
begin
  V := AcharVicioUI(AID);
  if V = nil then
    Exit;

  FModoNovo := False;
  FSelecionadoID := AID;
  FView.ExibirDetalhe(V);
end;

procedure TViciosPresenter.OnNovoVicio;
begin
  FModoNovo := True;
  FSelecionadoID := '';
  FView.EntrarModoNovo;
end;

procedure TViciosPresenter.OnSalvarVicio(const AID, ANome, ADescricao,
  ADica, AGatilho: string; const APrecisaCrossCena: Boolean);
var
  Resultado: TOperacaoVicio;
  FoiAdicionar: Boolean;
begin
  FoiAdicionar := FModoNovo;

  FView.MostrarProgresso('Salvando...');
  try
    if FoiAdicionar then
      Resultado := FUseCase.Adicionar(FCaminhoVicios, AID, ANome,
        ADescricao, ADica, AGatilho, APrecisaCrossCena)
    else
      Resultado := FUseCase.Atualizar(FCaminhoVicios, AID, ANome,
        ADescricao, ADica, AGatilho, APrecisaCrossCena);
  finally
    FView.OcultarProgresso;
  end;

  if not Resultado.Sucesso then
  begin
    FView.ExibirErro(Resultado.Motivo);
    Exit;
  end;

  if FoiAdicionar then
    FView.ExibirInfo(Format('Vício "%s" adicionado.', [AID]))
  else
    FView.ExibirInfo(Format('Vício "%s" atualizado.', [AID]));

  FModoNovo := False;
  FSelecionadoID := AID;

  RecarregarCatalogo(True);

  var V := AcharVicioUI(AID);
  if Assigned(V) then
    FView.ExibirDetalhe(V);
end;

procedure TViciosPresenter.OnRemoverVicio(const AID: string);
var
  Resultado: TOperacaoVicio;
begin
  FView.MostrarProgresso('Removendo...');
  try
    Resultado := FUseCase.Remover(FCaminhoVicios, AID);
  finally
    FView.OcultarProgresso;
  end;

  if not Resultado.Sucesso then
  begin
    FView.ExibirErro(Resultado.Motivo);
    Exit;
  end;

  FView.ExibirInfo(Format('Vício "%s" removido.', [AID]));
  FModoNovo := False;
  FSelecionadoID := '';

  RecarregarCatalogo(False);
  FView.ExibirDetalhe(nil);
end;

procedure TViciosPresenter.OnFechar;
begin
  // Nada a persistir — cada operação já salvou.
end;

// ────────────────────────────────────────────────────────────
// Auxiliares
// ────────────────────────────────────────────────────────────

procedure TViciosPresenter.RecarregarCatalogo(
  const AManterSelecao: Boolean);
var
  Catalogo: TCatalogoVicios;
  Lista: TArray<TVicioUI>;
  V: TVicio;
  I: Integer;
  UI: TVicioUI;
begin
  FCacheVicios.Clear;

  Catalogo := FViciosRepo.Carregar(FCaminhoVicios);
  try
    SetLength(Lista, Catalogo.Categorias.Count);
    for I := 0 to Catalogo.Categorias.Count - 1 do
    begin
      V := Catalogo.Categorias[I];
      UI := ConverterVicio(V);
      Lista[I] := UI;
      FCacheVicios.Add(UI);  // Presenter mantém a cópia própria
    end;
  finally
    Catalogo.Free;
  end;

  // A View só lê os IDs em ExibirCatalogo — não assume ownership
  // dos TVicioUI (eles continuam sendo do FCacheVicios).
  FView.ExibirCatalogo(Lista);

  if AManterSelecao and (FSelecionadoID <> '') then
    FView.SelecionarNaLista(FSelecionadoID);
end;

function TViciosPresenter.AcharVicioUI(const AID: string): TVicioUI;
var
  V: TVicioUI;
begin
  for V in FCacheVicios do
    if V.ID = AID then
      Exit(V);
  Result := nil;
end;

function TViciosPresenter.ConverterVicio(const AVicio: TVicio): TVicioUI;
begin
  Result := TVicioUI.Create;
  Result.ID := AVicio.ID;
  Result.Nome := AVicio.Nome;
  Result.Origem := AVicio.Origem;
  Result.Descricao := AVicio.Descricao;
  Result.DicaCorrecao := AVicio.DicaCorrecao;
  Result.GatilhoLocal := AVicio.GatilhoLocal;
  Result.PrecisaCrossCena := AVicio.PrecisaCrossCena;
  Result.FrequenciaNoManuscrito := AVicio.FrequenciaNoManuscrito;
end;

end.
