unit sHexMath;

{
  sHexMath - O DNA de Nível Hexadecimal.
  Base-16 (0-9, A-F)
  JTR Software - "O complicado é parecer simples"
}

interface

uses SysUtils, Math;

function HexSum(sA, sB: string): string;
function HexSub(sA, sB: string): string;
function HexMultiply(sA, sB: string): string;
function HexDivide(sA, sB: string): string;
function HexClean(sV: string): string;
function HexToDec(sHex: string): string;
function DecToHex(sDec: string): string;

const
  cDecimalSeparator: char = '.';
  HexChars = '0123456789ABCDEF';

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

function GetVal(C: char): integer;
begin
  C := UpCase(C);
  if (C >= '0') and (C <= '9') then Result := Ord(C) - 48
  else if (C >= 'A') and (C <= 'F') then Result := Ord(C) - 55
  else Result := 0;
end;

function GetChar(V: integer): char;
begin
  if (V >= 0) and (V <= 15) then Result := HexChars[V + 1]
  else Result := '0';
end;

function HexClean(sV: string): string;
var
  neg: boolean;
  val: string;
begin
  neg := IsNegative(sV);
  val := GetAbs(sV);
  while (Length(val) > 1) and (val[1] = '0') and (val[2] <> cDecimalSeparator) do Delete(val, 1, 1);
  if (Pos(cDecimalSeparator, val) > 0) then
  begin
    while (Length(val) > 1) and (val[Length(val)] = '0') and (val[Length(val)-1] <> cDecimalSeparator) do
      Delete(val, Length(val), 1);
    if val[Length(val)] = cDecimalSeparator then Delete(val, Length(val), 1);
  end;
  if val = '' then val := '0';
  if neg and (val <> '0') then HexClean := '-' + val
  else HexClean := val;
end;

procedure Align(var sA, sB: string);
var
  pA, pB, dA, dB, i: integer;
begin
  pA := 0; for i := 1 to Length(sA) do if sA[i] = cDecimalSeparator then pA := i;
  pB := 0; for i := 1 to Length(sB) do if sB[i] = cDecimalSeparator then pB := i;
  if pA = 0 then dA := 0 else dA := Length(sA) - pA;
  if pB = 0 then dB := 0 else dB := Length(sB) - pB;
  while dA < dB do begin
    if pA = 0 then begin sA := sA + cDecimalSeparator; pA := Length(sA); end;
    sA := sA + '0'; Inc(dA);
  end;
  while dB < dA do begin
    if pB = 0 then begin sB := sB + cDecimalSeparator; pB := Length(sB); end;
    sB := sB + '0'; Inc(dB);
  end;
  if pA = 0 then pA := Length(sA) + 1;
  if pB = 0 then pB := Length(sB) + 1;
  while pA < pB do begin sA := '0' + sA; Inc(pA); end;
  while pB < pA do begin sB := '0' + sB; Inc(pB); end;
end;

function InternalSum(sA, sB: string): string;
var i, sum, carry: integer; res: string;
begin
  Align(sA, sB);
  res := ''; carry := 0;
  for i := Length(sA) downto 1 do begin
    if sA[i] = cDecimalSeparator then res := cDecimalSeparator + res
    else begin
      sum := GetVal(sA[i]) + GetVal(sB[i]) + carry;
      carry := sum div 16;
      res := GetChar(sum mod 16) + res;
    end;
  end;
  if carry > 0 then res := GetChar(carry) + res;
  InternalSum := res;
end;

function InternalSub(sA, sB: string): string;
var i, diff, borrow: integer; res, t: string; bNeg: boolean;
begin
  Align(sA, sB);
  bNeg := sA < sB;
  if bNeg then begin t := sA; sA := sB; sB := t; end;
  res := ''; borrow := 0;
  for i := Length(sA) downto 1 do begin
    if sA[i] = cDecimalSeparator then res := cDecimalSeparator + res
    else begin
      diff := GetVal(sA[i]) - GetVal(sB[i]) - borrow;
      if diff < 0 then begin diff := diff + 16; borrow := 1; end else borrow := 0;
      res := GetChar(diff) + res;
    end;
  end;
  if bNeg then res := '-' + res;
  InternalSub := res;
