unit sSwapMath;

{
  sSwapMath - Versao Turbo Pascal (16-bit).
  ADN Super-Saiyajin em modo Real.
}

interface

procedure SwapSum(sFileA, sFileB, sFileRes: String);
procedure SwapSub(sFileA, sFileB, sFileRes: String);
procedure SwapMultiply(sFileA, sFileB, sFileRes: String);
procedure SwapDivide(sFileA, sFileB, sFileRes: String);

type
  TProgressCallback = procedure(iPos, iTotal: LongInt);

var
  cDecimalSeparator: Char;
  OnProgress: TProgressCallback;

implementation

function GetFileSize(var F: File): LongInt;
begin
  GetFileSize := FileSize(F);
end;

procedure ReverseFile(sSource, sDest: String);
var
  fIn, fOut: File;
  i: LongInt;
  c: Char;
begin
  Assign(fIn, sSource); Reset(fIn, 1);
  Assign(fOut, sDest); Rewrite(fOut, 1);
  for i := FileSize(fIn) - 1 downto 0 do
  begin
    Seek(fIn, i); BlockRead(fIn, c, 1);
    BlockWrite(fOut, c, 1);
  end;
  Close(fIn); Close(fOut);
end;

procedure CreateNormalizedFile(sIn, sOut: String; iTargetInt, iTargetDec: LongInt);
var
  fIn, fOut: File;
  c: Char;
  i, decPos, currInt, currDec: LongInt;
begin
  Assign(fIn, sIn); Reset(fIn, 1);
  decPos := -1;
  for i := 0 to FileSize(fIn) - 1 do
  begin
    Seek(fIn, i); BlockRead(fIn, c, 1);
    if c = cDecimalSeparator then begin decPos := i; Break; end;
  end;
  if decPos = -1 then begin currInt := FileSize(fIn); currDec := 0; end
  else begin currInt := decPos; currDec := FileSize(fIn) - decPos - 1; end;
  Assign(fOut, sOut); Rewrite(fOut, 1);
  c := '0';
  for i := 1 to iTargetInt - currInt do BlockWrite(fOut, c, 1);
  for i := 0 to currInt - 1 do begin Seek(fIn, i); BlockRead(fIn, c, 1); BlockWrite(fOut, c, 1); end;
  c := cDecimalSeparator; BlockWrite(fOut, c, 1);
  for i := 0 to currDec - 1 do begin Seek(fIn, decPos + 1 + i); BlockRead(fIn, c, 1); BlockWrite(fOut, c, 1); end;
  c := '0';
  for i := 1 to iTargetDec - currDec do BlockWrite(fOut, c, 1);
  Close(fIn); Close(fOut);
end;

procedure SwapSum(sFileA, sFileB, sFileRes: String);
var
  fA, fB, fRes: File;
  iPos, iTotal: LongInt;
  cA, cB, cR: Char;
  iSum, iCarry: Integer;
begin
  Assign(fA, sFileA); Reset(fA, 1); Assign(fB, sFileB); Reset(fB, 1);
  Assign(fRes, sFileRes + '.t'); Rewrite(fRes, 1);
  iCarry := 0; iTotal := FileSize(fA);
  for iPos := iTotal - 1 downto 0 do begin
    Seek(fA, iPos); BlockRead(fA, cA, 1); Seek(fB, iPos); BlockRead(fB, cB, 1);
    if cA = cDecimalSeparator then begin cR := cDecimalSeparator; BlockWrite(fRes, cR, 1); end
    else begin
      iSum := (Ord(cA) - 48) + (Ord(cB) - 48) + iCarry;
      iCarry := iSum div 10; cR := Char((iSum mod 10) + 48); BlockWrite(fRes, cR, 1);
    end;
  end;
  if iCarry > 0 then begin cR := Char(iCarry + 48); BlockWrite(fRes, cR, 1); end;
  Close(fA); Close(fB); Close(fRes);
  ReverseFile(sFileRes + '.t', sFileRes);
  Assign(fRes, sFileRes + '.t'); Erase(fRes);
end;

procedure SwapSub(sFileA, sFileB, sFileRes: String);
var
  fA, fB, fRes: File;
  iPos, iTotal: LongInt;
  cA, cB, cR: Char;
  iSub, iBorrow: Integer;
begin
  Assign(fA, sFileA); Reset(fA, 1); Assign(fB, sFileB); Reset(fB, 1);
  Assign(fRes, sFileRes + '.t'); Rewrite(fRes, 1);
  iBorrow := 0; iTotal := FileSize(fA);
  for iPos := iTotal - 1 downto 0 do begin
    Seek(fA, iPos); BlockRead(fA, cA, 1); Seek(fB, iPos); BlockRead(fB, cB, 1);
    if cA = cDecimalSeparator then begin cR := cDecimalSeparator; BlockWrite(fRes, cR, 1); end
    else begin
      iSub := (Ord(cA) - 48) - (Ord(cB) - 48) - iBorrow;
      if iSub < 0 then begin iSub := iSub + 10; iBorrow := 1; end else iBorrow := 0;
      cR := Char(iSub + 48); BlockWrite(fRes, cR, 1);
    end;
  end;
  Close(fA); Close(fB); Close(fRes);
  ReverseFile(sFileRes + '.t', sFileRes);
  Assign(fRes, sFileRes + '.t'); Erase(fRes);
end;

