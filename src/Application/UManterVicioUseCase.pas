unit UManterVicioUseCase;

{
  UManterVicioUseCase.pas
  ─────────────────────────────────────────────────────────────
  Caso de uso que mantém o catálogo editorial (Vicios.JSON):
  adicionar, atualizar e remover categorias.

  Regras:
    • Vídeos de origem "generico" (sementes do sistema) NÃO
      podem ser removidos nem ter o ID alterado.
    • Vídeos de origem "autor" (adicionados pelo usuário) podem
      ser editados livremente e removidos.
    • Descrição, dica de correção, gatilho local e flag de
      cross-cena são editáveis em qualquer categoria — inclusive
      nas sementes. Só o ID e a origem são protegidos.
    • Adicionar com ID já existente é rejeitado (não sobrescreve).
    • Toda operação bem-sucedida salva o catálogo (bump de versão
      acontece no repositório/entidade).

  Validação de ID:
    • Não vazio.
    • Só [a-z0-9_], minúsculo.
    • Não começa com número.
    • Tamanho máximo: 40 caracteres.
    Razão: o ID vira chave de cache, valor em JSON e (futuramente)
    parte de nome de arquivo em logs. Restringir evita dor de
    cabeça com encoding e case-insensitivity.

  Ownership:
    • O TCatalogoVicios é carregado e liberado dentro de cada
      método. O chamador não vê.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UIViciosRepository,
  UVicio,
  UValores;

type
  /// <summary>
  ///   Resultado de uma operação de manutenção do catálogo.
  ///   Record pequeno, sem dependências de domínio.
  /// </summary>
  TOperacaoVicio = record
    Sucesso: Boolean;
    Motivo: string;   // preenchido só quando Sucesso = False
  end;

  TManterVicioUseCase = class
  private
    FViciosRepo: IViciosRepository;

    function ValidarID(const AID: string; out AMotivo: string): Boolean;

    /// <summary>
    ///   Carrega o catálogo, aplica uma transformação e salva.
    ///   Devolve o resultado da transformação.
    ///   A transformação recebe o catálogo já carregado.
    /// </summary>
    function ExecutarTransacao(const ACaminhoVicios: string;
      const ATransformacao: TFunc<TCatalogoVicios, TOperacaoVicio>): TOperacaoVicio;
  public
    constructor Create(const AViciosRepo: IViciosRepository);

    /// <summary>
    ///   Adiciona uma nova categoria. Origem é sempre ovAutor.
    /// </summary>
    function Adicionar(const ACaminhoVicios, AID, ANome, ADescricao,
      ADicaCorrecao, AGatilhoLocal: string;
      APrecisaCrossCena: Boolean): TOperacaoVicio;

    /// <summary>
    ///   Atualiza os campos editáveis de uma categoria existente.
    ///   Não altera ID nem origem. Não permite esvaziar nome.
    /// </summary>
    function Atualizar(const ACaminhoVicios, AID, ANome, ADescricao,
      ADicaCorrecao, AGatilhoLocal: string;
      APrecisaCrossCena: Boolean): TOperacaoVicio;

    /// <summary>
    ///   Remove uma categoria. Só permite se a origem for ovAutor.
    /// </summary>
    function Remover(const ACaminhoVicios, AID: string): TOperacaoVicio;
  end;

implementation

uses
  System.RegularExpressions;

const
  REGEX_ID_VALIDO = '^[a-z][a-z0-9_]{0,39}$';

{ TManterVicioUseCase }

constructor TManterVicioUseCase.Create(const AViciosRepo: IViciosRepository);
begin
  inherited Create;
  if not Assigned(AViciosRepo) then
    raise EValorInvalido.Create('IViciosRepository não pode ser nil.');
  FViciosRepo := AViciosRepo;
end;

function TManterVicioUseCase.ValidarID(const AID: string;
  out AMotivo: string): Boolean;
begin
  AMotivo := '';

  if AID = '' then
  begin
    AMotivo := 'ID não pode ser vazio.';
    Exit(False);
  end;

  if not TRegEx.IsMatch(AID, REGEX_ID_VALIDO) then
  begin
    AMotivo := 'ID inválido. Use apenas letras minúsculas, números ' +
      'e "_", começando com letra. Máximo 40 caracteres.';
    Exit(False);
  end;

  Result := True;
end;

function TManterVicioUseCase.ExecutarTransacao(const ACaminhoVicios: string;
  const ATransformacao: TFunc<TCatalogoVicios, TOperacaoVicio>): TOperacaoVicio;
var
  Catalogo: TCatalogoVicios;
begin
  if ACaminhoVicios = '' then
    raise EValorInvalido.Create('CaminhoVicios não pode ser vazio.');
  if not Assigned(ATransformacao) then
    raise EValorInvalido.Create('Transformação não pode ser nil.');

  Catalogo := FViciosRepo.Carregar(ACaminhoVicios);
  try
    Result := ATransformacao(Catalogo);

    // Só salva se a transformação marcou sucesso.
    // Se falhou, o catálogo em memória pode ter sido tocado
    // em parte, mas como carregamos de novo a cada chamada,
    // nada foi persistido.
    if Result.Sucesso then
      FViciosRepo.Salvar(Catalogo, ACaminhoVicios);
  finally
    Catalogo.Free;
  end;
end;

function TManterVicioUseCase.Adicionar(const ACaminhoVicios, AID, ANome,
  ADescricao, ADicaCorrecao, AGatilhoLocal: string;
  APrecisaCrossCena: Boolean): TOperacaoVicio;
var
  MotivoID: string;
begin
  Result.Sucesso := False;
  Result.Motivo := '';

  if not ValidarID(AID, MotivoID) then
  begin
    Result.Motivo := MotivoID;
    Exit;
  end;

  if ANome.Trim = '' then
  begin
    Result.Motivo := 'Nome não pode ser vazio.';
    Exit;
  end;

  Result := ExecutarTransacao(ACaminhoVicios,
    function(ACat: TCatalogoVicios): TOperacaoVicio
    var
      V: TVicio;
    begin
      Result.Sucesso := False;
      Result.Motivo := '';

      if ACat.Existe(AID) then
      begin
        Result.Motivo := Format(
          'Já existe um vício com ID "%s". Use Atualizar para editá-lo.', [AID]);
        Exit;
      end;

      V := TVicio.Create;
      V.ID := AID;
      V.Nome := ANome.Trim;
      V.Origem := ovAutor;
      V.Descricao := ADescricao.Trim;
      V.DicaCorrecao := ADicaCorrecao.Trim;
      V.GatilhoLocal := AGatilhoLocal.Trim;
      V.PrecisaCrossCena := APrecisaCrossCena;

      ACat.Adicionar(V);
      Result.Sucesso := True;
    end);
end;

function TManterVicioUseCase.Atualizar(const ACaminhoVicios, AID, ANome,
  ADescricao, ADicaCorrecao, AGatilhoLocal: string;
  APrecisaCrossCena: Boolean): TOperacaoVicio;
begin
  Result.Sucesso := False;
  Result.Motivo := '';

  if AID.Trim = '' then
  begin
    Result.Motivo := 'ID não pode ser vazio.';
    Exit;
  end;

  if ANome.Trim = '' then
  begin
    Result.Motivo := 'Nome não pode ser vazio.';
    Exit;
  end;

  Result := ExecutarTransacao(ACaminhoVicios,
    function(ACat: TCatalogoVicios): TOperacaoVicio
    var
      V: TVicio;
    begin
      Result.Sucesso := False;
      Result.Motivo := '';

      V := ACat.VicioPorID(AID);
      if not Assigned(V) then
      begin
        Result.Motivo := Format('Vício "%s" não existe.', [AID]);
        Exit;
      end;

      // Edita só os campos mutáveis. ID e Origem ficam intactos.
      V.Nome := ANome.Trim;
      V.Descricao := ADescricao.Trim;
      V.DicaCorrecao := ADicaCorrecao.Trim;
      V.GatilhoLocal := AGatilhoLocal.Trim;
      V.PrecisaCrossCena := APrecisaCrossCena;

      ACat.MarcarAlterado;
      Result.Sucesso := True;
    end);
end;

function TManterVicioUseCase.Remover(const ACaminhoVicios,
  AID: string): TOperacaoVicio;
begin
  Result.Sucesso := False;
  Result.Motivo := '';

  if AID.Trim = '' then
  begin
    Result.Motivo := 'ID não pode ser vazio.';
    Exit;
  end;

  Result := ExecutarTransacao(ACaminhoVicios,
    function(ACat: TCatalogoVicios): TOperacaoVicio
    var
      V: TVicio;
    begin
      Result.Sucesso := False;
      Result.Motivo := '';

      V := ACat.VicioPorID(AID);
      if not Assigned(V) then
      begin
        Result.Motivo := Format('Vício "%s" não existe.', [AID]);
        Exit;
      end;

      if V.EhGenerico then
      begin
        Result.Motivo :=
          'Vícios originais do sistema não podem ser removidos. ' +
          'Você pode editá-los, mas não excluí-los.';
        Exit;
      end;

      ACat.Remover(AID);
      Result.Sucesso := True;
    end);
end;

end.
