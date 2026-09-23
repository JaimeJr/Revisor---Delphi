unit UIEnvioRepository;

{
  UIEnvioRepository.pas
  ─────────────────────────────────────────────────────────────
  Log append-only das chamadas à IA. Cada Append gera uma
  entrada imutável em chamadas[].

  O caminho do arquivo é passado em cada método — consistente
  com IAntesRepository e INovoRepository. O repositório é
  stateless: instanciado uma vez, usado com qualquer arquivo.
  ─────────────────────────────────────────────────────────────
}

interface

uses
  UChamada;

type
  IEnvioRepository = interface
  ['{8A37630A-5B5E-4E4A-B588-21673C5B1297}']
    /// <summary>
    ///   Anexa uma chamada ao log. Atribui IDChamada se ainda
    ///   não tiver, seguindo o padrão "req-NNNN", com base no
    ///   maior ID já existente no arquivo.
    /// </summary>
    procedure Append(const AChamada: TChamada; const ACaminho: string);

    /// <summary>
    ///   Busca uma chamada pelo IDChamada. Retorna nil se não
    ///   existir.
    /// </summary>
    function Buscar(const AIDChamada, ACaminho: string): TChamada;

    /// <summary>
    ///   True se já existe uma chamada com o mesmo hash de
    ///   payload. Consulta rápida para cache.
    /// </summary>
    function ExisteComHash(const AHashPayload,
      ACaminho: string): Boolean;

    /// <summary>
    ///   Busca a chamada mais recente com esse hash. Retorna nil
    ///   se nenhuma. Usado para reaproveitar cache.
    /// </summary>
    function BuscarPorHash(const AHashPayload,
      ACaminho: string): TChamada;

    /// <summary>Total de chamadas registradas no arquivo.</summary>
    function TotalChamadas(const ACaminho: string): Integer;
  end;

implementation

end.
