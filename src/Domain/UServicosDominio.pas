unit UServicosDominio;

{
  UServicosDominio.pas
  ─────────────────────────────────────────────────────────────
  Serviços de domínio: cálculos puros, validação e chunking.
  Nenhuma dependência de I/O, HTTP, VCL ou JSON.

  Três serviços:
    • TCalculadoraAtos      — mapeamento capítulo → ato
    • TValidadorManuscrito  — sanity check pós-parse
    • TCompressorPayload    — chunking de parágrafos grandes
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UValores,
  UManuscrito,
  UAnomaliaParse;

type
  // ────────────────────────────────────────────────────────────
  // TCalculadoraAtos
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Funções puras para mapear capítulo → ato.
  ///   Regra: Ato I (caps 1-7), Ato II (8-14), Ato III (15-21).
  /// </summary>
  TCalculadoraAtos = class
  public
    /// <summary>
    ///   Retorna o número do ato ao qual o capítulo pertence.
    ///   Lança EValorInvalido se o número estiver fora de 1..21.
    /// </summary>
    class function AtoDoCapitulo(const ANumeroCapitulo: Integer): Integer;

    /// <summary>
    ///   True se o capítulo inicia um novo ato (1, 8, 15).
    /// </summary>
    class function EhInicioDeAto(const ANumeroCapitulo: Integer): Boolean;

    /// <summary>
    ///   Lista os capítulos que compõem um ato.
    ///   Ato 1 → [1..7]; Ato 2 → [8..14]; Ato 3 → [15..21].
    /// </summary>
    class function CapitulosDoAto(const ANumeroAto: Integer): TArray<Integer>;

    /// <summary>
    ///   Lista canônica de todos os capítulos esperados (1..21).
    /// </summary>
    class function TodosOsCapitulos: TArray<Integer>;
  end;

  // ────────────────────────────────────────────────────────────
  // TValidadorManuscrito
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Valida a estrutura de um manuscrito após o parse.
  ///   Não lança — retorna lista de divergências em texto curto,
  ///   para o parser registrar como anomalias informativas.
  /// </summary>
  TValidadorManuscrito = class
  public
    /// <summary>
    ///   Verifica a estrutura completa do manuscrito:
    ///   contagem de atos, capítulos, sequência, capítulos vazios.
    /// </summary>
    class function Validar(const AManuscrito: TManuscrito): TArray<string>;

    /// <summary>
    ///   Verifica se as contagens do resumo batem com o padrão
    ///   (3 atos, 21 capítulos, pelo menos 1 parágrafo).
    /// </summary>
    class function ValidarResumo(const AResumo: TResumoParse): TArray<string>;
  end;

  // ────────────────────────────────────────────────────────────
  // TCompressorPayload
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Utilitário de chunking de parágrafos grandes. Um parágrafo
  ///   com mais de LIMITE_PARAGRAFO_PALAVRAS é dividido em blocos
  ///   de ~TAMANHO_CHUNK_PALAVRAS com sobreposição de
  ///   SOBREPOSICAO_CHUNK_FRASES frases.
  /// </summary>
  TCompressorPayload = class
  public
    /// <summary>
    ///   True se o texto ultrapassa o limite de palavras
    ///   que exige chunking.
    /// </summary>
    class function PrecisaChunking(const ATexto: string): Boolean;

    /// <summary>
    ///   Divide o texto em chunks. Se não precisar chunking,
    ///   retorna array com um único elemento (o texto original).
    ///   Nunca retorna array vazio.
    /// </summary>
    /// <remarks>
    ///   A divisão é feita por frases (segmentadas por . ! ? …),
    ///   acumulando até atingir o alvo de palavras. A última
    ///   frase do chunk anterior é repetida no início do próximo
    ///   (sobreposição) para o modelo não perder contexto de borda.
    /// </remarks>
    class function DividirEmChunks(const ATexto: string): TArray<string>;

    /// <summary>
    ///   Estimativa do número de chunks que o texto geraria.
    ///   Útil para a UI mostrar o badge "p03 (1/3)" antes de
    ///   efetivamente dividir.
    /// </summary>
    class function EstimarNumChunks(const ATexto: string): Integer;

    /// <summary>
    ///   Segmenta um texto em frases. Usado internamente pelo
    ///   chunker e disponível para outros serviços.
    /// </summary>
    class function SegmentarEmFrases(const ATexto: string): TArray<string>;

    /// <summary>Conta palavras no texto (wrapper utilitário).</summary>
    class function ContarPalavras(const ATexto: string): Integer;
  end;

implementation

// ────────────────────────────────────────────────────────────
// TCalculadoraAtos
// ────────────────────────────────────────────────────────────

class function TCalculadoraAtos.AtoDoCapitulo(
  const ANumeroCapitulo: Integer): Integer;
begin
  if (ANumeroCapitulo < 1) or (ANumeroCapitulo > CAPITULOS_TOTAIS) then
    raise EValorInvalido.CreateFmt(
      'Número de capítulo inválido: %d (esperado 1..%d).',
      [ANumeroCapitulo, CAPITULOS_TOTAIS]);

  Result := ((ANumeroCapitulo - 1) div CAPITULOS_POR_ATO) + 1;
end;

class function TCalculadoraAtos.EhInicioDeAto(
  const ANumeroCapitulo: Integer): Boolean;
begin
  if (ANumeroCapitulo < 1) or (ANumeroCapitulo > CAPITULOS_TOTAIS) then
    Exit(False);
  Result := ((ANumeroCapitulo - 1) mod CAPITULOS_POR_ATO) = 0;
end;

class function TCalculadoraAtos.CapitulosDoAto(
  const ANumeroAto: Integer): TArray<Integer>;
var
  Inicio, I: Integer;
begin
  if (ANumeroAto < 1) or (ANumeroAto > 3) then
    raise EValorInvalido.CreateFmt(
      'Número de ato inválido: %d (esperado 1..3).', [ANumeroAto]);

  Inicio := ((ANumeroAto - 1) * CAPITULOS_POR_ATO) + 1;
  SetLength(Result, CAPITULOS_POR_ATO);
  for I := 0 to CAPITULOS_POR_ATO - 1 do
    Result[I] := Inicio + I;
end;

class function TCalculadoraAtos.TodosOsCapitulos: TArray<Integer>;
var
  I: Integer;
begin
  SetLength(Result, CAPITULOS_TOTAIS);
  for I := 1 to CAPITULOS_TOTAIS do
    Result[I - 1] := I;
end;

// ────────────────────────────────────────────────────────────
// TValidadorManuscrito
// ────────────────────────────────────────────────────────────

class function TValidadorManuscrito.Validar(
  const AManuscrito: TManuscrito): TArray<string>;
var
  Lista: TList<string>;
  A: TAto;
  C: TCapitulo;
  Ce: TCena;
  CapitulosEncontrados: TList<Integer>;
  CapEsperado: Integer;
  NumeroSequencia: Integer;
begin
  Lista := TList<string>.Create;
  CapitulosEncontrados := TList<Integer>.Create;
  try
    if AManuscrito = nil then
    begin
      Lista.Add('Manuscrito é nil.');
      Exit(Lista.ToArray);
    end;

    if AManuscrito.Atos.Count = 0 then
    begin
      Lista.Add('Manuscrito não possui nenhum ato.');
      Exit(Lista.ToArray);
    end;

    // Contagem de atos
    if AManuscrito.Atos.Count <> 3 then
      Lista.Add(Format('Esperados 3 atos, encontrados %d.',
        [AManuscrito.Atos.Count]));

    // Contagem de capítulos
    if AManuscrito.TotalCapitulos <> CAPITULOS_TOTAIS then
      Lista.Add(Format('Esperados %d capítulos, encontrados %d.',
        [CAPITULOS_TOTAIS, AManuscrito.TotalCapitulos]));

    // Coleta capítulos e valida sequência
    for A in AManuscrito.Atos do
      for C in A.Capitulos do
        CapitulosEncontrados.Add(C.Numero);

    // Ordena para checar sequência
    CapitulosEncontrados.Sort;

    NumeroSequencia := 1;
    for CapEsperado in CapitulosEncontrados do
    begin
      // Ignora capítulo 0 (fallback para conteúdo antes do cap 1)
      if CapEsperado = 0 then
        Continue;

      if CapEsperado <> NumeroSequencia then
      begin
        Lista.Add(Format('Sequência quebrada: esperado cap %d, encontrado cap %d.',
          [NumeroSequencia, CapEsperado]));
        NumeroSequencia := CapEsperado;
      end;
      Inc(NumeroSequencia);
    end;

    // Capítulos vazios e cenas vazias
    for A in AManuscrito.Atos do
      for C in A.Capitulos do
      begin
        if not C.TemConteudo then
          Lista.Add(Format('Capítulo %d não tem cenas.', [C.Numero]));

        for Ce in C.Cenas do
          if Ce.Paragrafos.Count = 0 then
            Lista.Add(Format('Cena %s não tem parágrafos.', [Ce.ID]));
      end;

    Result := Lista.ToArray;
  finally
    CapitulosEncontrados.Free;
    Lista.Free;
  end;
end;

class function TValidadorManuscrito.ValidarResumo(
  const AResumo: TResumoParse): TArray<string>;
begin
  if AResumo = nil then
  begin
    SetLength(Result, 1);
    Result[0] := 'Resumo é nil.';
    Exit;
  end;
  Result := AResumo.DivergenciasDoPadrao;
end;

// ────────────────────────────────────────────────────────────
// TCompressorPayload
// ────────────────────────────────────────────────────────────

class function TCompressorPayload.ContarPalavras(
  const ATexto: string): Integer;
begin
  Result := UManuscrito.ContarPalavras(ATexto);
end;

class function TCompressorPayload.PrecisaChunking(
  const ATexto: string): Boolean;
begin
  Result := ContarPalavras(ATexto) > LIMITE_PARAGRAFO_PALAVRAS;
end;

class function TCompressorPayload.SegmentarEmFrases(
  const ATexto: string): TArray<string>;
var
  Lista: TList<string>;
  Buffer: TStringBuilder;
  I: Integer;
  C: Char;
begin
  Lista := TList<string>.Create;
  Buffer := TStringBuilder.Create;
  try
    for I := 1 to Length(ATexto) do
    begin
      C := ATexto[I];
      Buffer.Append(C);

      // Fim de frase: pontuação seguida de espaço ou fim do texto.
      // Considera também o caractere de reticências (…).
      if CharInSet(C, ['.', '!', '?', '…']) then
      begin
        // Verifica se o próximo é espaço ou fim
        if (I = Length(ATexto)) or
           CharInSet(ATexto[I + 1], [' ', #9, #10, #13]) then
        begin
          // Absorve espaços em branco seguintes (para não iniciar
          // a próxima frase com eles).
          var Texto := Buffer.ToString.Trim;
          if Texto <> '' then
            Lista.Add(Texto);
          Buffer.Clear;
        end;
      end;
    end;

    // Resto sem pontuação final
    var Resto := Buffer.ToString.Trim;
    if Resto <> '' then
      Lista.Add(Resto);

    Result := Lista.ToArray;
  finally
    Buffer.Free;
    Lista.Free;
  end;
end;

class function TCompressorPayload.EstimarNumChunks(
  const ATexto: string): Integer;
var
  Palavras: Integer;
begin
  Palavras := ContarPalavras(ATexto);
  if Palavras <= LIMITE_PARAGRAFO_PALAVRAS then
    Exit(1);

  // Estimativa: quantos blocos de TAMANHO_CHUNK_PALAVRAS cabem.
  Result := (Palavras + TAMANHO_CHUNK_PALAVRAS - 1) div TAMANHO_CHUNK_PALAVRAS;
  if Result < 2 then
    Result := 2;
end;

class function TCompressorPayload.DividirEmChunks(
  const ATexto: string): TArray<string>;
var
  Frases: TArray<string>;
  Chunks: TList<string>;
  ChunkAtual: TStringBuilder;
  PalavrasChunkAtual: Integer;
  PalavrasFrase: Integer;
  FraseAnterior: string;
  Frase: string;
begin
  // Sem chunking necessário → um único chunk com o texto original.
  if not PrecisaChunking(ATexto) then
  begin
    SetLength(Result, 1);
    Result[0] := ATexto;
    Exit;
  end;

  Frases := SegmentarEmFrases(ATexto);
  if Length(Frases) = 0 then
  begin
    SetLength(Result, 1);
    Result[0] := ATexto;
    Exit;
  end;

  Chunks := TList<string>.Create;
  ChunkAtual := TStringBuilder.Create;
  try
    PalavrasChunkAtual := 0;
    FraseAnterior := '';

    for Frase in Frases do
    begin
      PalavrasFrase := ContarPalavras(Frase);

      // Se adicionar essa frase estoura o alvo E já temos
      // conteúdo suficiente, fecha o chunk atual.
      if (PalavrasChunkAtual > 0) and
         (PalavrasChunkAtual + PalavrasFrase > TAMANHO_CHUNK_PALAVRAS) then
      begin
        Chunks.Add(ChunkAtual.ToString.Trim);
        ChunkAtual.Clear;
        PalavrasChunkAtual := 0;

        // Sobreposição: repete a última frase do chunk anterior
        // no início do próximo (contexto de borda).
        if (SOBREPOSICAO_CHUNK_FRASES > 0) and (FraseAnterior <> '') then
        begin
          ChunkAtual.Append(FraseAnterior).Append(' ');
          PalavrasChunkAtual := ContarPalavras(FraseAnterior);
        end;
      end;

      ChunkAtual.Append(Frase).Append(' ');
      Inc(PalavrasChunkAtual, PalavrasFrase);
      FraseAnterior := Frase;
    end;

    // Último chunk
    if ChunkAtual.Length > 0 then
    begin
      var Ultimo := ChunkAtual.ToString.Trim;
      if Ultimo <> '' then
        Chunks.Add(Ultimo);
    end;

    Result := Chunks.ToArray;
  finally
    ChunkAtual.Free;
    Chunks.Free;
  end;
end;

end.
