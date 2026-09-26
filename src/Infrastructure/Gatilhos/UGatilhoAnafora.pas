unit UGatilhoAnafora;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  UIGatilhoLocal,
  UManuscrito,
  UNormalizadorTexto,
  UServicosDominio,
  UValores;

type
  TDeteccaoAnafora = record
    Disparou: Boolean;
    Inicio: Integer;
    Fim: Integer;
    Contagem: Integer;
    Prefixo: string;
    Confianca: Double;
  end;

  TGatilhoAnafora = class(TInterfacedObject, IGatilhoLocal)
  private
    function ExtrairPrefixo(const AFrase: string;
      const APalavras: Integer): string;
    function DetectarEstrito(
      const APrefixos: TArray<string>): TDeteccaoAnafora;
    function DetectarTolerante(
      const APrefixos: TArray<string>): TDeteccaoAnafora;
    function Vencedor(const A, B: TDeteccaoAnafora): TDeteccaoAnafora;
    function MontarResultado(const ADeteccao: TDeteccaoAnafora;
      const AFrases, APrefixos: TArray<string>): TGatilhoResultado;
  public
    function VicioID: string;
    function PrecisaContexto: Boolean;
    function Avaliar(const AParagrafo: TParagrafo;
      const AContexto: TContextoGlobal): TGatilhoResultado;
  end;

implementation

const
  VICIO_ANAFORA = 'anafora';
  PALAVRAS_PREFIXO = 2;
  MIN_OCORRENCIAS = 3;
  MAX_FRASES_NEUTRAS = 1;
  MAX_TRECHOS = 5;

function ConfiancaEstrita(const AOcorrencias: Integer): Double;
begin
  if AOcorrencias >= 5 then
    Exit(1.0);
  if AOcorrencias = 4 then
    Exit(0.9);
  Result := 0.8;
end;

function ConfiancaTolerante(const AOcorrencias: Integer): Double;
begin
  if AOcorrencias >= 4 then
    Exit(0.7);
  Result := 0.5;
end;

function DeteccaoVazia: TDeteccaoAnafora;
begin
  Result.Disparou := False;
  Result.Inicio := -1;
  Result.Fim := -1;
  Result.Contagem := 0;
  Result.Prefixo := '';
  Result.Confianca := 0.0;
end;

{ TGatilhoAnafora }

function TGatilhoAnafora.VicioID: string;
begin
  Result := VICIO_ANAFORA;
end;

function TGatilhoAnafora.PrecisaContexto: Boolean;
begin
  Result := False;
end;

function TGatilhoAnafora.ExtrairPrefixo(const AFrase: string;
  const APalavras: Integer): string;
begin
  Result := TNormalizadorTexto.PrimeirasPalavras(AFrase, APalavras);
end;

function TGatilhoAnafora.DetectarEstrito(
  const APrefixos: TArray<string>): TDeteccaoAnafora;
var
  I, J, Contagem: Integer;
  Prefixo: string;
begin
  Result := DeteccaoVazia;

  I := 0;
  while I <= High(APrefixos) do
  begin
    Prefixo := APrefixos[I];
    if Prefixo = '' then
    begin
      Inc(I);
      Continue;
    end;

    // Conta consecutivos iguais a partir de I.
    Contagem := 0;
    J := I;
    while (J <= High(APrefixos)) and (APrefixos[J] = Prefixo) do
    begin
      Inc(Contagem);
      Inc(J);
    end;

    if Contagem > Result.Contagem then
    begin
      Result.Disparou := Contagem >= MIN_OCORRENCIAS;
      Result.Inicio := I;
      Result.Fim := J - 1;
      Result.Contagem := Contagem;
      Result.Prefixo := Prefixo;
      Result.Confianca := ConfiancaEstrita(Contagem);
    end;

    I := J;
  end;
end;

function TGatilhoAnafora.DetectarTolerante(
  const APrefixos: TArray<string>): TDeteccaoAnafora;
