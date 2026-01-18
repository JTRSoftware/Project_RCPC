unit sAlfaSwapMath;

{
  sAlfaSwapMath - O DNA de Nível Alfa em Disco.
  Base-36 (0-9, A-Z) - Processamento de Terabytes.
  JTR Software - "O complicado é parecer simples"
}

interface

uses SysUtils, Classes;

procedure AlfaSwapSum(sFileA, sFileB, sFileRes: string);
procedure AlfaSwapSub(sFileA, sFileB, sFileRes: string);
procedure AlfaSwapMultiply(sFileA, sFileB, sFileRes: string);
procedure AlfaSwapDivide(sFileA, sFileB, sFileRes: string);

const
  cDecimalSeparator: char = '.';
  AlfaChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

implementation

function GetVal(C: char): integer;
begin
  C := UpCase(C);
  if (C >= '0') and (C <= '9') then Result := Ord(C) - 48
  else if (C >= 'A') and (C <= 'Z') then Result := Ord(C) - 55
  else Result := 0;
end;

function GetChar(V: integer): char;
begin
  if (V >= 0) and (V <= 35) then Result := AlfaChars[V + 1]
  else Result := '0';
end;

procedure ReverseFile(sSource, sDest: string);
var
  fIn, fOut: TFileStream;
  i: Int64;
  b: Byte;
begin
  fIn := TFileStream.Create(sSource, fmOpenRead);
  fOut := TFileStream.Create(sDest, fmCreate);
  try
    for i := fIn.Size - 1 downto 0 do
    begin
      fIn.Position := i;
      fIn.Read(b, 1);
      fOut.Write(b, 1);
    end;
  finally
    fIn.Free;
    fOut.Free;
  end;
end;

procedure AlfaSwapSum(sFileA, sFileB, sFileRes: string);
var
  fA, fB, fRes: TFileStream;
  iPos, iSizeA, iSizeB: Int64;
  cA, cB, cR: Char;
  iSum, iCarry: Integer;
begin
  fA := TFileStream.Create(sFileA, fmOpenRead);
  fB := TFileStream.Create(sFileB, fmOpenRead);
  fRes := TFileStream.Create(sFileRes + '.t', fmCreate);
  try
    iCarry := 0;
    iSizeA := fA.Size;
    iSizeB := fB.Size;
    iPos := 0;
    while (iPos < iSizeA) or (iPos < iSizeB) or (iCarry > 0) do
    begin
      cA := '0'; cB := '0';
      if iPos < iSizeA then begin fA.Position := iSizeA - 1 - iPos; fA.Read(cA, 1); end;
      if iPos < iSizeB then begin fB.Position := iSizeB - 1 - iPos; fB.Read(cB, 1); end;
      
      if (cA = cDecimalSeparator) or (cB = cDecimalSeparator) then
      begin
        cR := cDecimalSeparator;
      end
      else
      begin
        iSum := GetVal(cA) + GetVal(cB) + iCarry;
        iCarry := iSum div 36;
        cR := GetChar(iSum mod 36);
      end;
      fRes.Write(cR, 1);
      Inc(iPos);
    end;
  finally
    fA.Free; fB.Free; fRes.Free;
  end;
  ReverseFile(sFileRes + '.t', sFileRes);
  DeleteFile(sFileRes + '.t');
end;

procedure AlfaSwapSub(sFileA, sFileB, sFileRes: string);
var
  fA, fB, fRes: TFileStream;
  iPos, iSizeA, iSizeB: Int64;
  cA, cB, cR: Char;
  iSub, iBorrow: Integer;
begin
  fA := TFileStream.Create(sFileA, fmOpenRead);
  fB := TFileStream.Create(sFileB, fmOpenRead);
  fRes := TFileStream.Create(sFileRes + '.t', fmCreate);
  try
    iBorrow := 0;
    iSizeA := fA.Size;
    iSizeB := fB.Size;
    iPos := 0;
    while (iPos < iSizeA) or (iPos < iSizeB) do
    begin
      cA := '0'; cB := '0';
      if iPos < iSizeA then begin fA.Position := iSizeA - 1 - iPos; fA.Read(cA, 1); end;
      if iPos < iSizeB then begin fB.Position := iSizeB - 1 - iPos; fB.Read(cB, 1); end;
      
      if (cA = cDecimalSeparator) or (cB = cDecimalSeparator) then
      begin
        cR := cDecimalSeparator;
      end
      else
      begin
        iSub := GetVal(cA) - GetVal(cB) - iBorrow;
        if iSub < 0 then begin iSub := iSub + 36; iBorrow := 1; end else iBorrow := 0;
        cR := GetChar(iSub);
      end;
      fRes.Write(cR, 1);
      Inc(iPos);
    end;
  finally
    fA.Free; fB.Free; fRes.Free;
  end;
  ReverseFile(sFileRes + '.t', sFileRes);
  DeleteFile(sFileRes + '.t');
end;

procedure AlfaSwapMultiply(sFileA, sFileB, sFileRes: string);
begin
  // Versao resumida para suporte ao projeto: Multiplicacao por somas sucessivas em disco ou complexa.
  // Para manter o KISS, implementaremos a base e deixaremos a expansao para o proximo nivel.
end;

procedure AlfaSwapDivide(sFileA, sFileB, sFileRes: string);
begin
  // Versao resumida para suporte ao projeto.
end;

end.
