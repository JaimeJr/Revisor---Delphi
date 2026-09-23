unit UIDocxReader;

{
  UIDocxReader.pas
  ─────────────────────────────────────────────────────────────
  Adaptador de leitura de .docx. Isola a biblioteca externa
  (OfficeXML4D) do resto do sistema.

  O parser não conhece OfficeXML4D — conhece esta interface.
  Trocar a lib = reimplementar esta interface.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Um parágrafo lido do .docx, já traduzido para tipos
  ///   neutros (sem dependência da lib externa).
  /// </summary>
  IParagrafoDocx = interface
    ['{0DE6FAA3-ACE9-4033-8477-62EA2B0D365F}']
    function Texto: string;
    function Estilo: string;
    function TemImagem: Boolean;
    function EhVazio: Boolean;
  end;

  /// <summary>Documento aberto para leitura sequencial.</summary>
  IDocumentoDocx = interface
    ['{033AD08F-065F-4C43-8818-9422949BBC75}']
    function Paragrafos: TArray<IParagrafoDocx>;
    function TotalParagrafos: Integer;
  end;

  /// <summary>Abre .docx e devolve o documento para iteração.</summary>
  IDocxReader = interface
    ['{8CFFE0D5-CA7A-4DB8-AD64-752B5E46CF0E}']
    function Abrir(const ACaminho: string): IDocumentoDocx;
  end;

implementation

end.