var
  I, J, Contagem, Neutras, UltimoMatch: Integer;
  Prefixo: string;
begin
  Result := DeteccaoVazia;

  for I := 0 to High(APrefixos) do
  begin
    Prefixo := APrefixos[I];
    if Prefixo = '' then
      Continue;

    Contagem := 1;
    UltimoMatch := I;
    Neutras := 0;
    J := I + 1;

    while J <= High(APrefixos) do
    begin
      if APrefixos[J] = Prefixo then
      begin
        Inc(Contagem);
        UltimoMatch := J;
        Neutras := 0;
      end
      else if APrefixos[J] <> '' then
      begin
        Inc(Neutras);
        if Neutras > MAX_FRASES_NEUTRAS then
          Break;
      end;
      Inc(J);
    end;

    if Contagem > Result.Contagem then
    begin
      Result.Disparou := Contagem >= MIN_OCORRENCIAS;
      Result.Inicio := I;
      Result.Fim := UltimoMatch;
      Result.Contagem := Contagem;
      Result.Prefixo := Prefixo;
      Result.Confianca := ConfiancaTolerante(Contagem);
    end;
  end;
end;

function TGatilhoAnafora.Vencedor(const A, B: TDeteccaoAnafora): TDeteccaoAnafora;
begin
  if A.Disparou and (A.Confianca >= B.Confianca) then
    Result := A
  else if B.Disparou then
    Result := B
  else
    Result := A;
end;

function TGatilhoAnafora.MontarResultado(const ADeteccao: TDeteccaoAnafora;
  const AFrases, APrefixos: TArray<string>): TGatilhoResultado;
var
  Trechos: TList<string>;
  I, Mostrados: Integer;
begin
  Result.VicioID := VICIO_ANAFORA;
  Result.Disparou := ADeteccao.Disparou;
  Result.Confianca := ADeteccao.Confianca;
  Result.Trechos := nil;

  if not ADeteccao.Disparou then
    Exit;

  Trechos := TList<string>.Create;
  try
    Trechos.Add('padrão: ' + ADeteccao.Prefixo);

    Mostrados := 0;
    for I := ADeteccao.Inicio to ADeteccao.Fim do
    begin
      if (I >= 0) and (I <= High(APrefixos)) and
         (APrefixos[I] = ADeteccao.Prefixo) then
      begin
        Trechos.Add(AFrases[I]);
        Inc(Mostrados);
        if Mostrados >= MAX_TRECHOS then
        begin
          if ADeteccao.Fim > I then
            Trechos.Add('(e mais ocorrências...)');
          Break;
        end;
      end;
    end;

    Result.Trechos := Trechos.ToArray;
  finally
    Trechos.Free;
  end;
end;

function TGatilhoAnafora.Avaliar(const AParagrafo: TParagrafo;
  const AContexto: TContextoGlobal): TGatilhoResultado;
var
  Frases: TArray<string>;
  Prefixos: TArray<string>;
  I: Integer;
  R1, R2, V: TDeteccaoAnafora;
begin
  Result.VicioID := VICIO_ANAFORA;
  Result.Disparou := False;
  Result.Confianca := 0.0;
  Result.Trechos := nil;

  if (AParagrafo = nil) or (AParagrafo.Texto.Trim = '') then
    Exit;

  Frases := TCompressorPayload.SegmentarEmFrases(AParagrafo.Texto);
  if Length(Frases) < MIN_OCORRENCIAS then
    Exit;

  SetLength(Prefixos, Length(Frases));
  for I := 0 to High(Frases) do
    Prefixos[I] := ExtrairPrefixo(Frases[I].Trim, PALAVRAS_PREFIXO);

  R1 := DetectarEstrito(Prefixos);
  R2 := DetectarTolerante(Prefixos);
  V := Vencedor(R1, R2);

  if not V.Disparou then
    Exit;

  Result := MontarResultado(V, Frases, Prefixos);
end;

end.
