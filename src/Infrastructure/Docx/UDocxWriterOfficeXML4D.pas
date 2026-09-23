unit UDocxWriterOfficeXML4D;

{
  UDocxWriterOfficeXML4D.pas
  ─────────────────────────────────────────────────────────────
  Adaptador de escrita de .docx usando a OfficeXML4D.

  Regras de escrita (espelham o parser):
    • Cabeçalho de capítulo → parágrafo com estilo "Heading 1",
      texto "Capítulo N" (ou Titulo do capítulo, se preenchido).
    • Parágrafos de cena  → estilo "Normal" (Texto Normal).
    • Entre cenas do mesmo capítulo → um parágrafo vazio
      (linha em branco).
    • A imagem separadora do manuscrito original NÃO é
      reproduzida (decisão travada — linha em branco basta
      para o parser reler como separador de cena).
    • Título de Ato NÃO é escrito — o ato é derivado da
      posição do capítulo (regra do parser).

  ⚠ PONTOS A VERIFICAR QUANDO COMPILAR PELA PRIMEIRA VEZ:
    1. Nome do unit da OfficeXML4D (uses).
    2. Classe do documento (TWordDocument? TDocxDocument?).
    3. Como criar um documento vazio (Create? NewDocument?).
    4. Como adicionar um parágrafo com texto e estilo.
    5. Nome exato do estilo de corpo ("Normal" ou
       "Texto Normal" — depende da localização da lib).
    6. Como salvar em arquivo (SaveToFile? Save? WriteTo?).
    Tudo isso se resolve em TOfficeXML4D_Contato.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils,
  UIDocxWriter,
  UManuscrito;

type
  /// <summary>
  ///   Escreve um TManuscrito em .docx via OfficeXML4D.
  ///   Segue as regras de estilo do parser para permitir
  ///   round-trip.
  /// </summary>
  TDocxWriterOfficeXML4D = class(TInterfacedObject, IDocxWriter)
  public
    /// <summary>
    ///   Escreve o manuscrito no caminho indicado.
    ///   Sobrescreve se já existir.
    /// </summary>
    procedure Escrever(const AManuscrito: TManuscrito;
      const ACaminho: string);
  end;

implementation

// ═══════════════════════════════════════════════════════════════════
//  ÁREA DE CONTATO COM A OFFICEXML4D
//
//  Todo acesso à lib externa passa por aqui. Se a API real for
//  diferente, ajuste APENAS este bloco.
//
//  Suposições feitas:
//    • Unit da lib: "OfficeXML4D".
//    • Classe do documento: TWordDocument.
//    • Criação: TWordDocument.Create (documento vazio).
//    • Adicionar parágrafo: Doc.AddParagraph(Texto, EstiloNome).
//      Alternativa comum: Doc.AddParagraph; P := Doc.Paragraphs.Last;
//      P.Text := Texto; P.StyleName := EstiloNome.
//    • Salvar: Doc.SaveToFile(Caminho).
// ═══════════════════════════════════════════════════════════════════

uses
  // ⚠ Ajustar: nome real da unit do OfficeXML4D.
  OfficeXML4D;

const
  /// <summary>Nome do estilo de capítulo, como a lib reporta.</summary>
  ESTILO_HEADING_1 = 'Heading 1';

  /// <summary>
  ///   Nome do estilo de corpo. Se a lib estiver em português,
  ///   pode ser 'Texto Normal'. Ajustar após primeiro teste.
  /// </summary>
  ESTILO_CORPO = 'Normal';

type
  TOfficeXML4D_ContatoWriter = class
  public
    /// <summary>Cria um documento vazio. Retorna handle opaco.</summary>
    class function CriarDocumento: TObject;

    /// <summary>
    ///   Adiciona um parágrafo com o texto e o estilo indicados.
    ///   Texto vazio gera parágrafo em branco.
    /// </summary>
    class procedure AdicionarParagrafo(const ADoc: TObject;
      const ATexto, AEstilo: string);

    /// <summary>Salva o documento em disco.</summary>
    class procedure Salvar(const ADoc: TObject; const ACaminho: string);

    /// <summary>Libera o documento.</summary>
    class procedure LiberarDocumento(const ADoc: TObject);
  end;

// ───────────────────────────────────────────────────────────────────
// Implementação da área de contato — AJUSTAR CONFORME A API REAL
// ───────────────────────────────────────────────────────────────────

class function TOfficeXML4D_ContatoWriter.CriarDocumento: TObject;
begin
  // ⚠ Ajustar: forma real de criar documento vazio.
  // Se a lib expõe função factory: TWordDocument.NewDocument.
  Result := TWordDocument.Create;
end;

class procedure TOfficeXML4D_ContatoWriter.AdicionarParagrafo(
  const ADoc: TObject; const ATexto, AEstilo: string);
begin
  // ⚠ Ajustar: forma real de adicionar parágrafo.
  // Suposição: AddParagraph(Texto, EstiloNome).

  if ATexto = '' then
    TWordDocument(ADoc).AddParagraph('', AEstilo)
  else
    TWordDocument(ADoc).AddParagraph(ATexto, AEstilo);
end;

class procedure TOfficeXML4D_ContatoWriter.Salvar(
  const ADoc: TObject; const ACaminho: string);
begin
  // ⚠ Ajustar: forma real de salvar.
  TWordDocument(ADoc).SaveToFile(ACaminho);
end;

class procedure TOfficeXML4D_ContatoWriter.LiberarDocumento(
  const ADoc: TObject);
begin
  ADoc.Free;
end;

// ═══════════════════════════════════════════════════════════════════
//  A partir daqui, nada toca a OfficeXML4D diretamente.
// ═══════════════════════════════════════════════════════════════════

// ────────────────────────────────────────────────────────────
// TDocxWriterOfficeXML4D
// ────────────────────────────────────────────────────────────

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
begin
  if AManuscrito = nil then
    raise Exception.Create('Manuscrito não pode ser nil.');

  Doc := nil;
  try
    Doc := TOfficeXML4D_ContatoWriter.CriarDocumento;

    for Ato in AManuscrito.Atos do
      for Cap in Ato.Capitulos do
      begin
        // Cabeçalho do capítulo como Heading 1.
        // Prefere o título original; se vazio, gera "Capítulo N".
        TituloCapitulo := Cap.Titulo.Trim;
        if TituloCapitulo = '' then
          TituloCapitulo := Format('Capítulo %d', [Cap.Numero]);

        TOfficeXML4D_ContatoWriter.AdicionarParagrafo(
          Doc, TituloCapitulo, ESTILO_HEADING_1);

        // Cenas do capítulo.
        IndiceCena := 0;
        for Cena in Cap.Cenas do
        begin
          Inc(IndiceCena);

          // Separador de cena: linha em branco antes de toda
          // cena que não seja a primeira do capítulo.
          if IndiceCena > 1 then
            TOfficeXML4D_ContatoWriter.AdicionarParagrafo(
              Doc, '', ESTILO_CORPO);

          // Parágrafos da cena.
          for Par in Cena.Paragrafos do
            TOfficeXML4D_ContatoWriter.AdicionarParagrafo(
              Doc, Par.Texto, ESTILO_CORPO);
        end;
      end;

    TOfficeXML4D_ContatoWriter.Salvar(Doc, ACaminho);
  finally
    if Doc <> nil then
      TOfficeXML4D_ContatoWriter.LiberarDocumento(Doc);
  end;
end;

end.