end;

function HexSum(sA, sB: string): string;
begin
  if IsNegative(sA) and IsNegative(sB) then HexSum := HexClean('-' + InternalSum(GetAbs(sA), GetAbs(sB)))
  else if IsNegative(sA) then HexSum := HexSub(sB, GetAbs(sA))
  else if IsNegative(sB) then HexSum := HexSub(sA, GetAbs(sB))
  else HexSum := HexClean(InternalSum(sA, sB));
end;

function HexSub(sA, sB: string): string;
begin
  if IsNegative(sB) then HexSub := HexSum(sA, GetAbs(sB))
  else if IsNegative(sA) then HexSub := HexClean('-' + InternalSum(GetAbs(sA), sB))
  else HexSub := HexClean(InternalSub(sA, sB));
end;

function HexMultiply(sA, sB: string): string;
var
  i, j, totalDecs, decA, decB, posDot: integer;
  sIntA, sIntB, sFinal, sRes: string;
  digitA, digitB, prod, carry: integer;
  isNeg: boolean;
begin
  isNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA); sB := GetAbs(sB);
  posDot := Pos(cDecimalSeparator, sA);
  if posDot > 0 then decA := Length(sA) - posDot else decA := 0;
  sIntA := StringReplace(sA, cDecimalSeparator, '', [rfReplaceAll]);
  posDot := Pos(cDecimalSeparator, sB);
  if posDot > 0 then decB := Length(sB) - posDot else decB := 0;
  sIntB := StringReplace(sB, cDecimalSeparator, '', [rfReplaceAll]);
  totalDecs := decA + decB;
  sFinal := '0';
  for i := Length(sIntB) downto 1 do begin
    digitB := GetVal(sIntB[i]);
    if digitB = 0 then Continue;
    sRes := ''; carry := 0;
    for j := Length(sIntA) downto 1 do begin
      digitA := GetVal(sIntA[j]);
      prod := (digitA * digitB) + carry;
      carry := prod div 16;
      sRes := GetChar(prod mod 16) + sRes;
    end;
    if carry > 0 then sRes := GetChar(carry) + sRes;
    for j := 1 to (Length(sIntB) - i) do sRes := sRes + '0';
    sFinal := HexSum(sFinal, sRes);
  end;
  if totalDecs > 0 then begin
    while Length(sFinal) <= totalDecs do sFinal := '0' + sFinal;
    Insert(cDecimalSeparator, sFinal, Length(sFinal) - totalDecs + 1);
  end;
  if isNeg and (sFinal <> '0') then HexMultiply := HexClean('-' + sFinal)
  else HexMultiply := HexClean(sFinal);
end;

function HexDivide(sA, sB: string): string;
var
  sQuot, sCurr, tA, tB: string;
  i, count, prec: integer;
  bHasDec, isNeg: boolean;
