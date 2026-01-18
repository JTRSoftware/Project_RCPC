unit sSwapMath;

{
  sSwapMath - DNA Nivel Decimal em Disco.
  Processamento de grandes volumes de dados.
  JTR Software - "O complicado e parecer simples"
}

interface

uses SysUtils, Classes;

procedure SwapSum(sFileA, sFileB, sFileRes: string);
procedure SwapSub(sFileA, sFileB, sFileRes: string);

const
  cDecimalSeparator: char = '.';

implementation

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

procedure SwapSum(sFileA, sFileB, sFileRes: string);
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
        iSum := (Ord(cA) - 48) + (Ord(cB) - 48) + iCarry;
        iCarry := iSum div 10;
        cR := Char((iSum mod 10) + 48);
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

procedure SwapSub(sFileA, sFileB, sFileRes: string);
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
        iSub := (Ord(cA) - 48) - (Ord(cB) - 48) - iBorrow;
        if iSub < 0 then begin iSub := iSub + 10; iBorrow := 1; end else iBorrow := 0;
        cR := Char(iSub + 48);
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

end.
