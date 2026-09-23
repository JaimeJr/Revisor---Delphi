unit UIDocxWriter;

{
  UIDocxWriter.pas
  ─────────────────────────────────────────────────────────────
  Adaptador de escrita de .docx. Constrói o documento final
  a partir do Novo.JSON, aplicando estilos corretos.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UManuscrito;

type
  /// <summary>
  ///   Escritor de .docx. Responsável por montar o arquivo
  ///   final respeitando a hierarquia Ato → Capítulo → Cena →
  ///   Parágrafo e os estilos (Heading 1 para capítulos,
  ///   Texto Normal para o corpo).
  /// </summary>
  IDocxWriter = interface
   ['{DAB6CB46-DB3C-4584-8C1C-10C927FD0066}']

    /// <summary>
    ///   Escreve o manuscrito em .docx no caminho indicado.
    ///   Sobrescreve se já existir.
    /// </summary>
    procedure Escrever(const AManuscrito: TManuscrito;
      const ACaminho: string);
  end;

implementation

end.
