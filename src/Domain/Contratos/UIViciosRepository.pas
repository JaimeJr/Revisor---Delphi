unit UIViciosRepository;

{
  UIViciosRepository.pas
  ─────────────────────────────────────────────────────────────
  Persistência do Vicios.JSON — catálogo editorial vivo.
  Carregado no boot; salvo quando o usuário adiciona vício
  ou quando uma ocorrência é registrada.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UVicio;

type
  IViciosRepository = interface
    ['{C8B2FC9A-2351-48CB-90B8-44F1022E7AE2}']

    /// <summary>Carrega o catálogo. Retorna catálogo vazio se não existir.</summary>
    function Carregar(const ACaminho: string): TCatalogoVicios;

    /// <summary>Salva o catálogo, incrementando Versao.</summary>
    procedure Salvar(const ACatalogo: TCatalogoVicios;
      const ACaminho: string);

    /// <summary>
    ///   Cria o catálogo semente na primeira execução, se ainda
    ///   não existir. Contém as 10 categorias iniciais.
    /// </summary>
    procedure GarantirSemente(const ACaminho: string);

    /// <summary>True se já existe Vicios.JSON no caminho.</summary>
    function Existe(const ACaminho: string): Boolean;
  end;

implementation

end.