procedure SwapMultiplyDigit(sFileIn, sFileRes: String; iDigit: Integer; iShift: LongInt);
var
  fIn, fRes: File;
  i: LongInt;
  cA, cR: Char;
  iProd, iCarry: Integer;
begin
  Assign(fIn, sFileIn); Reset(fIn, 1); Assign(fRes, sFileRes + '.t'); Rewrite(fRes, 1);
  iCarry := 0;
  for i := 1 to iShift do begin cR := '0'; BlockWrite(fRes, cR, 1); end;
  for i := FileSize(fIn) - 1 downto 0 do begin
    Seek(fIn, i); BlockRead(fIn, cA, 1);
    if cA = cDecimalSeparator then Continue;
    iProd := (Ord(cA) - 48) * iDigit + iCarry;
    iCarry := iProd div 10; cR := Char((iProd mod 10) + 48); BlockWrite(fRes, cR, 1);
  end;
  if iCarry > 0 then begin cR := Char(iCarry + 48); BlockWrite(fRes, cR, 1); end;
  Close(fIn); Close(fRes);
  ReverseFile(sFileRes + '.t', sFileRes);
  Assign(fRes, sFileRes + '.t'); Erase(fRes);
end;

procedure SwapMultiply(sFileA, sFileB, sFileRes: String);
var
  fB, fAcc: File;
  i: LongInt; iShift: LongInt; cDigit: Char;
  sAcc, sDig, sNew: String;
begin
  sAcc := sFileRes + '.acc'; Assign(fAcc, sAcc); Rewrite(fAcc, 1);
  cDigit := '0'; BlockWrite(fAcc, cDigit, 1); Close(fAcc);
  Assign(fB, sFileB); Reset(fB, 1); iShift := 0;
  for i := FileSize(fB) - 1 downto 0 do begin
    Seek(fB, i); BlockRead(fB, cDigit, 1);
    if cDigit = cDecimalSeparator then Continue;
    if cDigit <> '0' then begin
      sDig := sFileRes + '.d'; sNew := sFileRes + '.n';
      SwapMultiplyDigit(sFileA, sDig, Ord(cDigit) - 48, iShift);
      SwapSum(sAcc, sDig, sNew);
      Assign(fAcc, sAcc); Erase(fAcc); Assign(fAcc, sNew); Rename(fAcc, sAcc);
      Assign(fAcc, sDig); Erase(fAcc);
    end;
    Inc(iShift);
  end;
  Close(fB); Assign(fAcc, sAcc); Rename(fAcc, sFileRes);
end;

function SwapCompare(sFileA, sFileB: String): Integer;
var
  fA, fB: File; cA, cB: Char; i: LongInt; res: Integer;
begin
  Assign(fA, sFileA); Reset(fA, 1); Assign(fB, sFileB); Reset(fB, 1);
  if FileSize(fA) > FileSize(fB) then res := 1
  else if FileSize(fA) < FileSize(fB) then res := -1
  else begin
    res := 0;
    for i := 0 to FileSize(fA) - 1 do begin
      Seek(fA, i); BlockRead(fA, cA, 1); Seek(fB, i); BlockRead(fB, cB, 1);
      if cA > cB then begin res := 1; Break; end;
      if cA < cB then begin res := -1; Break; end;
    end;
  end;
  Close(fA); Close(fB); SwapCompare := res;
end;

procedure SwapDivide(sFileA, sFileB, sFileRes: String);
var
  fA, fQ, fC, fT: File; i, count: Integer; cA: Char;
  sQ, sC, sT, sS: String; j: LongInt;
begin
  sQ := sFileRes + '.q'; sC := sFileRes + '.c'; sT := sFileRes + '.tmp';
  Assign(fC, sC); Rewrite(fC, 1); cA := '0'; BlockWrite(fC, cA, 1); Close(fC);
  Assign(fQ, sQ); Rewrite(fQ, 1); Close(fQ);
  Assign(fA, sFileA); Reset(fA, 1);
  for j := 0 to FileSize(fA) - 1 do begin
    Seek(fA, j); BlockRead(fA, cA, 1);
    if cA = cDecimalSeparator then Continue;
    Assign(fC, sC); Reset(fC, 1); Assign(fT, sT); Rewrite(fT, 1);
    if FileSize(fC) = 1 then begin
      BlockRead(fC, cA, 1);
      if cA <> '0' then BlockWrite(fT, cA, 1);
    end else begin
      for i := 0 to FileSize(fC) - 1 do begin Seek(fC, i); BlockRead(fC, cA, 1); BlockWrite(fT, cA, 1); end;
    end;
    Seek(fA, j); BlockRead(fA, cA, 1); BlockWrite(fT, cA, 1);
    Close(fC); Close(fT); Assign(fC, sC); Erase(fC); Assign(fC, sT); Rename(fC, sC);
    count := 0;
    while SwapCompare(sC, sFileB) >= 0 do begin
      sS := sFileRes + '.s'; SwapSub(sC, sFileB, sS);
      Assign(fC, sC); Erase(fC); Assign(fC, sS); Rename(fC, sC); Inc(count);
    end;
    Assign(fQ, sQ); Reset(fQ, 1); Seek(fQ, FileSize(fQ));
    cA := Char(count + 48); BlockWrite(fQ, cA, 1); Close(fQ);
  end;
  Close(fA); Assign(fQ, sQ); Rename(fQ, sFileRes); Assign(fC, sC); Erase(fC);
end;

begin
  cDecimalSeparator := '.';
end.
