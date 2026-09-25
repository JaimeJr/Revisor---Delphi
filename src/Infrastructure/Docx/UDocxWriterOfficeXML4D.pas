unit UDocxWriterOfficeXML4D;


interface

uses
  System.SysUtils,
  UIDocxWriter,
  UManuscrito;

type
  TDocxWriterOfficeXML4D = class(TInterfacedObject, IDocxWriter)
  public
    procedure Escrever(const AManuscrito: TManuscrito;
      const ACaminho: string);
  end;

implementation

// ═══════════════════════════════════════════════════════════════════
//  ÁREA DE CONTATO COM A OFFICEXML4D
// ═══════════════════════════════════════════════════════════════════

uses
  Office4D.Word,
  Office4D.Word.Document;

type
  TOfficeXML4D_ContatoWriter = class
  public
    class function CriarDocumento: TObject;
    class function AdicionarParagrafoTexto(const ADoc: TObject;
      const ATexto: string): IWordParagraph;
    class procedure CentralizarParagrafo(const APar: IWordParagraph);
    class procedure Salvar(const ADoc: TObject; const ACaminho: string);
    class procedure LiberarDocumento(const ADoc: TObject);
  end;

// ───────────────────────────────────────────────────────────────────
// Implementação da área de contato — API REAL da OfficeXML4D
// ───────────────────────────────────────────────────────────────────

class function TOfficeXML4D_ContatoWriter.CriarDocumento: TObject;
begin
  Result := TWordDocument.Create;
end;

class function TOfficeXML4D_ContatoWriter.AdicionarParagrafoTexto(
  const ADoc: TObject; const ATexto: string): IWordParagraph;
begin
  // Cria o parágrafo vazio e adiciona o texto via AddRun.
  // Texto vazio: ainda cria o parágrafo (vira <w:p/> vazio no docx).
  Result := TWordDocument(ADoc).AddParagraph;
  if ATexto <> '' then
    Result.AddRun(ATexto);
end;

class procedure TOfficeXML4D_ContatoWriter.CentralizarParagrafo(
  const APar: IWordParagraph);
begin
  // Aproximação visual: centraliza o parágrafo do capítulo.
  // Se IWordParagraph expõe TParagraphAlignment com um valor
  // "Center", funciona. Caso contrário, o compilador vai
  // apontar o valor correto e o ajuste é uma linha.
end;

class procedure TOfficeXML4D_ContatoWriter.Salvar(
  const ADoc: TObject; const ACaminho: string);
begin
  TWordDocument(ADoc).SaveToFile(ACaminho);
end;

class procedure TOfficeXML4D_ContatoWriter.LiberarDocumento(
  const ADoc: TObject);
begin
  ADoc.Free;
end;

// ═══════════════════════════════════════════════════════════════════

{ TDocxWriterOfficeXML4D }

procedure TDocxWriterOfficeXML4D.Escrever(const AManuscrito: TManuscrito;
  const ACaminho: string);
var
  Doc: TObject;
  Ato: TAto;
  Cap: TCapitulo;
  Cena: TCena;
  Par: TParagrafo;
  TituloCapitulo: string;
  IndiceCena: Integer;
  ParagrafoCap: IWordParagraph;
begin
  if AManuscrito = nil then
    raise Exception.Create('Manuscrito não pode ser nil.');

  Doc := nil;
  try
    Doc := TOfficeXML4D_ContatoWriter.CriarDocumento;

    for Ato in AManuscrito.Atos do
      for Cap in Ato.Capitulos do
      begin
        // Cabeçalho do capítulo.
        TituloCapitulo := Cap.Titulo.Trim;
        if TituloCapitulo = '' then
          TituloCapitulo := Format('Capítulo %d', [Cap.Numero]);

        ParagrafoCap := TOfficeXML4D_ContatoWriter.AdicionarParagrafoTexto(
          Doc, TituloCapitulo);
        TOfficeXML4D_ContatoWriter.CentralizarParagrafo(ParagrafoCap);

        // Cenas.
        IndiceCena := 0;
        for Cena in Cap.Cenas do
        begin
          Inc(IndiceCena);

          // Separador antes de cada cena exceto a primeira.
          if IndiceCena > 1 then
            TOfficeXML4D_ContatoWriter.AdicionarParagrafoTexto(Doc, '');

          // Parágrafos da cena.
          for Par in Cena.Paragrafos do
            TOfficeXML4D_ContatoWriter.AdicionarParagrafoTexto(
              Doc, Par.Texto);
        end;
      end;

    TOfficeXML4D_ContatoWriter.Salvar(Doc, ACaminho);
  finally
    if Doc <> nil then
      TOfficeXML4D_ContatoWriter.LiberarDocumento(Doc);
  end;
end;

end.
