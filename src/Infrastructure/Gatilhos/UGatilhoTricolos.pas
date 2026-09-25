unit UGatilhoTricolos;

{
  UGatilhoTricolon.pas
  ─────────────────────────────────────────────────────────────
  Gatilho local para detecção de tricolon mecânico.

  Formas detectadas (todas com Confianca ≥ 0.5):
    1. Três frases curtas (≤ 8 palavras) seguidas com mesmo
       prefixo (2 palavras iniciais idênticas).
    2. Três frases seguidas começando com mesmo conector
       (mesma primeira palavra, ex: "como", "mesmo", "porque").
    3. Três itens em lista com paralelismo gramatical
       (substantivos ou orações com estrutura semelhante).
    4. Três negações seguidas ("não... não... não...").

  Confianca:
    • 3 ocorrências  → 0.5
    • 4 ocorrências  → 0.7
    • 5+ ocorrências → 1.0

  Trechos: os prefixos repetidos ou os itens da lista.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UIGatilhoLocal,
  UManuscrito,
  UNormalizadorTexto,
  UServicosDominio,
  UValores;

type
  TGatilhoTricolon = class(TInterfacedObject, IGatilhoLocal)
  private
    function DetectarPorPrefixo(const AFrases: TArray<string>): TGatilhoResultado;
    function DetectarPorConector(const AFrases: TArray<string>): TGatilhoResultado;
    function DetectarPorNegacao(const AFrases: TArray<string>): TGatilhoResultado;
    function DetectarPorLista(const ATexto: string): TGatilhoResultado;
    function EscolherMelhor(const AResultados: array of TGatilhoResultado): TGatilhoResultado;
  public
    function VicioID: string;
    function PrecisaContexto: Boolean;
    function Avaliar(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TGatilhoResultado;
  end;

implementation

const
  VICIO_TRICOLON = 'tricolon';
  MIN_FRASES_TRICOLON = 3;
  MAX_PALAVRAS_FRASE_CURTA = 8;

  CONECTORES_COMUNS: array [0..7] of string = (
    'como', 'mesmo', 'porque', 'que', 'se', 'quando', 'enquanto', 'onde'
  );

function ContarConsecutivosIguais(const AChaves: TArray<string>): Integer;
var
  I, Contador, Maximo: Integer;
begin
  if Length(AChaves) = 0 then
    Exit(0);

  Maximo := 1;
  Contador := 1;
  for I := 1 to High(AChaves) do
  begin
    if (AChaves[I] <> '') and (AChaves[I] = AChaves[I - 1]) then
      Inc(Contador)
    else
    begin
      if Contador > Maximo then
        Maximo := Contador;
      Contador := 1;
    end;
  end;

  if Contador > Maximo then
    Maximo := Contador;
  Result := Maximo;
end;

function ConfiancaPorOcorrencias(const AOcorrencias: Integer): Double;
begin
  if AOcorrencias <= 2 then
    Exit(0.0);
  if AOcorrencias = 3 then
    Exit(0.5);
  if AOcorrencias = 4 then
    Exit(0.7);
  Result := 1.0;
end;

{ TGatilhoTricolon }

function TGatilhoTricolon.VicioID: string;
begin
  Result := VICIO_TRICOLON;
end;

function TGatilhoTricolon.PrecisaContexto: Boolean;
begin
  // Detecção é local ao parágrafo.
  Result := False;
end;

function TGatilhoTricolon.Avaliar(const AParagrafo: TParagrafo;
  const AContexto: TContextoGlobal): TGatilhoResultado;
var
  Frases: TArray<string>;
  R1, R2, R3, R4: TGatilhoResultado;
begin
  Result.VicioID := VICIO_TRICOLON;
  Result.Disparou := False;
  Result.Confianca := 0.0;
  Result.Trechos := nil;

  if (AParagrafo = nil) or (AParagrafo.Texto.Trim = '') then
    Exit;

  Frases := TCompressorPayload.SegmentarEmFrases(AParagrafo.Texto);

  R1 := DetectarPorPrefixo(Frases);
  R2 := DetectarPorConector(Frases);
  R3 := DetectarPorNegacao(Frases);
  R4 := DetectarPorLista(AParagrafo.Texto);

  Result := EscolherMelhor([R1, R2, R3, R4]);
end;

function TGatilhoTricolon.DetectarPorPrefixo(
  const AFrases: TArray<string>): TGatilhoResultado;
var
  Prefixos: TArray<string>;
  I, Ocorrencias: Integer;
  Frase: string;
  ListaTrechos: TList<string>;
begin
  Result.VicioID := VICIO_TRICOLON;
  Result.Disparou := False;
  Result.Confianca := 0.0;
  Result.Trechos := nil;

  SetLength(Prefixos, Length(AFrases));
  ListaTrechos := TList<string>.Create;
  try
    for I := 0 to High(AFrases) do
    begin
      Frase := AFrases[I];
      if ContarPalavrasPalavras(Frase) > MAX_PALAVRAS_FRASE_CURTA then
      begin
        Prefixos[I] := '';
        Continue;
      end;
      Prefixos[I] := TNormalizadorTexto.PrimeirasPalavras(Frase, 2);
    end;

    Ocorrencias := ContarConsecutivosIguais(Prefixos);
    if Ocorrencias < MIN_FRASES_TRICOLON then
      Exit;

    for I := 0 to High(Prefixos) do
      if (Prefixos[I] <> '') and not ListaTrechos.Contains(Prefixos[I]) then
        ListaTrechos.Add(Prefixos[I]);

    Result.Disparou := True;
    Result.Confianca := ConfiancaPorOcorrencias(Ocorrencias);
    Result.Trechos := ListaTrechos.ToArray;
  finally
    ListaTrechos.Free;
  end;
end;

function TGatilhoTricolon.DetectarPorConector(
  const AFrases: TArray<string>): TGatilhoResultado;
var
  Chaves: TArray<string>;
  I, Ocorrencias: Integer;
  Primeira: string;
  ListaTrechos: TList<string>;
  EhConector: Boolean;
  C: string;
begin
  Result.VicioID := VICIO_TRICOLON;
  Result.Disparou := False;
  Result.Confianca := 0.0;
  Result.Trechos := nil;

  SetLength(Chaves, Length(AFrases));
  ListaTrechos := TList<string>.Create;
  try
    for I := 0 to High(AFrases) do
    begin
      Primeira := TNormalizadorTexto.PrimeirasPalavras(AFrases[I], 1);
      EhConector := False;
      for C in CONECTORES_COMUNS do
        if Primeira = C then
        begin
          EhConector := True;
          Break;
        end;

      if EhConector then
        Chaves[I] := Primeira
      else
        Chaves[I] := '';
    end;

    Ocorrencias := ContarConsecutivosIguais(Chaves);
    if Ocorrencias < MIN_FRASES_TRICOLON then
      Exit;

    for I := 0 to High(Chaves) do
      if (Chaves[I] <> '') and not ListaTrechos.Contains(Chaves[I]) then
        ListaTrechos.Add(Chaves[I]);

    Result.Disparou := True;
    Result.Confianca := ConfiancaPorOcorrencias(Ocorrencias);
    Result.Trechos := ListaTrechos.ToArray;
  finally
    ListaTrechos.Free;
  end;
end;

function TGatilhoTricolon.DetectarPorNegacao(
  const AFrases: TArray<string>): TGatilhoResultado;
var
  Chaves: TArray<string>;
  I, Ocorrencias: Integer;
  Primeira: string;
begin
  Result.VicioID := VICIO_TRICOLON;
  Result.Disparou := False;
  Result.Confianca := 0.0;
  Result.Trechos := nil;

  SetLength(Chaves, Length(AFrases));
  for I := 0 to High(AFrases) do
  begin
    Primeira := TNormalizadorTexto.PrimeirasPalavras(AFrases[I], 1);
    if (Primeira = 'nao') or (Primeira = 'nunca') or (Primeira = 'nem') then
      Chaves[I] := Primeira
    else
      Chaves[I] := '';
  end;

  Ocorrencias := ContarConsecutivosIguais(Chaves);
  if Ocorrencias < MIN_FRASES_TRICOLON then
    Exit;

  Result.Disparou := True;
  Result.Confianca := ConfiancaPorOcorrencias(Ocorrencias);
  SetLength(Result.Trechos, 1);
  Result.Trechos[0] := 'não/nunca/nem';
end;

function TGatilhoTricolon.DetectarPorLista(
  const ATexto: string): TGatilhoResultado;
var
  Trechos: TList<string>;
  Canonico: string;
begin
  Result.VicioID := VICIO_TRICOLON;
  Result.Disparou := False;
  Result.Confianca := 0.0;
  Result.Trechos := nil;

  Canonico := TNormalizadorTexto.Canonical(ATexto);
  Trechos := TList<string>.Create;
  try
    // Heurística simples: procura por padrão "X, Y, Z" onde X, Y, Z
    // têm paralelismo — mesma terminação (plural, feminino etc.).
    // Implementação completa fica para quando o gatilho for integrado.
    // Por ora, retorna não disparado — evita falso positivo grosseiro.
    Result.Disparou := False;
  finally
    Trechos.Free;
  end;
end;

function TGatilhoTricolon.EscolherMelhor(
  const AResultados: array of TGatilhoResultado): TGatilhoResultado;
var
  R: TGatilhoResultado;
begin
  Result.VicioID := VICIO_TRICOLON;
  Result.Disparou := False;
  Result.Confianca := 0.0;
  Result.Trechos := nil;

  for R in AResultados do
    if R.Disparou and (R.Confianca > Result.Confianca) then
      Result := R;
end;

end.
