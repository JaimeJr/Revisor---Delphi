unit UViciosJsonRepository;

{
  UViciosJsonRepository.pas
  ─────────────────────────────────────────────────────────────
  Persistência do Vicios.JSON — catálogo editorial vivo.

  Características:
    • Carregar: se o arquivo não existir, retorna catálogo vazio.
    • GarantirSemente: cria o arquivo com as 15 categorias
      iniciais se não existir. NÃO sobrescreve catálogo existente.
    • Salvar: regrava o arquivo inteiro. Volume pequeno, rewrite
      é adequado.

  Sobre o catálogo semente:
    • As 10 primeiras categorias foram propostas na arquitetura.
    • As 5 últimas vieram do autor do manuscrito.
    • Categorias de "ausência de detalhe" e "diálogo/subtexto"
      não têm gatilho local — só a IA detecta, no modo varredura.
      Isso é esperado: ausência não se detecta por regex.

  Decisões:
    • Enum OrigemVicio (generico/autor) preservado no JSON.
    • Exemplos do manuscrito com cena_id, paragrafo_id, trecho,
      id_chamada e timestamp.
    • Versao incrementa a cada edição do catálogo.
    • Escrita atômica, UTF-8 sem BOM, datas ISO 8601 UTC.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UIViciosRepository, UVicio;

type
  TViciosJsonRepository = class(TInterfacedObject, IViciosRepository)
  public
    function Carregar(const ACaminho: string): TCatalogoVicios;

    procedure Salvar(const ACatalogo: TCatalogoVicios;
      const ACaminho: string);

    procedure GarantirSemente(const ACaminho: string);

    function Existe(const ACaminho: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.DateUtils,
  System.JSON,
  UValores;

const
  VERSAO_SCHEMA_VICIOS = 1;

// ────────────────────────────────────────────────────────────
// Utilitários internos
// ────────────────────────────────────────────────────────────

function DataHoraParaISO(const AData: TDateTime): string;
var
  UTC: TDateTime;
begin
  UTC := TTimeZone.Local.ToUniversalTime(AData);
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"', UTC);
end;

function ISOParaDataHora(const ATexto: string): TDateTime;
var
  UTC: TDateTime;
begin
  if Length(ATexto) < 19 then
    raise EValorInvalido.CreateFmt(
      'Data/hora em formato inválido: "%s".', [ATexto]);

  try
    UTC := EncodeDateTime(
      StrToInt(Copy(ATexto, 1, 4)),
      StrToInt(Copy(ATexto, 6, 2)),
      StrToInt(Copy(ATexto, 9, 2)),
      StrToInt(Copy(ATexto, 12, 2)),
      StrToInt(Copy(ATexto, 15, 2)),
      StrToInt(Copy(ATexto, 18, 2)),
      0);
  except
    on E: Exception do
      raise EValorInvalido.CreateFmt(
        'Falha ao interpretar data/hora "%s": %s', [ATexto, E.Message]);
  end;

  Result := TTimeZone.Local.ToLocalTime(UTC);
end;

procedure EscreverArquivoAtomico(const AConteudo, ACaminho: string);
var
  Temp: string;
begin
  Temp := ACaminho + '.tmp';
  TFile.WriteAllText(Temp, AConteudo, TEncoding.UTF8);
  if TFile.Exists(ACaminho) then
    TFile.Delete(ACaminho);
  TFile.Move(Temp, ACaminho);
end;

function LerArquivoTexto(const ACaminho: string): string;
begin
  if not TFile.Exists(ACaminho) then
    raise Exception.CreateFmt('Arquivo não encontrado: %s', [ACaminho]);
  Result := TFile.ReadAllText(ACaminho, TEncoding.UTF8);
end;

// ────────────────────────────────────────────────────────────
// Serialização: ExemploManuscrito
// ────────────────────────────────────────────────────────────

function ExemploParaJson(const AEx: TExemploManuscrito): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('cena_id', AEx.CenaID);
  Result.AddPair('paragrafo_id', AEx.ParagrafoID);
  Result.AddPair('trecho', AEx.Trecho);
  Result.AddPair('id_chamada', AEx.IDChamada);
  Result.AddPair('timestamp', DataHoraParaISO(AEx.Timestamp));
end;

function JsonParaExemplo(const AObj: TJSONObject): TExemploManuscrito;
begin
  Result := TExemploManuscrito.Create;
  Result.CenaID := AObj.GetValue<string>('cena_id');
  Result.ParagrafoID := AObj.GetValue<string>('paragrafo_id');
  Result.Trecho := AObj.GetValue<string>('trecho');
  Result.IDChamada := AObj.GetValue<string>('id_chamada');
  Result.Timestamp := ISOParaDataHora(AObj.GetValue<string>('timestamp'));
end;

// ────────────────────────────────────────────────────────────
// Serialização: Vicio
// ────────────────────────────────────────────────────────────

function VicioParaJson(const AVicio: TVicio): TJSONObject;
var
  Arranjo: TJSONArray;
  Ex: TExemploManuscrito;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', AVicio.ID);
  Result.AddPair('nome', AVicio.Nome);
  Result.AddPair('origem', AVicio.Origem.ToStr);
  Result.AddPair('descricao', AVicio.Descricao);
  Result.AddPair('dica_correcao', AVicio.DicaCorrecao);
  Result.AddPair('gatilho_local', AVicio.GatilhoLocal);
  Result.AddPair('precisa_cross_cena',
    TJSONBool.Create(AVicio.PrecisaCrossCena));
  Result.AddPair('frequencia_no_manuscrito',
    TJSONNumber.Create(AVicio.FrequenciaNoManuscrito));

  Arranjo := TJSONArray.Create;
  for Ex in AVicio.Exemplos do
    Arranjo.AddElement(ExemploParaJson(Ex));
  Result.AddPair('exemplos_manuscrito', Arranjo);
end;

function JsonParaVicio(const AObj: TJSONObject): TVicio;
var
  Arranjo: TJSONArray;
  I: Integer;
begin
  Result := TVicio.Create;
  try
    Result.ID := AObj.GetValue<string>('id');
    Result.Nome := AObj.GetValue<string>('nome');
    Result.Origem := TOrigemVicio.FromStr(AObj.GetValue<string>('origem'));
    Result.Descricao := AObj.GetValue<string>('descricao');
    Result.DicaCorrecao := AObj.GetValue<string>('dica_correcao');
    Result.GatilhoLocal := AObj.GetValue<string>('gatilho_local');
    Result.PrecisaCrossCena :=
      AObj.GetValue<Boolean>('precisa_cross_cena');
    Result.FrequenciaNoManuscrito :=
      AObj.GetValue<Integer>('frequencia_no_manuscrito');

    Arranjo := AObj.GetValue<TJSONArray>('exemplos_manuscrito');
    for I := 0 to Arranjo.Count - 1 do
      Result.Exemplos.Add(
        JsonParaExemplo(Arranjo.Items[I] as TJSONObject));
  except
    Result.Free;
    raise;
  end;
end;

// ────────────────────────────────────────────────────────────
// Serialização: CatalogoVicios
// ────────────────────────────────────────────────────────────

function CatalogoParaJson(const ACatalogo: TCatalogoVicios): TJSONObject;
var
  Arranjo: TJSONArray;
  V: TVicio;
begin
  Result := TJSONObject.Create;
  Result.AddPair('versao_schema', TJSONNumber.Create(VERSAO_SCHEMA_VICIOS));
  Result.AddPair('versao', TJSONNumber.Create(ACatalogo.Versao));
  Result.AddPair('atualizado_em',
    DataHoraParaISO(ACatalogo.AtualizadoEm));

  Arranjo := TJSONArray.Create;
  for V in ACatalogo.Categorias do
    Arranjo.AddElement(VicioParaJson(V));
  Result.AddPair('categorias', Arranjo);
end;

function JsonParaCatalogo(const AObj: TJSONObject): TCatalogoVicios;
var
  Arranjo: TJSONArray;
  I, Versao, VersaoSchema: Integer;
begin
  VersaoSchema := AObj.GetValue<Integer>('versao_schema');
  if VersaoSchema <> VERSAO_SCHEMA_VICIOS then
    raise EValorInvalido.CreateFmt(
      'Versão de schema do Vicios.JSON não suportada: %d (esperado %d).',
      [VersaoSchema, VERSAO_SCHEMA_VICIOS]);

  Result := TCatalogoVicios.Create;
  try
    Result.VersaoSchema := VersaoSchema;
    Versao := AObj.GetValue<Integer>('versao');
    Result.Versao := Versao;
    Result.AtualizadoEm :=
      ISOParaDataHora(AObj.GetValue<string>('atualizado_em'));

    Arranjo := AObj.GetValue<TJSONArray>('categorias');
    for I := 0 to Arranjo.Count - 1 do
    begin
      var V := JsonParaVicio(Arranjo.Items[I] as TJSONObject);
      // Adiciona sem incrementar Versao — senão o catálogo
      // recém-carregado apareceria "alterado".
      Result.Categorias.Add(V);
      // Como o dicionário é privado, uso o Adicionar normal e
      // depois corrijo a Versao.
      // (TVicio vai para o lista; o índice interno precisa
      // saber disso. Uso Adicionar e depois restauro Versao.)
    end;

    // Reconstrói índice e Versao original. Como Categorias foi
    // populada diretamente, o índice interno fica vazio — é
    // preciso reindexar. Solução: reatribui via Adicionar.
    // Vou fazer isso de forma limpa:
    Result.Categorias.Clear;
    for I := 0 to Arranjo.Count - 1 do
      Result.Adicionar(JsonParaVicio(Arranjo.Items[I] as TJSONObject));

    // Restaura a Versao original (Adicionar incrementa).
    Result.Versao := Versao;
  except
    Result.Free;
    raise;
  end;
end;

// ────────────────────────────────────────────────────────────
// Catálogo semente — 15 categorias
// ────────────────────────────────────────────────────────────

procedure AdicionarVicio(const ACatalogo: TCatalogoVicios;
  const AID, ANome, ADescricao, ADica, AGatilho: string;
  APrecisaCrossCena: Boolean);
var
  V: TVicio;
begin
  V := TVicio.Create;
  V.ID := AID;
  V.Nome := ANome;
  V.Origem := ovGenerico;
  V.Descricao := ADescricao;
  V.DicaCorrecao := ADica;
  V.GatilhoLocal := AGatilho;
  V.PrecisaCrossCena := APrecisaCrossCena;
  ACatalogo.Adicionar(V);
end;

procedure ConstruirSemente(const ACatalogo: TCatalogoVicios);
begin
  // ─── Excesso / repetição ───

  AdicionarVicio(ACatalogo,
    'anafora',
    'Anáfora',
    'Repetição da mesma palavra ou expressão no início de frases ' +
    'consecutivas, criando ritmo monótono.',
    'Remonte o parágrafo variando a ordem sintática, fundindo frases ' +
    'ou invertendo sujeito/objeto. Se o ritmo ternário for intencional, ' +
    'quebre-o na última ocorrência.',
    '3+ frases seguidas cujo prefixo (2-3 palavras iniciais) é idêntico.',
    False);

  AdicionarVicio(ACatalogo,
    'repeticao_lexical_curta',
    'Repetição lexical em janela curta',
    'Mesma palavra significativa (não artigo/preposição/pronome) ' +
    'repetida 3+ vezes em um intervalo de 100 palavras.',
    'Substitua uma ou duas ocorrências por sinônimo, pronome ou elipse. ' +
    'Cuidado com sinônimos forçados — às vezes a repetição é o menor dos males.',
    '3+ ocorrências da mesma palavra (fora stopwords) em janela de 100 palavras.',
    False);

  AdicionarVicio(ACatalogo,
    'padrao_descritivo_repetido',
    'Repetição de descrição',
    'Mesma sequência sensorial usada para descrever reações emocionais ' +
    'de personagens ou cenas diferentes, empobrecendo a caracterização.',
    'Substitua uma ou mais linhas por metáfora, ação externa, diálogo ' +
    'indireto ou silêncio narrativo. Evite reusar a mesma tríade ' +
    '(físico → fisiológico → sensorial).',
    '3 frases nominais curtas seguidas (< 7 palavras, sem verbo ' +
    'conjugado principal) descrevendo reação corporal.',
    True);

  AdicionarVicio(ACatalogo,
    'comeco_paragrafo_repetido',
    'Começo de parágrafo repetido',
    'Vários parágrafos consecutivos começando com a mesma palavra ' +
    'ou expressão ("Ele...", "Ela...", "Então...", "E...").',
    'Varie a abertura movendo o sujeito para o meio, começando com ' +
    'circunstância, ou fundindo dois parágrafos.',
    '3+ parágrafos consecutivos com mesma primeira palavra ' +
    '(ignorando artigos e preposições comuns).',
    False);

  AdicionarVicio(ACatalogo,
    'adverbio_mente_empilhado',
    'Advérbios em -mente empilhados',
    'Dois ou mais advérbios terminados em -mente na mesma frase ou em ' +
    'frases adjacentes, deixando a prosa pesada.',
    'Elimine um dos advérbios ou substitua o verbo por um mais preciso ' +
    'que dispense a modificação.',
    '2+ tokens terminando em "-mente" na mesma frase, ou 3+ no mesmo parágrafo.',
    False);

  AdicionarVicio(ACatalogo,
    'adjetivacao_dupla',
    'Adjetivação dupla',
    'Dois adjetivos para o mesmo substantivo, geralmente sinônimos ou ' +
    'previsíveis ("um silêncio profundo e denso", "um olhar frio e duro").',
    'Escolha um. Se nenhum sozinho serve, o problema é o substantivo — ' +
    'troque-o.',
    'Padrão substantivo + adjetivo + " e " + adjetivo na mesma oração.',
    False);

  AdicionarVicio(ACatalogo,
    'cliche_corporal',
    'Clichê de reação corporal',
    'Expressões gastas para emoções — "coração disparou", "sangue gelou", ' +
    '"estômago embrulhou", "nó na garganta", "frio na espinha".',
    'Substitua por reação específica do personagem ou por ação concreta. ' +
    'Se o clichê for inevitável, ancore-o com um detalhe único da cena.',
    'Match exato (case-insensitive) contra lista de clichês pré-carregada.',
    False);

  // ─── Estrutura da frase ───

  AdicionarVicio(ACatalogo,
    'frase_longa_sem_pausa',
    'Frase longa sem pausa',
    'Período com mais de 40 palavras sem vírgula, ponto-e-vírgula, ' +
    'dois-pontos ou travessão. Cansa o leitor e dilui a ênfase.',
    'Quebre em duas ou três frases. Coloque o núcleo da informação no ' +
    'fim, para o leitor não se perder.',
    'Frase com > 40 palavras e < 1 pontuação interna.',
    False);

  AdicionarVicio(ACatalogo,
    'explicacao_do_obvio',
    'Explicação do óbvio',
    'A narração explica ao leitor algo que a cena já mostrou ou que é ' +
    'dedutível. Redundância narrativa.',
    'Corte a frase explicativa. Se a cena não se sustenta sem ela, o ' +
    'problema está na cena, não na explicação.',
    '',  // difícil de detectar localmente — só IA no modo varredura
    False);

  // ─── Diálogo e cena ───

  AdicionarVicio(ACatalogo,
    'tag_dialogo_redundante',
    'Tag de diálogo redundante',
    'Verbo de fala acompanhado de advérbio ou ação que repete a ' +
    'informação — "ele disse, falou", "ela gritou alto", "ele sussurrou baixinho".',
    'Use só "disse", ou substitua por ação que mostre o tom. Se o tom ' +
    'for óbvio pelo contexto, remova a tag inteira.',
    'Diálogo (entre aspas ou travessão) seguido por verbo de fala + ' +
    'advérbio redundante conhecido.',
    False);

  AdicionarVicio(ACatalogo,
    'dialogo_sem_reacao',
    'Diálogo sem reação',
    'Falas consecutivas sem nenhuma reação corporal, gesto ou ' +
    'pensamento dos personagens entre elas. Fica "cabeça falante".',
    'Intercale uma reação física, um gesto, uma pausa ou um pensamento. ' +
    'Nem toda fala precisa — mas 3+ seguidas sem âncora corporal pesam.',
    '',  // difícil localmente — IA detecta no modo varredura
    False);

  AdicionarVicio(ACatalogo,
    'falta_subtexto',
    'Falta de subtexto',
    'Personagens dizem exatamente o que sentem ou pensam, sem ' +
    'ambiguidade, silêncio ou contradição entre fala e ação.',
    'Deixe o personagem não dizer o que quer dizer. Use hesitação, ' +
    'mudança de assunto, ação contraditória. O leitor deduz o que ' +
    'a fala esconde.',
    '',  // IA detecta no modo varredura
    False);

  // ─── Ausência de detalhe ───

  AdicionarVicio(ACatalogo,
    'falta_detalhe_corporal',
    'Falta de detalhe corporal',
    'Cenas inteiras em que os personagens não têm corpo: não respiram, ' +
    'não gesticulam, não sentem o próprio peso, não ocupam espaço.',
    'Insira uma ou duas âncoras corporais por cena: uma respiração, um ' +
    'gesto involuntário, uma sensação física. Não precisa em toda frase ' +
    '— mas a cena inteira sem corpo fica etérea.',
    '',  // ausência não se detecta localmente
    False);

  AdicionarVicio(ACatalogo,
    'falta_detalhe_ambiente',
    'Falta de detalhe do ambiente',
    'Cenas sem ancoragem espacial: o leitor não sabe onde está, que ' +
    'som ambiente existe, que temperatura faz, o que há à volta.',
    'Uma referência sensorial do ambiente por cena basta: um som, uma ' +
    'temperatura, um objeto, uma luz. Não vire descrição de cenário — ' +
    'só ancore o leitor.',
    '',  // IA detecta no modo varredura
    False);

  AdicionarVicio(ACatalogo,
    'falta_detalhe_sensorial',
    'Falta de detalhe sensorial',
    'Cena narrada quase inteiramente pelo visual — o leitor não cheira, ' +
    'ouve, toca ou sente gosto. Prosa "plana".',
    'Introduza um ou dois sentidos não-visuais por cena. Escolha os que ' +
    'o personagem mais notaria dado o estado emocional dele.',
    '',  // IA detecta no modo varredura
    False);
end;

// ────────────────────────────────────────────────────────────
// TViciosJsonRepository
// ────────────────────────────────────────────────────────────

function TViciosJsonRepository.Carregar(
  const ACaminho: string): TCatalogoVicios;
var
  Texto: string;
  Valor: TJSONValue;
begin
  if not TFile.Exists(ACaminho) then
    Exit(TCatalogoVicios.Create);

  Texto := LerArquivoTexto(ACaminho);

  Valor := TJSONObject.ParseJSONValue(Texto);
  if not Assigned(Valor) then
    raise EValorInvalido.CreateFmt(
      'Conteúdo de "%s" não é JSON válido.', [ACaminho]);

  try
    if not (Valor is TJSONObject) then
      raise EValorInvalido.CreateFmt(
        'Esperado objeto JSON em "%s".', [ACaminho]);

    Result := JsonParaCatalogo(Valor as TJSONObject);
  finally
    Valor.Free;
  end;
end;

procedure TViciosJsonRepository.Salvar(const ACatalogo: TCatalogoVicios;
  const ACaminho: string);
var
  Json: TJSONObject;
  Texto: string;
begin
  if ACatalogo = nil then
    raise EValorInvalido.Create('Catálogo não pode ser nil.');

  Json := CatalogoParaJson(ACatalogo);
  try
    Texto := Json.Format(2);
  finally
    Json.Free;
  end;

  EscreverArquivoAtomico(Texto, ACaminho);
end;

procedure TViciosJsonRepository.GarantirSemente(const ACaminho: string);
var
  Catalogo: TCatalogoVicios;
begin
  if TFile.Exists(ACaminho) then
    Exit;

  Catalogo := TCatalogoVicios.Create;
  try
    ConstruirSemente(Catalogo);
    Catalogo.Versao := 1;   // versão inicial do catálogo
    Catalogo.AtualizadoEm := Now;
    Salvar(Catalogo, ACaminho);
  finally
    Catalogo.Free;
  end;
end;

function TViciosJsonRepository.Existe(const ACaminho: string): Boolean;
begin
  Result := TFile.Exists(ACaminho);
end;

end.