begin
  if HexClean(sB) = '0' then begin HexDivide := '0'; Exit; end;
  isNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA); sB := GetAbs(sB);
  tA := sA; tB := sB; Align(tA, tB);
  tA := StringReplace(tA, cDecimalSeparator, '', [rfReplaceAll]);
  tB := StringReplace(tB, cDecimalSeparator, '', [rfReplaceAll]);
  tA := HexClean(tA); tB := HexClean(tB);
  sQuot := ''; sCurr := '0'; prec := 0; bHasDec := False;
  for i := 1 to Length(tA) + 10 do begin
    if i <= Length(tA) then sCurr := sCurr + tA[i]
    else begin
      if not bHasDec then begin
        if sQuot = '' then sQuot := '0';
        sQuot := sQuot + cDecimalSeparator;
        bHasDec := True;
      end;
      sCurr := sCurr + '0'; Inc(prec);
    end;
    sCurr := HexClean(sCurr);
    count := 0;
    while (Length(sCurr) > Length(tB)) or ((Length(sCurr) = Length(tB)) and (sCurr >= tB)) do begin
      sCurr := HexClean(InternalSub(sCurr, tB));
      Inc(count);
    end;
    if (sQuot <> '') or (count > 0) or (i = Length(tA)) then sQuot := sQuot + GetChar(count);
    if (i >= Length(tA)) and (sCurr = '0') then Break;
    if prec >= 10 then Break;
  end;
  if isNeg and (sQuot <> '0') then HexDivide := HexClean('-' + sQuot)
  else HexDivide := HexClean(sQuot);
end;

{ Funcoes Auxiliares para Conversao String-na-String Base10 (Cópia da sAlfaMath para Portabilidade) }
function DecSum(sA, sB: string): string;
var
  i, sum, carry: integer;
  res: string;
begin
  while Length(sA) < Length(sB) do sA := '0' + sA;
  while Length(sB) < Length(sA) do sB := '0' + sB;
  res := ''; carry := 0;
  for i := Length(sA) downto 1 do begin
    sum := (Ord(sA[i]) - 48) + (Ord(sB[i]) - 48) + carry;
    carry := sum div 10;
    res := char((sum mod 10) + 48) + res;
  end;
  if carry > 0 then res := char(carry + 48) + res;
  DecSum := res;
end;

function DecMultSmall(sNum: string; val: integer): string;
var
  i, prod, carry: integer;
  res: string;
begin
  res := ''; carry := 0;
  for i := Length(sNum) downto 1 do begin
    prod := ((Ord(sNum[i]) - 48) * val) + carry;
    carry := prod div 10;
    res := char((prod mod 10) + 48) + res;
  end;
  if carry > 0 then res := IntToStr(carry) + res;
  DecMultSmall := res;
end;

function DecDivModSmall(sNum: string; divisor: integer; var rem: integer): string;
var
  i: integer;
  curr, q: integer;
  res: string;
begin
  res := ''; rem := 0;
  for i := 1 to Length(sNum) do begin
    curr := (rem * 10) + (Ord(sNum[i]) - 48);
    q := curr div divisor;
    rem := curr mod divisor;
    if (res <> '') or (q > 0) or (i = Length(sNum)) then
      res := res + char(q + 48);
  end;
  DecDivModSmall := res;
end;

function HexToDec(sHex: string): string;
var
  i, posDot: integer;
  isNeg: boolean;
  resInt, power, val: string;
begin
  isNeg := IsNegative(sHex);
  val := GetAbs(sHex);
  posDot := Pos(cDecimalSeparator, val);
  if posDot > 0 then resInt := Copy(val, 1, posDot - 1) else resInt := val;
  sHex := resInt;
  resInt := '0'; power := '1';
  for i := Length(sHex) downto 1 do begin
    resInt := DecSum(resInt, DecMultSmall(power, GetVal(sHex[i])));
    power := DecMultSmall(power, 16);
  end;
  if isNeg and (resInt <> '0') then HexToDec := '-' + resInt else HexToDec := resInt;
end;

function DecToHex(sDec: string): string;
var
  isNeg: boolean;
  val, res: string;
  rem: integer;
begin
  isNeg := IsNegative(sDec);
  val := GetAbs(sDec);
  if (Pos(cDecimalSeparator, val) > 0) then val := Copy(val, 1, Pos(cDecimalSeparator, val) - 1);
  res := '';
  repeat
    val := DecDivModSmall(val, 16, rem);
    res := GetChar(rem) + res;
  until (val = '0') or (val = '');
  if res = '' then res := '0';
  if isNeg and (res <> '0') then DecToHex := '-' + res else DecToHex := res;
end;

end.
