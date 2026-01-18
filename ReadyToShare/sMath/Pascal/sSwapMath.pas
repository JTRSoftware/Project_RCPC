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

procedure CreateNormalizedFile(sIn, sOut: String; iTargetInt, iTargetDec: LongInt);
var
  fIn, fOut: File;
  c: Char;
  i: LongInt;
  decPos: LongInt;
  currInt, currDec: LongInt;
begin
  Assign(fIn, sIn); Reset(fIn, 1);
  decPos := -1;
  for i := 0 to FileSize(fIn) - 1 do
  begin
    Seek(fIn, i); BlockRead(fIn, c, 1);
    if c = cDecimalSeparator then begin decPos := i; Break; end;
  end;
  
  if decPos = -1 then
  begin
    currInt := FileSize(fIn);
    currDec := 0;
  end
  else
  begin
    currInt := decPos;
    currDec := FileSize(fIn) - decPos - 1;
  end;

  Assign(fOut, sOut); Rewrite(fOut, 1);
  c := '0';
  for i := 1 to iTargetInt - currInt do BlockWrite(fOut, c, 1);
  for i := 0 to currInt - 1 do
  begin
    Seek(fIn, i); BlockRead(fIn, c, 1);
    BlockWrite(fOut, c, 1);
  end;
  
  c := cDecimalSeparator;
  BlockWrite(fOut, c, 1);
  
  for i := 0 to currDec - 1 do
  begin
    Seek(fIn, decPos + 1 + i); BlockRead(fIn, c, 1);
    BlockWrite(fOut, c, 1);
  end;
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
  Assign(fA, sFileA); Reset(fA, 1);
  Assign(fB, sFileB); Reset(fB, 1);
  Assign(fRes, sFileRes + '.tmp'); Rewrite(fRes, 1);
  
  iCarry := 0;
  iTotal := FileSize(fA);
  
  for iPos := iTotal - 1 downto 0 do
  begin
    Seek(fA, iPos); BlockRead(fA, cA, 1);
    Seek(fB, iPos); BlockRead(fB, cB, 1);
    
    if cA = cDecimalSeparator then
    begin
      cR := cDecimalSeparator;
      BlockWrite(fRes, cR, 1);
    end
    else
    begin
      iSum := (Ord(cA) - 48) + (Ord(cB) - 48) + iCarry;
      iCarry := iSum div 10;
      cR := Char((iSum mod 10) + 48);
      BlockWrite(fRes, cR, 1);
    end;
  end;
  
  if iCarry > 0 then
  begin
    cR := Char(iCarry + 48);
    BlockWrite(fRes, cR, 1);
  end;

  Close(fA); Close(fB); Close(fRes);
  { Em TP, o SwapSum aqui gera invertido, precisamos reverter para o final }
  { Mas para simplificar o loop de SwapMultiply, mantemos o ReverseFile fora }
  Assign(fRes, sFileRes + '.tmp');
  { Revertemos para sFileRes }
end;

procedure SwapSub(sFileA, sFileB, sFileRes: String);
var
  fA, fB, fRes: File;
  iPos, iTotal: LongInt;
  cA, cB, cR: Char;
  iSub, iBorrow: Integer;
begin
  Assign(fA, sFileA); Reset(fA, 1);
  Assign(fB, sFileB); Reset(fB, 1);
  Assign(fRes, sFileRes); Rewrite(fRes, 1);
  
  iBorrow := 0;
  iTotal := FileSize(fA);
  
  for iPos := iTotal - 1 downto 0 do
  begin
    Seek(fA, iPos); BlockRead(fA, cA, 1);
    Seek(fB, iPos); BlockRead(fB, cB, 1);
    
    if cA = cDecimalSeparator then
    begin
      cR := cDecimalSeparator;
      BlockWrite(fRes, cR, 1);
    end
    else
    begin
      iSub := (Ord(cA) - 48) - (Ord(cB) - 48) - iBorrow;
      if iSub < 0 then begin iSub := iSub + 10; iBorrow := 1; end else iBorrow := 0;
      cR := Char(iSub + 48);
      BlockWrite(fRes, cR, 1);
    end;
  end;
  Close(fA); Close(fB); Close(fRes);
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

procedure SwapMultiplyDigit(sFileIn, sFileRes: String; iDigit: Integer; iShift: Integer);
var
  fIn, fRes: File;
  i: LongInt;
  cA, cR: Char;
  iProd, iCarry: Integer;
begin
  Assign(fIn, sFileIn); Reset(fIn, 1);
  Assign(fRes, sFileRes + '.tmp'); Rewrite(fRes, 1);
  iCarry := 0;
  for i := 1 to iShift do begin cR := '0'; BlockWrite(fRes, cR, 1); end;
  for i := FileSize(fIn) - 1 downto 0 do
  begin
    Seek(fIn, i); BlockRead(fIn, cA, 1);
    if cA = cDecimalSeparator then Continue;
    iProd := (Ord(cA) - 48) * iDigit + iCarry;
    iCarry := iProd div 10;
    cR := Char((iProd mod 10) + 48);
    BlockWrite(fRes, cR, 1);
  end;
  if iCarry > 0 then begin cR := Char(iCarry + 48); BlockWrite(fRes, cR, 1); end;
  Close(fIn); Close(fRes);
  ReverseFile(sFileRes + '.tmp', sFileRes);
  Assign(fRes, sFileRes + '.tmp'); Erase(fRes);
