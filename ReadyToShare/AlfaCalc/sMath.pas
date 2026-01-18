unit sMath;

{
  sMath - DNA Nivel Decimal.
  Suporte a precisao infinita via Strings.
  JTR Software - "O complicado e parecer simples"
}

interface

uses SysUtils;

function Sum(sA, sB: string): string;
function Sub(sA, sB: string): string;
function Multiply(sA, sB: string): string;
function Divide(sA, sB: string): string;
function CleanNumber(sV: string): string;

const
  cDecimalSeparator: char = '.';

implementation

function IsNegative(sV: string): boolean;
begin
  IsNegative := (Length(sV) > 0) and (sV[1] = '-');
end;

function GetAbs(sV: string): string;
begin
  if IsNegative(sV) then GetAbs := Copy(sV, 2, MaxInt)
  else GetAbs := sV;
end;

function CleanNumber(sV: string): string;
var
  neg: boolean;
  val: string;
begin
  neg := IsNegative(sV);
  val := GetAbs(sV);
  while (Length(val) > 1) and (val[1] = '0') and (val[2] <> cDecimalSeparator) do 
    Delete(val, 1, 1);
  
  if Pos(cDecimalSeparator, val) > 0 then
  begin
    while (Length(val) > 1) and (val[Length(val)] = '0') and (val[Length(val)-1] <> cDecimalSeparator) do 
      Delete(val, Length(val), 1);
    if val[Length(val)] = cDecimalSeparator then Delete(val, Length(val), 1);
  end;
  
  if (val = '') then val := '0';
  if neg and (val <> '0') then CleanNumber := '-' + val
  else CleanNumber := val;
end;

procedure AlignDecimals(var sA, sB: string);
var 
  iPosA, iPosB, iDecA, iDecB: integer;
  i: integer;
begin
  iPosA := 0; for i := 1 to Length(sA) do if sA[i] = cDecimalSeparator then iPosA := i;
  iPosB := 0; for i := 1 to Length(sB) do if sB[i] = cDecimalSeparator then iPosB := i;
  
  if iPosA = 0 then iDecA := 0 else iDecA := Length(sA) - iPosA;
  if iPosB = 0 then iDecB := 0 else iDecB := Length(sB) - iPosB;

  while iDecA < iDecB do begin
    if iPosA = 0 then begin sA := sA + cDecimalSeparator; iPosA := Length(sA); end;
    sA := sA + '0'; Inc(iDecA);
  end;
  while iDecB < iDecA do begin
    if iPosB = 0 then begin sB := sB + cDecimalSeparator; iPosB := Length(sB); end;
    sB := sB + '0'; Inc(iDecB);
  end;

  if iPosA = 0 then iPosA := Length(sA) + 1;
  if iPosB = 0 then iPosB := Length(sB) + 1;

  while iPosA < iPosB do begin sA := '0' + sA; Inc(iPosA); end;
  while iPosB < iPosA do begin sB := '0' + sB; Inc(iPosB); end;
end;

function InternalSum(sA, sB: string): string;
var 
  i: integer; iSum, iCarry: integer; sRes: string;
begin
  AlignDecimals(sA, sB);
  sRes := ''; iCarry := 0;
  for i := Length(sA) downto 1 do begin
    if sA[i] = cDecimalSeparator then sRes := cDecimalSeparator + sRes
    else begin
      iSum := (Ord(sA[i]) - 48) + (Ord(sB[i]) - 48) + iCarry;
      iCarry := iSum div 10;
      sRes := char((iSum mod 10) + 48) + sRes;
    end;
  end;
  if iCarry > 0 then sRes := IntToStr(iCarry) + sRes;
  InternalSum := sRes;
end;

function InternalSub(sA, sB: string): string;
var 
  i: integer; iSub, iBorrow: integer; sRes, sTemp: string; bNeg: boolean;
begin
  AlignDecimals(sA, sB);
  bNeg := sA < sB;
  if bNeg then begin sTemp := sA; sA := sB; sB := sTemp; end;
  sRes := ''; iBorrow := 0;
  for i := Length(sA) downto 1 do begin
    if sA[i] = cDecimalSeparator then sRes := cDecimalSeparator + sRes
    else begin
      iSub := (Ord(sA[i]) - 48) - (Ord(sB[i]) - 48) - iBorrow;
      if iSub < 0 then begin iSub := iSub + 10; iBorrow := 1; end else iBorrow := 0;
      sRes := char(iSub + 48) + sRes;
    end;
  end;
  if bNeg then sRes := '-' + sRes;
  InternalSub := sRes;
end;

