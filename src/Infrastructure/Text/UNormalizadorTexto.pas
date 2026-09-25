unit UNormalizadorTexto;

{
  UNormalizadorTexto.pas
  ─────────────────────────────────────────────────────────────
  Funções puras de normalização de texto para uso dos gatilhos
  locais. Nada aqui tem estado ou depende de contexto.

  Operações:
    • Minúsculas + remoção de acentuação (chave canônica).
    • Trim de espaços, tabs, quebras.
    • Remoção de pontuação.
    • Extração das N primeiras palavras (para detecção de
      prefixo repetido — anáfora).
    • Contagem de pontuação interna (para frase longa).
    • Detecção de "frase nominal" (sem verbo conjugado
      principal) — heurística usada por padrão_descritivo.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TNormalizadorTexto = class
  public
    /// <summary>
    ///   Converte para minúsculas e remove acentos comuns do
    ///   português (á→a, é→e, ç→c, ã→a, õ→o, etc.).
    ///   Também remove pontuação básica.
    /// </summary>
    class function Canonical(const ATexto: string): string;

    /// <summary>
    ///   Minúsculas sem remover acentos nem pontuação.
    /// </summary>
    class function Minusculas(const ATexto: string): string;

    /// <summary>Remove acentuação, preserva caixa.</summary>
    class function SemAcentos(const ATexto: string): string;

    /// <summary>
    ///   Remove pontuação (,.;:!?…-—–"'"'()[]{}) mas preserva
    ///   o espaçamento entre palavras.
    /// </summary>
    class function SemPunctuacao(const ATexto: string): string;

    /// <summary>
    ///   Retorna as N primeiras palavras do texto, já
    ///   canonicalizadas e separadas por espaço único.
    ///   Se o texto tiver menos que N palavras, retorna tudo.
    /// </summary>
    class function PrimeirasPalavras(const ATexto: string;
      const AN: Integer): string;

    /// <summary>Array de palavras do texto (por espaço).</summary>
    class function Palavras(const ATexto: string): TArray<string>;

    /// <summary>
    ///   Conta pontuação "de pausa" (vírgula, ponto-e-vírgula,
    ///   dois-pontos, travessão) no texto. Usado pelo gatilho
    ///   de frase longa.
    /// </summary>
    class function ContarPausasInternas(const ATexto: string): Integer;

    /// <summary>
    ///   Heurística leve: True se o texto não contém nenhuma
    ///   palavra que pareça verbo conjugado típico.
    ///   Não é análise morfológica — só lista de sufixos comuns.
    /// </summary>
    class function PareceFraseNominal(const ATexto: string): Boolean;

    /// <summary>
    ///   Split por espaço em branco, descartando tokens vazios.
    ///   Não usa separador de frase.
    /// </summary>
    class function SplitEspacos(const ATexto: string): TArray<string>;

    /// <summary>Remove espaços repetidos e das extremidades.</summary>
    class function ColapsarEspacos(const ATexto: string): string;

    /// <summary>True se o texto é vazio ou só espaços.</summary>
    class function EhVazio(const ATexto: string): Boolean;
  end;

implementation

const
  MAPA_ACENTOS: array [0..15] of record De: Char; Para: Char; end = (
    (De: 'á'; Para: 'a'), (De: 'à'; Para: 'a'), (De: 'ã'; Para: 'a'),
    (De: 'â'; Para: 'a'), (De: 'ä'; Para: 'a'),
    (De: 'é'; Para: 'e'), (De: 'ê'; Para: 'e'), (De: 'è'; Para: 'e'),
    (De: 'í'; Para: 'i'), (De: 'î'; Para: 'i'),
    (De: 'ó'; Para: 'o'), (De: 'ô'; Para: 'o'), (De: 'õ'; Para: 'o'),
    (De: 'ú'; Para: 'u'), (De: 'û'; Para: 'u'),
    (De: 'ç'; Para: 'c')
  );

{ TNormalizadorTexto }

class function TNormalizadorTexto.EhVazio(const ATexto: string): Boolean;
begin
  Result := ATexto.Trim = '';
end;

class function TNormalizadorTexto.Minusculas(const ATexto: string): string;
begin
  Result := ATexto.ToLower;
end;

class function TNormalizadorTexto.SemAcentos(const ATexto: string): string;
var
  I, J: Integer;
  C: Char;
  Encontrou: Boolean;
begin
  Result := ATexto;

  for I := 1 to Length(Result) do
  begin
    C := Result[I];
    Encontrou := False;
    for J := Low(MAPA_ACENTOS) to High(MAPA_ACENTOS) do
      if MAPA_ACENTOS[J].De = C then
      begin
        Result[I] := MAPA_ACENTOS[J].Para;
        Encontrou := True;
        Break;
      end;
    // Se não achou e é maiúscula acentuada, baixa antes de mapear.
    if not Encontrou then
    begin
      case C of
        'Á', 'À', 'Ã', 'Â', 'Ä': Result[I] := 'A';
        'É', 'Ê', 'È':           Result[I] := 'E';
        'Í', 'Î':                Result[I] := 'I';
        'Ó', 'Ô', 'Õ':           Result[I] := 'O';
        'Ú', 'Û':                Result[I] := 'U';
        'Ç':                     Result[I] := 'C';
      end;
    end;
  end;
end;

class function TNormalizadorTexto.SemPunctuacao(const ATexto: string): string;
var
  SB: TStringBuilder;
  I: Integer;
  C: Char;
begin
  SB := TStringBuilder.Create;
  try
    for I := 1 to Length(ATexto) do
    begin
      C := ATexto[I];
      if CharInSet(C, [',', '.', ';', ':', '!', '?', '…', '-', '–', '—',
                       '"', '''', '´', '`', '(', ')', '[', ']', '{', '}']) then
        SB.Append(' ')
      else
        SB.Append(C);
    end;
    Result := ColapsarEspacos(SB.ToString);
  finally
    SB.Free;
  end;
end;

class function TNormalizadorTexto.Canonical(const ATexto: string): string;
begin
  Result := ColapsarEspacos(
    SemPunctuacao(SemAcentos(ATexto.ToLower)));
end;

class function TNormalizadorTexto.ColapsarEspacos(
  const ATexto: string): string;
var
  SB: TStringBuilder;
  I: Integer;
  C: Char;
  UltimoFoiEspaco: Boolean;
begin
  SB := TStringBuilder.Create;
  try
    UltimoFoiEspaco := True;  // ignora espaços iniciais
    for I := 1 to Length(ATexto) do
    begin
      C := ATexto[I];
      if CharInSet(C, [' ', #9, #10, #13, #160]) then
      begin
        if not UltimoFoiEspaco then
        begin
          SB.Append(' ');
          UltimoFoiEspaco := True;
        end;
      end
      else
      begin
        SB.Append(C);
        UltimoFoiEspaco := False;
      end;
    end;

    // Remove espaço final.
    if (SB.Length > 0) and (SB.Chars[SB.Length - 1] = ' ') then
      SB.Length := SB.Length - 1;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

class function TNormalizadorTexto.SplitEspacos(
  const ATexto: string): TArray<string>;
var
  Lista: TList<string>;
  SB: TStringBuilder;
  I: Integer;
  C: Char;
begin
  Lista := TList<string>.Create;
  SB := TStringBuilder.Create;
  try
    for I := 1 to Length(ATexto) do
    begin
      C := ATexto[I];
      if CharInSet(C, [' ', #9, #10, #13, #160]) then
      begin
        if SB.Length > 0 then
        begin
          Lista.Add(SB.ToString);
          SB.Clear;
        end;
      end
      else
        SB.Append(C);
    end;

    if SB.Length > 0 then
      Lista.Add(SB.ToString);

    Result := Lista.ToArray;
  finally
    SB.Free;
    Lista.Free;
  end;
end;

class function TNormalizadorTexto.Palavras(
  const ATexto: string): TArray<string>;
begin
  Result := SplitEspacos(ATexto);
end;

class function TNormalizadorTexto.PrimeirasPalavras(const ATexto: string;
  const AN: Integer): string;
var
  Palavras: TArray<string>;
  I, Limite: Integer;
begin
  Palavras := SplitEspacos(Canonical(ATexto));
  Limite := AN;
  if Length(Palavras) < Limite then
    Limite := Length(Palavras);

  if Limite = 0 then
    Exit('');

  Result := Palavras[0];
  for I := 1 to Limite - 1 do
    Result := Result + ' ' + Palavras[I];
end;

class function TNormalizadorTexto.ContarPausasInternas(
  const ATexto: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(ATexto) do
    if CharInSet(ATexto[I], [',', ';', ':', '—', '–', '-']) then
      Inc(Result);
end;

class function TNormalizadorTexto.PareceFraseNominal(
  const ATexto: string): Boolean;
var
  Palavras: TArray<string>;
  P: string;
  I: Integer;
  AchouVerbo: Boolean;
begin
  // Heurística simples: se o texto tem até 7 palavras e nenhuma
  // delas termina em sufixo típico de verbo conjugado, é
  // provavelmente nominal.
  //
  // Sufixos considerados: -ou, -eu, -iu, -ava, -ia, -ou, -am,
  // -em, -ão, -ei, -ou. Não é morfologia real — é filtro.
  Palavras := SplitEspacos(Canonical(ATexto));
  if Length(Palavras) > 7 then
    Exit(False);

  AchouVerbo := False;
  for I := 0 to High(Palavras) do
  begin
    P := Palavras[I];
    if (P.EndsWith('ou')) or (P.EndsWith('eu')) or (P.EndsWith('iu')) or
       (P.EndsWith('ava')) or (P.EndsWith('ava')) or
       (P.EndsWith('avam')) or (P.EndsWith('iam')) or
       (P.EndsWith('aram')) or (P.EndsWith('eram')) or
       (P.EndsWith('iram')) or (P.EndsWith('am')) or
       (P.EndsWith('em')) or (P.EndsWith('ao')) then
    begin
      AchouVerbo := True;
      Break;
    end;
  end;

  Result := not AchouVerbo;
end;

end.