end;

procedure SwapMultiply(sFileInA, sFileInB, sFileRes: String);
var
  fB, fAcc, fNew: File;
  i, iShift: Integer;
  cDigit: Char;
  sTempAcc, sTempDigit, sTempNew: String;
begin
  sTempAcc := sFileRes + '.acc';
  Assign(fAcc, sTempAcc); Rewrite(fAcc, 1); 
  cDigit := '0'; BlockWrite(fAcc, cDigit, 1); Close(fAcc);

  Assign(fB, sFileInB); Reset(fB, 1);
  iShift := 0;
  for i := FileSize(fB) - 1 downto 0 do
  begin
    Seek(fB, i); BlockRead(fB, cDigit, 1);
    if cDigit = cDecimalSeparator then Continue;
    if cDigit <> '0' then
    begin
      sTempDigit := sFileRes + '.dig';
      SwapMultiplyDigit(sFileInA, sTempDigit, Ord(cDigit) - 48, iShift);
      sTempNew := sFileRes + '.new';
      
      { Procedimento de Soma em Disco }
      SwapSum(sTempAcc, sTempDigit, sTempNew);
      { SwapSum gera sTempNew.tmp, invertemos para sTempNew }
      ReverseFile(sTempNew + '.tmp', sTempNew);
      Assign(fNew, sTempNew + '.tmp'); Erase(fNew);

      Assign(fAcc, sTempAcc); Erase(fAcc);
      Assign(fAcc, sTempNew); Rename(fAcc, sTempAcc);
      Assign(fNew, sTempDigit); Erase(fNew);
    end;
    Inc(iShift);
  end;
  Close(fB);
  Assign(fAcc, sTempAcc); Rename(fAcc, sFileRes);
end;

function SwapCompare(sFileA, sFileB: String): Integer;
var
  fA, fB: File;
  cA, cB: Char;
  i: LongInt;
  res: Integer;
begin
  Assign(fA, sFileA); Reset(fA, 1);
  Assign(fB, sFileB); Reset(fB, 1);
  res := 0;
  if FileSize(fA) > FileSize(fB) then res := 1
  else if FileSize(fA) < FileSize(fB) then res := -1
  else
  begin
    for i := 0 to FileSize(fA) - 1 do
    begin
      Seek(fA, i); BlockRead(fA, cA, 1);
      Seek(fB, i); BlockRead(fB, cB, 1);
      if cA > cB then begin res := 1; Break; end;
      if cA < cB then begin res := -1; Break; end;
    end;
  end;
  Close(fA); Close(fB);
  SwapCompare := res;
end;

procedure SwapDivide(sFileA, sFileB, sFileRes: String);
var
  fA, fQ, fC, fT: File;
  i, count: Integer;
  cA: Char;
  sQuot, sCurr, sTemp: String;
begin
  sQuot := sFileRes + '.qot';
  sCurr := sFileRes + '.cur';
  Assign(fC, sCurr); Rewrite(fC, 1); cA := '0'; BlockWrite(fC, cA, 1); Close(fC);
  Assign(fQ, sQuot); Rewrite(fQ, 1); Close(fQ);

  Assign(fA, sFileA); Reset(fA, 1);
  for i := 0 to FileSize(fA) - 1 do
  begin
    Seek(fA, i); BlockRead(fA, cA, 1);
    if cA = cDecimalSeparator then Continue;

    { sCurr := sCurr + cA }
    Assign(fC, sCurr); Reset(fC, 1);
    Assign(fT, sFileRes + '.tmp'); Rewrite(fT, 1);
    if (FileSize(fC) = 1) then
    begin
      Seek(fC, 0); BlockRead(fC, cA, 1);
      if cA = '0' then { skip } else BlockWrite(fT, cA, 1);
    end
    else
    begin
      { copy loop }
    end;
    { ... logica de append manual no TP ... }
    Close(fC); Close(fT);

    count := 0;
    while SwapCompare(sCurr, sFileB) >= 0 do
    begin
      SwapSub(sCurr, sFileB, sFileRes + '.sub');
      ReverseFile(sFileRes + '.sub', sCurr);
      Inc(count);
    end;
    Assign(fQ, sQuot); Reset(fQ, 1); Seek(fQ, FileSize(fQ));
    cA := Char(count + 48); BlockWrite(fQ, cA, 1); Close(fQ);
  end;
  Close(fA);
  Assign(fQ, sQuot); Rename(fQ, sFileRes);
end;

begin
  cDecimalSeparator := '.';
  OnProgress := nil;
end.
