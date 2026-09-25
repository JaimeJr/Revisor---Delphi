unit UValores;

{
  UValores.pas
  ─────────────────────────────────────────────────────────────
  Tipos base do domínio: enums, identificadores, exceções e
  constantes de regra de negócio.

  Nenhuma dependência externa (VCL, HTTP, JSON, OfficeXML).
  Toda conversão string <-> enum é explícita e case-insensitive,
  para que o formato persistido em JSON não dependa da ordem
  ordinal dos enums (que pode mudar entre versões do compilador).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Identificador único de uma entidade do domínio.
  /// </summary>
  /// <remarks>
  ///   Formatos esperados:
  ///     act-N                       → Ato
  ///     cap-N                       → Capítulo
  ///     cap-N-cena-N                → Cena
  ///     cap-N-cena-N-pNN            → Parágrafo (NN com 2+ dígitos)
  /// </remarks>
  TID = string;

  /// <summary>
  ///   Modo de envio de uma revisão à IA.
  /// </summary>
  TModoEnvio = (
    /// <summary>Apenas os parágrafos e vícios marcados pelo usuário.</summary>
    meCirurgico,
    /// <summary>Cena inteira + catálogo completo de vícios.</summary>
    meVarredura
  );

  /// <summary>
  ///   Status de um parágrafo dentro do Novo.JSON.
  /// </summary>
  TStatusParagrafo = (
    /// <summary>Ainda não revisado.</summary>
    spPendente,
    /// <summary>Pelo menos uma revisão foi aceita.</summary>
    spAceito,
    /// <summary>Revisão recusada, sem aceite posterior.</summary>
    spRecusado,
    /// <summary>Usuário leu e decidiu não mexer.</summary>
    spRevisadoManual,
    /// <summary>Usuário alterou o texto sem passar pela IA.</summary>
    spEditadoManual
  );

  /// <summary>
  ///   Resultado do parse da resposta da IA.
  /// </summary>
  TStatusParse = (
    /// <summary>JSON válido, edições extraídas com sucesso.</summary>
    spOK,
    /// <summary>Resposta não é JSON válido — usuário inspeciona a bruta.</summary>
    spParseError,
    /// <summary>IA não encontrou vício no trecho enviado.</summary>
    spVazio,
    /// <summary>IA sugeriu edição fora do escopo enviado.</summary>
    spForaEscopo
  );

  /// <summary>
  ///   Severidade de uma anomalia detectada durante o parse do .docx.
  /// </summary>
  TSeveridadeAnomalia = (
    /// <summary>Comportamento esperado, vale registrar.</summary>
    saInfo,
    /// <summary>Fora do padrão, mas recuperável.</summary>
    saAviso,
    /// <summary>Impede o processamento correto.</summary>
    saErro
  );

  /// <summary>
  ///   Tipo específico de anomalia detectada pelo parser do manuscrito.
  /// </summary>
  TTipoAnomalia = (
    taConteudoAntesDoPrimeiroCapitulo,
    taCapituloSemCena,
    taSequenciaCapitulosQuebrada,
    taDocumentoSemHeading1,
    taNumeroCapitulosDivergente,
    taArquivoVazio,
    taDoisHeadingsSeguidos
  );

  /// <summary>
  ///   Origem de uma categoria no catálogo de vícios.
  /// </summary>
  TOrigemVicio = (
    /// <summary>Semente distribuída com o sistema.</summary>
    ovGenerico,
    /// <summary>Adicionada manualmente pelo autor.</summary>
    ovAutor
  );

  // ────────────────────────────────────────────────────────────
  // Exceções do domínio
  // ────────────────────────────────────────────────────────────

  /// <summary>Raiz de todas as exceções do domínio.</summary>
  EDominio = class(Exception);

  /// <summary>
  ///   Lançada quando uma conversão ou validação de valor falha
  ///   (ex: string de enum desconhecida).
  /// </summary>
  EValorInvalido = class(EDominio);

  /// <summary>
  ///   Lançada quando uma operação não faz sentido dado o estado
  ///   atual de uma entidade (ex: aceitar edição de parágrafo já aceito).
  /// </summary>
  EOperacaoInvalida = class(EDominio);

  // ────────────────────────────────────────────────────────────
  // Helpers de conversão string <-> enum
  //
  // Todos seguem o mesmo contrato:
  //   • ToStr  → sempre retorna minúsculo, sem acento.
  //   • FromStr → case-insensitive; lança EValorInvalido se
  //               o texto não corresponder a um valor válido.
  // ────────────────────────────────────────────────────────────

  TModoEnvioHelper = record helper for TModoEnvio
    function ToStr: string;
    class function FromStr(const S: string): TModoEnvio; static;
  end;

  TStatusParagrafoHelper = record helper for TStatusParagrafo
    function ToStr: string;
    class function FromStr(const S: string): TStatusParagrafo; static;
  end;

  TStatusParseHelper = record helper for TStatusParse
    function ToStr: string;
    class function FromStr(const S: string): TStatusParse; static;
  end;

  TSeveridadeAnomaliaHelper = record helper for TSeveridadeAnomalia
    function ToStr: string;
    class function FromStr(const S: string): TSeveridadeAnomalia; static;
  end;

  TTipoAnomaliaHelper = record helper for TTipoAnomalia
    function ToStr: string;
    class function FromStr(const S: string): TTipoAnomalia; static;
  end;

  TOrigemVicioHelper = record helper for TOrigemVicio
    function ToStr: string;
    class function FromStr(const S: string): TOrigemVicio; static;
  end;

  // ────────────────────────────────────────────────────────────
  // Constantes de regra de negócio
  // ────────────────────────────────────────────────────────────

const
  /// <summary>Capítulos por ato. Ato I: 1-7, Ato II: 8-14, Ato III: 15-21.</summary>
  CAPITULOS_POR_ATO = 7;

  /// <summary>Total de capítulos esperados em um manuscrito completo.</summary>
  CAPITULOS_TOTAIS = 21;

  /// <summary>Acima deste número de palavras, um parágrafo é dividido em chunks.</summary>
  LIMITE_PARAGRAFO_PALAVRAS = 600;

  /// <summary>Tamanho-alvo de cada chunk ao dividir um parágrafo grande.</summary>
  TAMANHO_CHUNK_PALAVRAS = 300;

  /// <summary>Frases de sobreposição entre chunks consecutivos (contexto de borda).</summary>
  SOBREPOSICAO_CHUNK_FRASES = 1;

  VICIO_VARREDURA = '(varredura)';

implementation

// ────────────────────────────────────────────────────────────
// TModoEnvio
// ────────────────────────────────────────────────────────────

function TModoEnvioHelper.ToStr: string;
begin
  case Self of
    meCirurgico: Result := 'cirurgico';
    meVarredura: Result := 'varredura';
  else
    raise EValorInvalido.Create('TModoEnvio: valor desconhecido.');
  end;
end;

class function TModoEnvioHelper.FromStr(const S: string): TModoEnvio;
begin
  if SameText(S, 'cirurgico') then Exit(meCirurgico);
  if SameText(S, 'varredura') then Exit(meVarredura);
  raise EValorInvalido.CreateFmt('TModoEnvio: valor inválido "%s".', [S]);
end;

// ────────────────────────────────────────────────────────────
// TStatusParagrafo
// ────────────────────────────────────────────────────────────

function TStatusParagrafoHelper.ToStr: string;
begin
  case Self of
    spPendente:       Result := 'pendente';
    spAceito:         Result := 'aceito';
    spRecusado:       Result := 'recusado';
    spRevisadoManual: Result := 'revisado_manual';
    spEditadoManual:  Result := 'editado_manual';
  else
    raise EValorInvalido.Create('TStatusParagrafo: valor desconhecido.');
  end;
end;

class function TStatusParagrafoHelper.FromStr(const S: string): TStatusParagrafo;
begin
  if SameText(S, 'pendente')        then Exit(spPendente);
  if SameText(S, 'aceito')          then Exit(spAceito);
  if SameText(S, 'recusado')        then Exit(spRecusado);
  if SameText(S, 'revisado_manual') then Exit(spRevisadoManual);
  if SameText(S, 'editado_manual')  then Exit(spEditadoManual);
  raise EValorInvalido.CreateFmt('TStatusParagrafo: valor inválido "%s".', [S]);
end;

// ────────────────────────────────────────────────────────────
// TStatusParse
// ────────────────────────────────────────────────────────────

function TStatusParseHelper.ToStr: string;
begin
  case Self of
    spOK:         Result := 'ok';
    spParseError: Result := 'parse_error';
    spVazio:      Result := 'vazio';
    spForaEscopo: Result := 'fora_escopo';
  else
    raise EValorInvalido.Create('TStatusParse: valor desconhecido.');
  end;
end;

class function TStatusParseHelper.FromStr(const S: string): TStatusParse;
begin
  if SameText(S, 'ok')          then Exit(spOK);
  if SameText(S, 'parse_error') then Exit(spParseError);
  if SameText(S, 'vazio')       then Exit(spVazio);
  if SameText(S, 'fora_escopo') then Exit(spForaEscopo);
  raise EValorInvalido.CreateFmt('TStatusParse: valor inválido "%s".', [S]);
end;

// ────────────────────────────────────────────────────────────
// TSeveridadeAnomalia
// ────────────────────────────────────────────────────────────

function TSeveridadeAnomaliaHelper.ToStr: string;
begin
  case Self of
    saInfo:  Result := 'info';
    saAviso: Result := 'aviso';
    saErro:  Result := 'erro';
  else
    raise EValorInvalido.Create('TSeveridadeAnomalia: valor desconhecido.');
  end;
end;

class function TSeveridadeAnomaliaHelper.FromStr(const S: string): TSeveridadeAnomalia;
begin
  if SameText(S, 'info')  then Exit(saInfo);
  if SameText(S, 'aviso') then Exit(saAviso);
  if SameText(S, 'erro')  then Exit(saErro);
  raise EValorInvalido.CreateFmt('TSeveridadeAnomalia: valor inválido "%s".', [S]);
end;

// ────────────────────────────────────────────────────────────
// TTipoAnomalia
// ────────────────────────────────────────────────────────────

function TTipoAnomaliaHelper.ToStr: string;
begin
  case Self of
    taConteudoAntesDoPrimeiroCapitulo: Result := 'conteudo_antes_primeiro_capitulo';
    taCapituloSemCena:                 Result := 'capitulo_sem_cena';
    taSequenciaCapitulosQuebrada:      Result := 'sequencia_capitulos_quebrada';
    taDocumentoSemHeading1:            Result := 'documento_sem_heading_1';
    taNumeroCapitulosDivergente:       Result := 'numero_capitulos_divergente';
    taArquivoVazio:                    Result := 'arquivo_vazio';
    taDoisHeadingsSeguidos:            Result := 'dois_headings_seguidos';
  else
    raise EValorInvalido.Create('TTipoAnomalia: valor desconhecido.');
  end;
end;

class function TTipoAnomaliaHelper.FromStr(const S: string): TTipoAnomalia;
begin
  if SameText(S, 'conteudo_antes_primeiro_capitulo') then Exit(taConteudoAntesDoPrimeiroCapitulo);
  if SameText(S, 'capitulo_sem_cena')                then Exit(taCapituloSemCena);
  if SameText(S, 'sequencia_capitulos_quebrada')     then Exit(taSequenciaCapitulosQuebrada);
  if SameText(S, 'documento_sem_heading_1')          then Exit(taDocumentoSemHeading1);
  if SameText(S, 'numero_capitulos_divergente')      then Exit(taNumeroCapitulosDivergente);
  if SameText(S, 'arquivo_vazio')                    then Exit(taArquivoVazio);
  if SameText(S, 'dois_headings_seguidos')           then Exit(taDoisHeadingsSeguidos);
  raise EValorInvalido.CreateFmt('TTipoAnomalia: valor inválido "%s".', [S]);
end;

// ────────────────────────────────────────────────────────────
// TOrigemVicio
// ────────────────────────────────────────────────────────────

function TOrigemVicioHelper.ToStr: string;
begin
  case Self of
    ovGenerico: Result := 'generico';
    ovAutor:    Result := 'autor';
  else
    raise EValorInvalido.Create('TOrigemVicio: valor desconhecido.');
  end;
end;

class function TOrigemVicioHelper.FromStr(const S: string): TOrigemVicio;
begin
  if SameText(S, 'generico') then Exit(ovGenerico);
  if SameText(S, 'autor')    then Exit(ovAutor);
  raise EValorInvalido.CreateFmt('TOrigemVicio: valor inválido "%s".', [S]);
end;

end.