function Sum(sA, sB: string): string;
begin
  if IsNegative(sA) and IsNegative(sB) then Sum := '-' + InternalSum(GetAbs(sA), GetAbs(sB))
  else if IsNegative(sA) then Sum := Sub(sB, GetAbs(sA))
  else if IsNegative(sB) then Sum := Sub(sA, GetAbs(sB))
  else Sum := CleanNumber(InternalSum(sA, sB));
end;

function Sub(sA, sB: string): string;
begin
  if IsNegative(sB) then Sub := Sum(sA, GetAbs(sB))
  else if IsNegative(sA) then Sub := '-' + InternalSum(GetAbs(sA), sB)
  else Sub := CleanNumber(InternalSub(sA, sB));
end;

function Multiply(sA, sB: string): string;
var
  i, j: integer;
  iPos: integer;
  iDecA, iDecB, iTotalDecs: integer;
  sIntA, sIntB, sRes, sFinal: string;
  iDigitA, iDigitB, iProd, iCarry: integer;
  resNeg: boolean;
begin
  resNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA); sB := GetAbs(sB);
  
  iPos := Pos(cDecimalSeparator, sA);
  if iPos > 0 then iDecA := Length(sA) - iPos else iDecA := 0;
  sIntA := StringReplace(sA, cDecimalSeparator, '', [rfReplaceAll]);
  
  iPos := Pos(cDecimalSeparator, sB);
  if iPos > 0 then iDecB := Length(sB) - iPos else iDecB := 0;
  sIntB := StringReplace(sB, cDecimalSeparator, '', [rfReplaceAll]);
  
  iTotalDecs := iDecA + iDecB;
  sFinal := '0';
  
  for i := Length(sIntB) downto 1 do begin
    iDigitB := Ord(sIntB[i]) - 48;
    if iDigitB = 0 then Continue;
    sRes := ''; iCarry := 0;
    for j := Length(sIntA) downto 1 do begin
      iDigitA := Ord(sIntA[j]) - 48;
      iProd := (iDigitA * iDigitB) + iCarry;
      iCarry := iProd div 10;
      sRes := char((iProd mod 10) + 48) + sRes;
    end;
    if iCarry > 0 then sRes := IntToStr(iCarry) + sRes;
    for j := 1 to (Length(sIntB) - i) do sRes := sRes + '0';
    sFinal := Sum(sFinal, sRes);
  end;
  
  if iTotalDecs > 0 then begin
    while Length(sFinal) <= iTotalDecs do sFinal := '0' + sFinal;
    Insert(cDecimalSeparator, sFinal, Length(sFinal) - iTotalDecs + 1);
  end;
  if resNeg and (sFinal <> '0') then Multiply := '-' + CleanNumber(sFinal)
  else Multiply := CleanNumber(sFinal);
end;

function Divide(sA, sB: string): string;
var
  sQuot, sCurr, sTempA, sTempB: string;
  iCount, iPrec, i: integer;
  bHasDec, resNeg: boolean;
begin
  if CleanNumber(sB) = '0' then begin Divide := '0'; Exit; end;
  resNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA); sB := GetAbs(sB);
  
  sQuot := ''; sCurr := '0'; iPrec := 0; bHasDec := False;
  sTempA := sA; sTempB := sB;
  AlignDecimals(sTempA, sTempB);
  sA := StringReplace(sTempA, cDecimalSeparator, '', [rfReplaceAll]);
  sB := StringReplace(sTempB, cDecimalSeparator, '', [rfReplaceAll]);
  sA := CleanNumber(sA); sB := CleanNumber(sB);

  sCurr := '0';
  for i := 1 to Length(sA) + 10 do begin
    if i <= Length(sA) then sCurr := sCurr + sA[i]
    else begin
      if not bHasDec then begin 
        if sQuot = '' then sQuot := '0';
        sQuot := sQuot + cDecimalSeparator; 
        bHasDec := True; 
      end;
      sCurr := sCurr + '0'; Inc(iPrec);
    end;
    sCurr := CleanNumber(sCurr);
    iCount := 0;
    while (Length(sCurr) > Length(sB)) or ((Length(sCurr) = Length(sB)) and (sCurr >= sB)) do begin
      sCurr := Sub(sCurr, sB);
      Inc(iCount);
    end;
    if (sQuot <> '') or (iCount > 0) or (i = Length(sA)) then
      sQuot := sQuot + char(iCount + 48);
    if (i >= Length(sA)) and (sCurr = '0') then Break;
    if iPrec >= 10 then Break;
  end;
  if resNeg and (sQuot <> '0') then Divide := '-' + CleanNumber(sQuot)
  else Divide := CleanNumber(sQuot);
end;

end.
