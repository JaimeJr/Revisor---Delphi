unit UDocxReaderOfficeXML4D;


interface

uses
  System.SysUtils,
  System.Classes,
  UIDocxReader;

type
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
  ///   método retornar.
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
// ═══════════════════════════════════════════════════════════════════

uses
  Office4D.Word,
  Office4D.Word.Document;

type
  TOfficeXML4D_Contato = class
  public
    class function AbrirDocumento(const ACaminho: string): TObject;
    class procedure LiberarDocumento(const ADoc: TObject);
    class function TotalParagrafos(const ADoc: TObject): Integer;
    class function TextoDoParagrafo(const ADoc: TObject;
      const AIndex: Integer): string;
    class function EstiloDoParagrafo(const ADoc: TObject;
      const AIndex: Integer): string;
    class function ParagrafoTemImagem(const ADoc: TObject;
      const AIndex: Integer): Boolean;
  end;

// ───────────────────────────────────────────────────────────────────
// Implementação da área de contato — API REAL da OfficeXML4D
// ───────────────────────────────────────────────────────────────────

class function TOfficeXML4D_Contato.AbrirDocumento(
  const ACaminho: string): TObject;
begin
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
  Result := TWordDocument(ADoc).GetParagraphCount;
end;

class function TOfficeXML4D_Contato.TextoDoParagrafo(
  const ADoc: TObject; const AIndex: Integer): string;
var
  Par: IWordParagraph;
  SB: TStringBuilder;
  J: Integer;
begin
  // Não usamos Par.Text porque a implementação da lib tem
  // bug de indexação (List index out of bounds). Iteramos
  // os runs manualmente.
  Par := TWordDocument(ADoc).GetParagraph(AIndex);

  if Par.RunCount = 0 then
    Exit('');

  SB := TStringBuilder.Create;
  try
    for J := 0 to Par.RunCount - 1 do
      SB.Append(Par.Runs[J].Text);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

class function TOfficeXML4D_Contato.EstiloDoParagrafo(
  const ADoc: TObject; const AIndex: Integer): string;
begin
  // A lib não expõe estilo de parágrafo (só ListStyle, que é
  // diferente). O parser não depende disso — identifica
  // capítulos pelo texto "Capítulo N".
  Result := '';
end;

class function TOfficeXML4D_Contato.ParagrafoTemImagem(
  const ADoc: TObject; const AIndex: Integer): Boolean;
var
  Par: IWordParagraph;
  J: Integer;
begin
  Par := TWordDocument(ADoc).GetParagraph(AIndex);

  for J := 0 to Par.RunCount - 1 do
    if Par.Runs[J].HasImage then
      Exit(True);
  Result := False;
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
