unit UDocxReaderOfficeXML4D;

{
  UDocxReaderOfficeXML4D.pas
  ─────────────────────────────────────────────────────────────
  Adaptador de leitura de .docx usando a OfficeXML4D.

  Estratégia de desacoplamento:
    • A lib externa é tocada APENAS em TOfficeXML4D_Contato.
    • Os adapters (TParagrafoDocxAdapter, TDocumentoDocxAdapter)
      copiam os dados da lib no momento da leitura e se
      desconectam completamente — o documento externo pode ser
      liberado logo após Abrir() retornar.
    • Nenhuma outra unit do projeto referencia a OfficeXML4D
      diretamente. Trocar de lib = reimplementar este arquivo.

  ⚠ PONTOS A VERIFICAR QUANDO COMPILAR PELA PRIMEIRA VEZ:
    1. Nome do unit da OfficeXML4D (uses).
    2. Nome da classe principal do documento.
    3. Forma de carregar o arquivo (constructor vs LoadFromFile).
    4. Como iterar parágrafos (Paragraphs? Paragraph[i]? Enumerator?).
    5. Como obter texto puro de um parágrafo.
    6. Como obter o estilo de um parágrafo.
    7. Como detectar presença de imagem (drawing/pict) em um
       parágrafo.
    Todas essas dúvidas se resolvem em TOfficeXML4D_Contato.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  System.Classes,
  UIDocxReader;

type
  // ────────────────────────────────────────────────────────────
  // Adapter de parágrafo
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Implementação de IParagrafoDocx destacada da lib.
  ///   Todos os campos são copiados no construtor, e o objeto
  ///   vive independente da lib a partir daí.
  /// </summary>
  TParagrafoDocxAdapter = class(TInterfacedObject, IParagrafoDocx)
  private
    FTexto: string;
    FEstilo: string;
    FTemImagem: Boolean;
  public
    constructor Create(const ATexto, AEstilo: string; ATemImagem: Boolean);

    function Texto: string;
    function Estilo: string;
    function TemImagem: Boolean;
    function EhVazio: Boolean;
  end;

  // ────────────────────────────────────────────────────────────
  // Adapter de documento
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Implementação de IDocumentoDocx destacada da lib.
  ///   Só guarda o array de parágrafos já adaptados.
  /// </summary>
  TDocumentoDocxAdapter = class(TInterfacedObject, IDocumentoDocx)
  private
    FParagrafos: TArray<IParagrafoDocx>;
  public
    constructor Create(const AParagrafos: TArray<IParagrafoDocx>);

    function Paragrafos: TArray<IParagrafoDocx>;
    function TotalParagrafos: Integer;
  end;

  // ────────────────────────────────────────────────────────────
  // Reader
  // ────────────────────────────────────────────────────────────

  /// <summary>
  ///   Abre um .docx via OfficeXML4D e devolve o documento
  ///   adaptado. O documento externo é liberado antes deste
  ///   método retornar — o chamador só recebe dados puros.
  /// </summary>
  TDocxReaderOfficeXML4D = class(TInterfacedObject, IDocxReader)
  public
    function Abrir(const ACaminho: string): IDocumentoDocx;
  end;

implementation

// ═══════════════════════════════════════════════════════════════════
//  ÁREA DE CONTATO COM A OFFICEXML4D
//
//  Todo acesso à lib externa passa por aqui. Se a API real for
//  diferente, ajuste APENAS este bloco.
//
//  Abaixo, a implementação assumida:
//    • Unit da lib: "OfficeXML4D" (ajustar no uses).
//    • Classe do documento: TWordDocument.
//    • Carregamento: TWordDocument.Create; Doc.LoadFromFile(caminho).
//    • Iteração: Doc.Paragraphs (coleção indexada 0..Count-1),
//      ou o doc suporta "for p in Doc.Paragraphs" via GetEnumerator.
//    • Texto: p.Text (string).
//    • Estilo: p.StyleName (string).
//    • Imagem: p.HasDrawing (Boolean) — pode ser p.HasImage
//      ou precisa iterar p.Runs e checar Run.HasImage.
// ═══════════════════════════════════════════════════════════════════

uses
  // ⚠ Ajustar: nome real da unit do OfficeXML4D.
  // Pode ser "OfficeXML4D", "OfficeXML4D.Word",
  // "OfficeXML4D.Word.Document" — depende do pacote instalado.
  OfficeXML4D;

type
  TOfficeXML4D_Contato = class
  public
    /// <summary>
    ///   Abre o documento. Retorna um handle opaco que o
    ///   chamador deve passar para as outras funções e
    ///   liberar com LiberarDocumento.
    /// </summary>
    class function AbrirDocumento(const ACaminho: string): TObject;

    /// <summary>Libera o documento aberto.</summary>
    class procedure LiberarDocumento(const ADoc: TObject);

    /// <summary>Total de parágrafos no documento.</summary>
    class function TotalParagrafos(const ADoc: TObject): Integer;

    /// <summary>Texto puro do parágrafo no índice indicado (0-based).</summary>
    class function TextoDoParagrafo(const ADoc: TObject;
      const AIndex: Integer): string;

    /// <summary>Nome do estilo do parágrafo (ex: "Heading 1").</summary>
    class function EstiloDoParagrafo(const ADoc: TObject;
      const AIndex: Integer): string;

    /// <summary>True se o parágrafo contém imagem inline.</summary>
    class function ParagrafoTemImagem(const ADoc: TObject;
      const AIndex: Integer): Boolean;
  end;

// ───────────────────────────────────────────────────────────────────
// Implementação da área de contato — AJUSTAR CONFORME A API REAL
// ───────────────────────────────────────────────────────────────────

class function TOfficeXML4D_Contato.AbrirDocumento(
  const ACaminho: string): TObject;
begin
  // ⚠ Ajustar: forma real de abrir o arquivo.
  // A suposição abaixo usa TWordDocument com LoadFromFile.
  //
  // Se a lib expõe um construtor que já carrega:
  //   Result := TWordDocument.Create(ACaminho);
  // Se expõe uma função factory:
  //   Result := TWordDocument.Load(ACaminho);

  var Doc := TWordDocument.Create;
  try
    Doc.LoadFromFile(ACaminho);
    Result := Doc;
  except
    Doc.Free;
    raise;
  end;
end;

class procedure TOfficeXML4D_Contato.LiberarDocumento(
  const ADoc: TObject);
begin
  ADoc.Free;
end;

class function TOfficeXML4D_Contato.TotalParagrafos(
  const ADoc: TObject): Integer;
begin
  // ⚠ Ajustar: nome real da coleção de parágrafos.
  // Suposição: TWordDocument.Paragraphs com propriedade Count.
  Result := TWordDocument(ADoc).Paragraphs.Count;
end;

class function TOfficeXML4D_Contato.TextoDoParagrafo(
  const ADoc: TObject; const AIndex: Integer): string;
begin
  // ⚠ Ajustar: forma real de obter o parágrafo e o texto.
  // Suposição: Paragraphs[i].Text (0-based).
  Result := TWordDocument(ADoc).Paragraphs[AIndex].Text;
end;

class function TOfficeXML4D_Contato.EstiloDoParagrafo(
  const ADoc: TObject; const AIndex: Integer): string;
begin
  // ⚠ Ajustar: nome real da propriedade de estilo.
  // Pode ser .StyleName, .Style, .StyleID — depende da lib.
  // Estilos típicos retornados: 'Heading 1', 'Normal',
  // 'Heading 2', etc.
  Result := TWordDocument(ADoc).Paragraphs[AIndex].StyleName;
end;

class function TOfficeXML4D_Contato.ParagrafoTemImagem(
  const ADoc: TObject; const AIndex: Integer): Boolean;
begin
  // ⚠ Ajustar: forma real de detectar imagem.
  //
  // Três cenários possíveis:
  //
  // (a) A lib expõe uma propriedade direta:
  //     Result := TWordDocument(ADoc).Paragraphs[AIndex].HasDrawing;
  //
  // (b) A lib permite iterar runs e checar cada um:
  //     Result := False;
  //     for Run in TWordDocument(ADoc).Paragraphs[AIndex].Runs do
  //       if Run.HasImage then
  //         Exit(True);
  //
  // (c) A lib expõe o XML cru do parágrafo:
  //     var Xml := TWordDocument(ADoc).Paragraphs[AIndex].Xml;
  //     Result := (Pos('<w:drawing', Xml) > 0) or
  //               (Pos('<w:pict', Xml) > 0);
  //
  // Abaixo, a suposição (a):

  Result := TWordDocument(ADoc).Paragraphs[AIndex].HasDrawing;
end;

// ═══════════════════════════════════════════════════════════════════
//  A partir daqui, nada toca a OfficeXML4D diretamente.
//  Só TOfficeXML4D_Contato faz a ponte.
// ═══════════════════════════════════════════════════════════════════

// ────────────────────────────────────────────────────────────
// TParagrafoDocxAdapter
// ────────────────────────────────────────────────────────────

constructor TParagrafoDocxAdapter.Create(const ATexto, AEstilo: string;
  ATemImagem: Boolean);
begin
  inherited Create;
  FTexto := ATexto;
  FEstilo := AEstilo;
  FTemImagem := ATemImagem;
end;

function TParagrafoDocxAdapter.Texto: string;
begin
  Result := FTexto;
end;

function TParagrafoDocxAdapter.Estilo: string;
begin
  Result := FEstilo;
end;

function TParagrafoDocxAdapter.TemImagem: Boolean;
begin
  Result := FTemImagem;
end;

function TParagrafoDocxAdapter.EhVazio: Boolean;
begin
  // Vazio = sem texto E sem imagem.
  // Parágrafo com imagem não é vazio (mas o parser o ignora
  // por outra regra, não por esta).
  Result := (FTexto.Trim = '') and not FTemImagem;
end;

// ────────────────────────────────────────────────────────────
// TDocumentoDocxAdapter
// ────────────────────────────────────────────────────────────

constructor TDocumentoDocxAdapter.Create(
  const AParagrafos: TArray<IParagrafoDocx>);
begin
  inherited Create;
  FParagrafos := AParagrafos;
end;

function TDocumentoDocxAdapter.Paragrafos: TArray<IParagrafoDocx>;
begin
  Result := FParagrafos;
end;

function TDocumentoDocxAdapter.TotalParagrafos: Integer;
begin
  Result := Length(FParagrafos);
end;

// ────────────────────────────────────────────────────────────
// TDocxReaderOfficeXML4D
// ────────────────────────────────────────────────────────────

function TDocxReaderOfficeXML4D.Abrir(
  const ACaminho: string): IDocumentoDocx;
var
  Doc: TObject;
  Total, I: Integer;
  Texto, Estilo: string;
  TemImagem: Boolean;
  Paragrafos: TArray<IParagrafoDocx>;
begin
  if not FileExists(ACaminho) then
    raise Exception.CreateFmt('Arquivo .docx não encontrado: %s', [ACaminho]);

  Doc := nil;
  try
    Doc := TOfficeXML4D_Contato.AbrirDocumento(ACaminho);

    Total := TOfficeXML4D_Contato.TotalParagrafos(Doc);
    SetLength(Paragrafos, Total);

    for I := 0 to Total - 1 do
    begin
      Texto := TOfficeXML4D_Contato.TextoDoParagrafo(Doc, I);
      Estilo := TOfficeXML4D_Contato.EstiloDoParagrafo(Doc, I);
      TemImagem := TOfficeXML4D_Contato.ParagrafoTemImagem(Doc, I);

      Paragrafos[I] := TParagrafoDocxAdapter.Create(Texto, Estilo, TemImagem);
    end;

    Result := TDocumentoDocxAdapter.Create(Paragrafos);
  finally
    // O documento externo é liberado independentemente do que
    // aconteça — os adapters já copiaram tudo que precisavam.
    if Doc <> nil then
      TOfficeXML4D_Contato.LiberarDocumento(Doc);
  end;
end;

end.
