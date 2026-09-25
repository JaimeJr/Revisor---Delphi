unit UParserManuscrito;

{
  UParserManuscrito.pas
  ─────────────────────────────────────────────────────────────
  Parser do manuscrito .docx → TManuscrito + TParseLog.

  ═══ MÁQUINA DE ESTADOS ═══

  Estados implícitos nos campos FAtoAtual/FCapAtual/FCenaAtual:

    AguardandoPrimeiroCapitulo : Ato=nil, Cap=nil, Cena=nil
    EmCapitulo                 : Ato≠nil, Cap≠nil, Cena=nil
    EmCena                     : Ato≠nil, Cap≠nil, Cena≠nil

  Transições-chave:
    • Heading 1 "Capítulo N" → fecha cena, fecha capítulo,
      (se N ∈ {1,8,15 fecha ato), abre novo ato se preciso,
      abre novo capítulo.
    • Parágrafo vazio        → fecha cena.
    • Parágrafo com imagem   → ignorado (não muda estado).
    • Parágrafo normal       → abre cena se não houver,
      adiciona parágrafo.

  Regras de robustez:
    • Fechar só se aberto. Abrir só quando há conteúdo.
    • Parser NUNCA lança por conteúdo estranho — só registra
      anomalia tipada. Exceção apenas em falha fatal (arquivo
      inexistente, .docx corrompido, sem parágrafos).
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Hash,
  System.RegularExpressions,
  UIDocxReader,
  UIParserManuscrito,
  UManuscrito,
  UAnomaliaParse,
  UServicosDominio,
  UValores;

type
  TParserManuscrito = class(TInterfacedObject, IParserManuscrito)
  private
    FReader: IDocxReader;
    FLimiteParagrafoPalavras: Integer;

    FManuscrito: TManuscrito;
    FLog: TParseLog;
    FAtoAtual: TAto;
    FCapAtual: TCapitulo;
    FCenaAtual: TCena;
    FUltimoNumeroCapitulo: Integer;
    FEncontrouHeading1: Boolean;

    FTotalPalavras: Integer;
    FParagrafosGrandes: Integer;

    procedure ProcessarHeading1(const ATexto: string;
      const ANumeroCapitulo: Integer);
    procedure ProcessarImagem;
    procedure ProcessarVazio;
    procedure ProcessarParagrafoNormal(const ATexto: string);

    procedure FecharCenaSeAberta;
    procedure FecharCapituloSeAberto;
    procedure FecharAtoSeAberto;
    procedure AbrirNovoAto(const ANumeroAto: Integer);
    procedure AbrirNovoCapitulo(const ANumeroCapitulo: Integer;
      const ATitulo: string);
    procedure AbrirNovaCenaSeNecessario;
    procedure AdicionarParagrafoAtual(const ATexto: string);

    procedure FinalizarParse;
    procedure RegistrarAnomaliasFinais;
    procedure PreencherResumo;
    procedure RegistrarValidacaoEstrutural;

    function EhHeading1DeCapitulo(const ATexto: string;
      out ANumeroCapitulo: Integer): Boolean;
    procedure CriarCapituloZero(const AParagrafoTexto: string);
    function CalcularHashArquivo(const ACaminho: string): string;
    procedure ResetarEstado;
  public
    constructor Create(const AReader: IDocxReader;
      const ALimiteParagrafoPalavras: Integer = LIMITE_PARAGRAFO_PALAVRAS);

    function Parsear(const ACaminho: string): TParseResultado;
  end;

implementation

{ TParserManuscrito }

constructor TParserManuscrito.Create(const AReader: IDocxReader;
  const ALimiteParagrafoPalavras: Integer);
begin
  inherited Create;
  if not Assigned(AReader) then
    raise EValorInvalido.Create('IDocxReader não pode ser nil.');

  FReader := AReader;
  FLimiteParagrafoPalavras := ALimiteParagrafoPalavras;
end;

procedure TParserManuscrito.ResetarEstado;
begin
  FManuscrito := nil;
  FLog := nil;
  FAtoAtual := nil;
  FCapAtual := nil;
  FCenaAtual := nil;
  FUltimoNumeroCapitulo := 0;
  FEncontrouHeading1 := False;
  FTotalPalavras := 0;
  FParagrafosGrandes := 0;
end;

function TParserManuscrito.Parsear(const ACaminho: string): TParseResultado;
var
  Doc: IDocumentoDocx;
  Par: IParagrafoDocx;
  Texto: string;
  NumeroCapitulo: Integer;
  Sucesso: Boolean;
begin
  if not FileExists(ACaminho) then
    raise Exception.CreateFmt('Arquivo .docx não encontrado: %s', [ACaminho]);

  ResetarEstado;

  FManuscrito := TManuscrito.Create;
  FLog := TParseLog.Create;

  Sucesso := False;
  try
    try
      FManuscrito.ArquivoOrigem := ExtractFileName(ACaminho);
      FManuscrito.GeradoEm := Now;
      FManuscrito.Titulo := ChangeFileExt(FManuscrito.ArquivoOrigem, '');
      FManuscrito.HashArquivo := CalcularHashArquivo(ACaminho);

      FLog.Arquivo := FManuscrito.ArquivoOrigem;
      FLog.Timestamp := Now;

      Doc := FReader.Abrir(ACaminho);

      if Doc.TotalParagrafos = 0 then
      begin
        FLog.Registrar(saErro, taArquivoVazio, 'global',
          'Documento não contém nenhum parágrafo.');
        FinalizarParse;
        PreencherResumo;

        Result := TParseResultado.Create(FManuscrito, FLog);
        Sucesso := True;
        Exit;
      end;

      for Par in Doc.Paragrafos do
      begin
        // 1) Cabeçalho de capítulo?
        //    Detecção por texto, não por estilo (a lib não
        //    expõe estilo de parágrafo).
        Texto := Par.Texto.Trim;
        if EhHeading1DeCapitulo(Texto, NumeroCapitulo) then
        begin
          ProcessarHeading1(Texto, NumeroCapitulo);
          Continue;
        end;

        // 2) Parágrafo com imagem?
        if Par.TemImagem then
        begin
          ProcessarImagem;
          Continue;
        end;

        // 3) Parágrafo vazio?
        if Par.EhVazio then
        begin
          ProcessarVazio;
          Continue;
        end;

        // 4) Parágrafo normal
        ProcessarParagrafoNormal(Texto);
      end;

      FinalizarParse;
      RegistrarAnomaliasFinais;
      RegistrarValidacaoEstrutural;
      PreencherResumo;

      Result := TParseResultado.Create(FManuscrito, FLog);
      Sucesso := True;
    except
      raise;
    end;
  finally
    if not Sucesso then
    begin
      FreeAndNil(FManuscrito);
      FreeAndNil(FLog);
    end;
  end;
end;

// ────────────────────────────────────────────────────────────
// Processamento por tipo de parágrafo
// ────────────────────────────────────────────────────────────

procedure TParserManuscrito.ProcessarHeading1(const ATexto: string;
  const ANumeroCapitulo: Integer);
begin
  FEncontrouHeading1 := True;

  // 1) Fecha cena e capítulo abertos.
  FecharCenaSeAberta;
  FecharCapituloSeAberto;

  // 2) Se é início de novo ato — ou se não há ato aberto (caso
  //    o primeiro capítulo encontrado seja > 1) — abre novo ato.
  if (FAtoAtual = nil) or TCalculadoraAtos.EhInicioDeAto(ANumeroCapitulo) then
  begin
    FecharAtoSeAberto;
    AbrirNovoAto(TCalculadoraAtos.AtoDoCapitulo(ANumeroCapitulo));
  end;

  // 3) Valida sequência antes de abrir o novo capítulo.
  if (FUltimoNumeroCapitulo > 0) and
     (ANumeroCapitulo <> FUltimoNumeroCapitulo + 1) then
    FLog.Registrar(saAviso, taSequenciaCapitulosQuebrada,
      Format('cap-%d', [ANumeroCapitulo]),
      Format('Sequência quebrada: esperado cap %d, encontrado cap %d.',
        [FUltimoNumeroCapitulo + 1, ANumeroCapitulo]));

  // 4) Abre o novo capítulo.
  AbrirNovoCapitulo(ANumeroCapitulo, ATexto);
  FUltimoNumeroCapitulo := ANumeroCapitulo;
end;

procedure TParserManuscrito.ProcessarImagem;
begin
  // Ignorado por design. Não muda estado, não vira conteúdo.
  // A imagem separadora do manuscrito é absorvida entre as
  // duas linhas em branco que delimitam a cena.
end;

procedure TParserManuscrito.ProcessarVazio;
begin
  FecharCenaSeAberta;
end;

procedure TParserManuscrito.ProcessarParagrafoNormal(const ATexto: string);
begin
  // Conteúdo antes do primeiro capítulo → capítulo 0.
  if FCapAtual = nil then
    CriarCapituloZero(ATexto);

  AbrirNovaCenaSeNecessario;
  AdicionarParagrafoAtual(ATexto);
end;

// ────────────────────────────────────────────────────────────
// Transições de estado
// ────────────────────────────────────────────────────────────

procedure TParserManuscrito.FecharCenaSeAberta;
begin
  // A cena já está no capítulo — só desvincula a referência.
  FCenaAtual := nil;
end;

procedure TParserManuscrito.FecharCapituloSeAberto;
begin
  if FCapAtual = nil then
    Exit;

  if FCapAtual.Cenas.Count = 0 then
    FLog.Registrar(saAviso, taCapituloSemCena, FCapAtual.ID,
      Format('Capítulo %d não contém nenhuma cena.', [FCapAtual.Numero]));

  FCapAtual := nil;
end;

procedure TParserManuscrito.FecharAtoSeAberto;
begin
  FAtoAtual := nil;
end;

procedure TParserManuscrito.AbrirNovoAto(const ANumeroAto: Integer);
begin
  FAtoAtual := TAto.Create;
  FAtoAtual.Numero := ANumeroAto;
  FAtoAtual.ID := GerarIDAto(ANumeroAto);
  FManuscrito.Atos.Add(FAtoAtual);
end;

procedure TParserManuscrito.AbrirNovoCapitulo(const ANumeroCapitulo: Integer;
  const ATitulo: string);
begin
  FCapAtual := TCapitulo.Create;
  FCapAtual.Numero := ANumeroCapitulo;
  FCapAtual.Titulo := ATitulo;
  FCapAtual.ID := GerarIDCapitulo(ANumeroCapitulo);
  FAtoAtual.Capitulos.Add(FCapAtual);
end;

procedure TParserManuscrito.AbrirNovaCenaSeNecessario;
begin
  if FCenaAtual <> nil then
    Exit;

  FCenaAtual := TCena.Create;
  FCenaAtual.Numero := FCapAtual.Cenas.Count + 1;
  FCenaAtual.ID := GerarIDCena(FCapAtual.Numero, FCenaAtual.Numero);
  FCapAtual.Cenas.Add(FCenaAtual);
end;

procedure TParserManuscrito.AdicionarParagrafoAtual(const ATexto: string);
var
  Par: TParagrafo;
begin
  Par := TParagrafo.Create;
  Par.Ordem := FCenaAtual.Paragrafos.Count + 1;
  Par.ID := GerarIDParagrafo(FCapAtual.Numero,
    FCenaAtual.Numero, Par.Ordem);
  Par.Texto := ATexto;
  Par.Hash := THashSHA1.GetHashString(ATexto);
  Par.NumPalavras := ContarPalavras(ATexto);
  Par.NumChunks := TCompressorPayload.EstimarNumChunks(ATexto);
  FCenaAtual.Paragrafos.Add(Par);

  Inc(FTotalPalavras, Par.NumPalavras);
  if Par.NumChunks > 1 then
    Inc(FParagrafosGrandes);
end;

// ────────────────────────────────────────────────────────────
// Finalização
// ────────────────────────────────────────────────────────────

procedure TParserManuscrito.FinalizarParse;
begin
  FecharCenaSeAberta;
  FecharCapituloSeAberto;
  FecharAtoSeAberto;
end;

procedure TParserManuscrito.RegistrarAnomaliasFinais;
begin
  if not FEncontrouHeading1 then
    FLog.Registrar(saErro, taDocumentoSemHeading1, 'global',
      'Nenhum parágrafo com estilo "Heading 1" no formato ' +
      '"Capítulo N" foi encontrado no documento.');
end;

procedure TParserManuscrito.RegistrarValidacaoEstrutural;
begin
  // Contagens agregadas — o resto já foi registrado em tempo real
  // (sequência, capítulo vazio). Aqui só checamos totais.
  if (FManuscrito.Atos.Count > 0) and (FManuscrito.Atos.Count <> 3) then
    FLog.Registrar(saAviso, taNumeroCapitulosDivergente, 'global',
      Format('Esperados 3 atos, encontrados %d.', [FManuscrito.Atos.Count]));

  if (FManuscrito.TotalCapitulos > 0) and
     (FManuscrito.TotalCapitulos <> CAPITULOS_TOTAIS) then
    FLog.Registrar(saAviso, taNumeroCapitulosDivergente, 'global',
      Format('Esperados %d capítulos, encontrados %d.',
        [CAPITULOS_TOTAIS, FManuscrito.TotalCapitulos]));
end;

procedure TParserManuscrito.PreencherResumo;
begin
  FLog.Resumo.Atos := FManuscrito.Atos.Count;
  FLog.Resumo.Capitulos := FManuscrito.TotalCapitulos;
  FLog.Resumo.Cenas := FManuscrito.TotalCenas;
  FLog.Resumo.Paragrafos := FManuscrito.TotalParagrafos;
  FLog.Resumo.Palavras := FTotalPalavras;
  FLog.Resumo.ParagrafosGrandes := FParagrafosGrandes;
end;

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

function TParserManuscrito.EhHeading1DeCapitulo(const ATexto: string;
  out ANumeroCapitulo: Integer): Boolean;
var
  Match: TMatch;
begin
  ANumeroCapitulo := 0;
  Result := False;

  if ATexto = '' then
    Exit;

  // Case-sensitive: exige "Capítulo" com C maiúsculo e
  // acento. Aceita também "Capitulo" sem acento, ainda com
  // C maiúsculo, para tolerar manuscritos sem acentuação.
  Match := TRegEx.Match(ATexto, '^(Capítulo|Capitulo)\s+(\d+)',
    [roMultiLine]);
  if not Match.Success then
    Exit;

  Result := TryStrToInt(Match.Groups[2].Value, ANumeroCapitulo);
end;

procedure TParserManuscrito.CriarCapituloZero(const AParagrafoTexto: string);
begin
  FLog.Registrar(saInfo, taConteudoAntesDoPrimeiroCapitulo, 'inicio',
    'Criado capítulo 0 para conter parágrafos anteriores ao ' +
    'primeiro "Capítulo N".');

  FAtoAtual := TAto.Create;
  FAtoAtual.Numero := 1;
  FAtoAtual.ID := GerarIDAto(1);
  FManuscrito.Atos.Add(FAtoAtual);

  AbrirNovoCapitulo(0, '(sem capítulo)');
end;

function TParserManuscrito.CalcularHashArquivo(
  const ACaminho: string): string;
begin
  try
    Result := THashSHA2.GetHashStringFromFile(ACaminho);
  except
    // Hash é informativo — não bloqueia o parse.
    Result := '';
  end;
end;

end.
