unit UStopwords;

{
  UStopwords.pas
  ─────────────────────────────────────────────────────────────
  Lista fixa de stopwords do português. Usada por gatilhos que
  ignoram palavras funcionais (artigos, preposições, pronomes,
  conjunções) ao detectar repetição lexical ou começos de
  parágrafo repetidos.

  A lista é deliberadamente curta. Palavras ambíguas como
  "muito", "bem", "só" ficam FORA — são significativas o
  suficiente para contar como repetição lexical.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UNormalizadorTexto;

type
  TStopwords = class
  private
    class var FCache: TDictionary<string, Boolean>;
    class procedure Inicializar;
  public
    /// <summary>
    ///   True se a palavra (canonicalizada) é stopword.
    ///   A comparação é feita em minúsculas sem acento.
    /// </summary>
    class function EhStopword(const APalavra: string): Boolean;

    /// <summary>
    ///   Filtra um array, devolvendo só as palavras não-stopword.
    /// </summary>
    class function Filtrar(const APalavras: TArray<string>): TArray<string>;

    /// <summary>Lista completa (para inspeção/testes).</summary>
    class function Lista: TArray<string>;
  end;

implementation

const
  STOPWORDS: array [0..73] of string = (
    // Artigos
    'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas',
    // Preposições
    'de', 'da', 'do', 'das', 'dos',
    'em', 'no', 'na', 'nos', 'nas',
    'por', 'pelo', 'pela', 'pelos', 'pelas',
    'para', 'pra', 'com', 'sem', 'sob', 'sobre',
    'entre', 'ate', 'desde', 'contra',
    // Conjunções
    'e', 'ou', 'mas', 'que', 'se', 'como', 'porque', 'pois',
    'entao', 'tambem', 'nem', 'porem', 'contudo', 'todavia',
    // Pronomes comuns
    'eu', 'tu', 'ele', 'ela', 'nos', 'vos', 'eles', 'elas',
    'me', 'te', 'lhe', 'lhes', 'nos', 'vos',
    'meu', 'minha', 'seu', 'sua', 'dele', 'dela',
    'este', 'esta', 'isso', 'isto', 'aquele', 'aquela', 'aquilo'
  );

{ TStopwords }

class procedure TStopwords.Inicializar;
var
  W: string;
begin
  if Assigned(FCache) then
    Exit;

  FCache := TDictionary<string, Boolean>.Create;
  for W in STOPWORDS do
    FCache.AddOrSetValue(W, True);
end;

class function TStopwords.EhStopword(const APalavra: string): Boolean;
var
  Chave: string;
begin
  Inicializar;
  Chave := TNormalizadorTexto.Canonical(APalavra);
  if Chave = '' then
    Exit(True);  // vazio não conta como palavra significativa
  Result := FCache.ContainsKey(Chave);
end;

class function TStopwords.Filtrar(
  const APalavras: TArray<string>): TArray<string>;
var
  Lista: TList<string>;
  P: string;
begin
  Lista := TList<string>.Create;
  try
    for P in APalavras do
      if not EhStopword(P) then
        Lista.Add(P);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

class function TStopwords.Lista: TArray<string>;
var
  W: string;
  Lista: TList<string>;
begin
  Lista := TList<string>.Create;
  try
    for W in STOPWORDS do
      Lista.Add(W);
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

end.
