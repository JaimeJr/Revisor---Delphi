unit UIComandoEditorial;

{
  UIComandoEditorial.pas
  ─────────────────────────────────────────────────────────────
  Contrato de comando editorial reversível. Todo comando tem
  Executar e Desfazer, permitindo undo/redo sem estado extra.

  A pilha de comandos (CommandStack) é uma implementação
  concreta que fica na camada Application.
  ─────────────────────────────────────────────────────────────
}

interface

type
  IComandoEditorial = interface
    ['{451A2F4E-8FFF-4BA1-ADFE-0C92DBB54684}']

    /// <summary>Aplica o comando. Deve ser idempotente.</summary>
    procedure Executar;

    /// <summary>
    ///   Reverte o comando. Deve restaurar o estado anterior
    ///   exatamente como estava antes de Executar.
    /// </summary>
    procedure Desfazer;

    /// <summary>Descrição curta para log/UI ("Aceitar edição em p03").</summary>
    function Descricao: string;
  end;

implementation

end.
