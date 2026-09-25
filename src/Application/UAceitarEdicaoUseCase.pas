unit UAceitarEdicaoUseCase;

{
  UAceitarEdicaoUseCase.pas
  ─────────────────────────────────────────────────────────────
  Caso de uso que aceita UMA edição da IA e persiste o resultado.

  Fluxo:
    1. Localiza o parágrafo no manuscrito em memória.
    2. Captura o texto ANTERIOR (para alimentar o exemplo em
       Vicios.JSON — o exemplo deve mostrar o trecho que tinha
       o vício, não o corrigido).
    3. Cria TAceitarEdicaoCommand e o executa via command stack
       (undo/redo de graça).
    4. Alimenta Vicios.JSON: registra ocorrência com exemplo.
       Se o VicioID não existir no catálogo (vício detectado
       pela IA e ainda não cadastrado), NÃO bloqueia o aceite
       — apenas não registra a ocorrência. O usuário cadastra
       o vício depois via UAdicionarVicioUseCase.
    5. Salva Novo.JSON (autosave).
    6. Salva Vicios.JSON se houve alteração.

  Retorno:
    • True  → aceite aplicado e persistido.
    • False → parágrafo não encontrado no manuscrito (não é erro
              fatal — só sinaliza à UI que o alvo sumiu).

  Ownership:
    • O Manuscrito é do chamador — recebido por parâmetro, não
      liberado aqui. É o mesmo objeto que a UI mantém em memória
      durante toda a sessão.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UManuscrito,
  UEdicaoSugerida,
  UVicio,
  UAceitarEdicaoCommand,
  UCommandStack,
  UINovoRepository,
  UIViciosRepository,
  UValores,
  UIComandoEditorial;

type
  TAceitarEdicaoUseCase = class
  private
    FNovoRepo: INovoRepository;
    FViciosRepo: IViciosRepository;
    FCommandStack: TCommandStack;

    /// <summary>
    ///   Localiza a cena que contém o parágrafo. Necessário
    ///   para preencher o CenaID do exemplo em Vicios.JSON.
    /// </summary>
    function LocalizarCenaDoParagrafo(const AManuscrito: TManuscrito;
      const AParagrafoID: TID): TID;

    /// <summary>
    ///   Registra a ocorrência em Vicios.JSON, se o vício existir
    ///   no catálogo. Retorna True se registrou.
    /// </summary>
    function RegistrarOcorrencia(const ACatalogo: TCatalogoVicios;
      const ACenaID, AParagrafoID, ATrechoAnterior,
      AVicioID, AIDChamada: string): Boolean;
  public
    constructor Create(const ANovoRepo: INovoRepository;
      const AViciosRepo: IViciosRepository;
      const ACommandStack: TCommandStack);

    /// <summary>
    ///   Executa o aceite. AManuscrito deve ser o Novo.JSON já
    ///   carregado em memória pela UI.
    /// </summary>
    function Executar(const AManuscrito: TManuscrito;
      const ACaminhoNovo, ACaminhoVicios: string;
      const AEdicao: TEdicaoSugerida;
      const AIDChamada: string): Boolean;
  end;

implementation

uses
  System.IOUtils;

{ TAceitarEdicaoUseCase }

constructor TAceitarEdicaoUseCase.Create(const ANovoRepo: INovoRepository;
  const AViciosRepo: IViciosRepository;
  const ACommandStack: TCommandStack);
begin
  inherited Create;

  if not Assigned(ANovoRepo) then
    raise EValorInvalido.Create('INovoRepository não pode ser nil.');
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');
  if not Assigned(ACommandStack) then
    raise EValorInvalido.Create('TCommandStack não pode ser nil.');

  FNovoRepo := ANovoRepo;
  FViciosRepo := AViciosRepo;
  FCommandStack := ACommandStack;
end;

function TAceitarEdicaoUseCase.LocalizarCenaDoParagrafo(
  const AManuscrito: TManuscrito; const AParagrafoID: TID): TID;
var
  Ato: TAto;
  Cap: TCapitulo;
  Cena: TCena;
  Par: TParagrafo;
begin
  for Ato in AManuscrito.Atos do
    for Cap in Ato.Capitulos do
      for Cena in Cap.Cenas do
        for Par in Cena.Paragrafos do
          if Par.ID = AParagrafoID then
            Exit(Cena.ID);
  Result := '';
end;

function TAceitarEdicaoUseCase.RegistrarOcorrencia(
  const ACatalogo: TCatalogoVicios;
  const ACenaID, AParagrafoID, ATrechoAnterior,
  AVicioID, AIDChamada: string): Boolean;
var
  Exemplo: TExemploManuscrito;
begin
  if not ACatalogo.Existe(AVicioID) then
    Exit(False);

  Exemplo := TExemploManuscrito.Create;
  try
    Exemplo.CenaID := ACenaID;
    Exemplo.ParagrafoID := AParagrafoID;
    Exemplo.Trecho := ATrechoAnterior;
    Exemplo.IDChamada := AIDChamada;
    Exemplo.Timestamp := Now;

    Result := ACatalogo.RegistrarOcorrencia(AVicioID, Exemplo);
    if not Result then
      Exemplo.Free;  // RegistrarOcorrencia só assume ownership se aceitou
  except
    Exemplo.Free;
    raise;
  end;
end;

function TAceitarEdicaoUseCase.Executar(const AManuscrito: TManuscrito;
  const ACaminhoNovo, ACaminhoVicios: string;
  const AEdicao: TEdicaoSugerida;
  const AIDChamada: string): Boolean;
var
  Paragrafo: TParagrafo;
  CenaID: TID;
  TrechoAnterior: string;
  Catalogo: TCatalogoVicios;
  Cmd: IComandoEditorial;
  RegistrouOcorrencia: Boolean;
begin
  // ─── Validações ───
  if not Assigned(AManuscrito) then
    raise EValorInvalido.Create('Manuscrito não pode ser nil.');
  if not Assigned(AEdicao) then
    raise EValorInvalido.Create('Edição não pode ser nil.');
  if not AEdicao.EhValida then
    raise EValorInvalido.Create(
      'Edição precisa ter parágrafo, vício e texto sugerido.');
  if ACaminhoNovo = '' then
    raise EValorInvalido.Create('CaminhoNovo não pode ser vazio.');
  if ACaminhoVicios = '' then
    raise EValorInvalido.Create('CaminhoVicios não pode ser vazio.');

  // ─── 1. Localiza o parágrafo ───
  Paragrafo := AManuscrito.ParagrafoPorID(AEdicao.ParagrafoID);
  if not Assigned(Paragrafo) then
    Exit(False);

  // ─── 2. Captura estado ANTES do comando ───
  TrechoAnterior := Paragrafo.Texto;
  CenaID := LocalizarCenaDoParagrafo(AManuscrito, AEdicao.ParagrafoID);

  // ─── 3. Executa o comando via stack ───
  Cmd := TAceitarEdicaoCommand.Create(Paragrafo, AEdicao, AIDChamada);
  FCommandStack.Executar(Cmd);

  // ─── 4. Alimenta Vicios.JSON ───
  Catalogo := FViciosRepo.Carregar(ACaminhoVicios);
  try
    RegistrouOcorrencia := RegistrarOcorrencia(
      Catalogo, CenaID, AEdicao.ParagrafoID, TrechoAnterior,
      AEdicao.VicioID, AIDChamada);

    if RegistrouOcorrencia then
      FViciosRepo.Salvar(Catalogo, ACaminhoVicios);
  finally
    Catalogo.Free;
  end;

  // ─── 5. Autosave do Novo.JSON ───
  FNovoRepo.SalvarAuto(AManuscrito, ACaminhoNovo);

  Result := True;
end;

end.
