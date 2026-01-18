unit sAlfaMath;

{
  sAlfaMath - O DNA de Nível Alfa.
  Base-36 (0-9, A-Z) - Máxima densidade e performance em String.
  JTR Software - "O complicado é parecer simples"
}

interface

uses SysUtils, Math;

function AlfaSum(sA, sB: string): string;
function AlfaSub(sA, sB: string): string;
function AlfaMultiply(sA, sB: string): string;
function AlfaDivide(sA, sB: string): string;
function AlfaClean(sV: string): string;
function AlfaToDec(sAlfa: string): string;
function DecToAlfa(sDec: string): string;

const
  cDecimalSeparator: char = '.';
  AlfaChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

implementation

function IsNegative(sV: string): boolean;
begin
  IsNegative := (Length(sV) > 0) and (sV[1] = '-');
end;

function GetAbs(sV: string): string;
begin
  if IsNegative(sV) then GetAbs := Copy(sV, 2, 255)
  else
    GetAbs := sV;
end;

function GetVal(C: char): integer;
begin
  C := UpCase(C);
  if (C >= '0') and (C <= '9') then Result := Ord(C) - 48
  else if (C >= 'A') and (C <= 'Z') then Result := Ord(C) - 55
  else
    Result := 0;
end;

function GetChar(V: integer): char;
begin
  if (V >= 0) and (V <= 35) then Result := AlfaChars[V + 1]
  else
    Result := '0';
end;

function AlfaClean(sV: string): string;
var
  neg: boolean;
  val: string;
begin
  neg := IsNegative(sV);
  val := GetAbs(sV);
  while (Length(val) > 1) and (val[1] = '0') and (val[2] <> cDecimalSeparator) do
    Delete(val, 1, 1);
  if (Pos(cDecimalSeparator, val) > 0) then
  begin
    while (Length(val) > 1) and (val[Length(val)] = '0') and
      (val[Length(val) - 1] <> cDecimalSeparator) do
      Delete(val, Length(val), 1);
    if val[Length(val)] = cDecimalSeparator then Delete(val, Length(val), 1);
  end;
  if val = '' then val := '0';
  if neg and (val <> '0') then AlfaClean := '-' + val
  else
    AlfaClean := val;
end;

procedure Align(var sA, sB: string);
var
  pA, pB, dA, dB, i: integer;
begin
  pA := 0;
  for i := 1 to Length(sA) do if sA[i] = cDecimalSeparator then pA := i;
  pB := 0;
  for i := 1 to Length(sB) do if sB[i] = cDecimalSeparator then pB := i;
  if pA = 0 then dA := 0
  else
    dA := Length(sA) - pA;
  if pB = 0 then dB := 0
  else
    dB := Length(sB) - pB;
  while dA < dB do
  begin
    if pA = 0 then
    begin
      sA := sA + cDecimalSeparator;
      pA := Length(sA);
    end;
    sA := sA + '0';
    Inc(dA);
  end;
  while dB < dA do
  begin
    if pB = 0 then
    begin
      sB := sB + cDecimalSeparator;
      pB := Length(sB);
    end;
    sB := sB + '0';
    Inc(dB);
  end;
  if pA = 0 then pA := Length(sA) + 1;
  if pB = 0 then pB := Length(sB) + 1;
  while pA < pB do
  begin
    sA := '0' + sA;
    Inc(pA);
  end;
  while pB < pA do
  begin
    sB := '0' + sB;
    Inc(pB);
  end;
end;

function InternalSum(sA, sB: string): string;
var
  i, sum, carry: integer;
  res: string;
begin
  Align(sA, sB);
  res := '';
  carry := 0;
  for i := Length(sA) downto 1 do
  begin
    if sA[i] = cDecimalSeparator then res := cDecimalSeparator + res
    else
    begin
      sum := GetVal(sA[i]) + GetVal(sB[i]) + carry;
      carry := sum div 36;
      res := GetChar(sum mod 36) + res;
    end;
  end;
  if carry > 0 then res := GetChar(carry) + res;
  InternalSum := res;
end;

function InternalSub(sA, sB: string): string;
var
  i, diff, borrow: integer;
  res, t: string;
  bNeg: boolean;
begin
  Align(sA, sB);
  bNeg := sA < sB;
  if bNeg then
  begin
    t := sA;
    sA := sB;
    sB := t;
  end;
  res := '';
  borrow := 0;
  for i := Length(sA) downto 1 do
  begin
    if sA[i] = cDecimalSeparator then res := cDecimalSeparator + res
    else
    begin
      diff := GetVal(sA[i]) - GetVal(sB[i]) - borrow;
      if diff < 0 then
      begin
        diff := diff + 36;
        borrow := 1;
      end
      else
        borrow := 0;
      res := GetChar(diff) + res;
    end;
  end;
  if bNeg then res := '-' + res;
  InternalSub := res;
end;

function AlfaSum(sA, sB: string): string;
begin
  if IsNegative(sA) and IsNegative(sB) then
    AlfaSum := AlfaClean('-' + InternalSum(GetAbs(sA), GetAbs(sB)))
  else if IsNegative(sA) then AlfaSum := AlfaSub(sB, GetAbs(sA))
  else if IsNegative(sB) then AlfaSum := AlfaSub(sA, GetAbs(sB))
  else
    AlfaSum := AlfaClean(InternalSum(sA, sB));
end;

function AlfaSub(sA, sB: string): string;
begin
  if IsNegative(sB) then AlfaSub := AlfaSum(sA, GetAbs(sB))
  else if IsNegative(sA) then AlfaSub := AlfaClean('-' + InternalSum(GetAbs(sA), sB))
  else
    AlfaSub := AlfaClean(InternalSub(sA, sB));
end;

function AlfaMultiply(sA, sB: string): string;
var
  i, j, totalDecs, decA, decB, posDot: integer;
  sIntA, sIntB, sFinal, sRes: string;
  digitA, digitB, prod, carry: integer;
  isNeg: boolean;
begin
  isNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA);
  sB := GetAbs(sB);
  posDot := Pos(cDecimalSeparator, sA);
  if posDot > 0 then decA := Length(sA) - posDot
  else
    decA := 0;
  sIntA := StringReplace(sA, cDecimalSeparator, '', [rfReplaceAll]);
  posDot := Pos(cDecimalSeparator, sB);
  if posDot > 0 then decB := Length(sB) - posDot
  else
    decB := 0;
  sIntB := StringReplace(sB, cDecimalSeparator, '', [rfReplaceAll]);
  totalDecs := decA + decB;
  sFinal := '0';
  for i := Length(sIntB) downto 1 do
  begin
    digitB := GetVal(sIntB[i]);
    if digitB = 0 then Continue;
    sRes := '';
    carry := 0;
    for j := Length(sIntA) downto 1 do
    begin
      digitA := GetVal(sIntA[j]);
      prod := (digitA * digitB) + carry;
      carry := prod div 36;
      sRes := GetChar(prod mod 36) + sRes;
    end;
    if carry > 0 then sRes := GetChar(carry) + sRes;
    for j := 1 to (Length(sIntB) - i) do sRes := sRes + '0';
    sFinal := AlfaSum(sFinal, sRes);
  end;
  if totalDecs > 0 then
  begin
    while Length(sFinal) <= totalDecs do sFinal := '0' + sFinal;
    Insert(cDecimalSeparator, sFinal, Length(sFinal) - totalDecs + 1);
  end;
  if isNeg and (sFinal <> '0') then AlfaMultiply := AlfaClean('-' + sFinal)
  else
    AlfaMultiply := AlfaClean(sFinal);
end;

function AlfaDivide(sA, sB: string): string;
var
  sQuot, sCurr, tA, tB: string;
  i, Count, prec: integer;
  bHasDec, isNeg: boolean;
begin
  if AlfaClean(sB) = '0' then
  begin
    AlfaDivide := '0';
    Exit;
  end;
  isNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA);
  sB := GetAbs(sB);
  tA := sA;
  tB := sB;
  Align(tA, tB);
  tA := StringReplace(tA, cDecimalSeparator, '', [rfReplaceAll]);
  tB := StringReplace(tB, cDecimalSeparator, '', [rfReplaceAll]);
  tA := AlfaClean(tA);
  tB := AlfaClean(tB);
  sQuot := '';
  sCurr := '0';
  prec := 0;
  bHasDec := False;
  for i := 1 to Length(tA) + 10 do
  begin
    if i <= Length(tA) then sCurr := sCurr + tA[i]
    else
    begin
      if not bHasDec then
      begin
        if sQuot = '' then sQuot := '0';
        sQuot := sQuot + cDecimalSeparator;
        bHasDec := True;
      end;
      sCurr := sCurr + '0';
      Inc(prec);
    end;
    sCurr := AlfaClean(sCurr);
    Count := 0;
    while (Length(sCurr) > Length(tB)) or ((Length(sCurr) = Length(tB)) and
        (sCurr >= tB)) do
    begin
      sCurr := AlfaClean(InternalSub(sCurr, tB));
      Inc(Count);
    end;
    if (sQuot <> '') or (Count > 0) or (i = Length(tA)) then
      sQuot := sQuot + GetChar(Count);
    if (i >= Length(tA)) and (sCurr = '0') then Break;
    if prec >= 10 then Break;
  end;
  if isNeg and (sQuot <> '0') then AlfaDivide := AlfaClean('-' + sQuot)
  else
    AlfaDivide := AlfaClean(sQuot);
end;

{ Funcoes Auxiliares para Conversao String-na-String Base10 }
function DecSum(sA, sB: string): string;
var
  i, sum, carry: integer;
  res: string;
begin
  while Length(sA) < Length(sB) do sA := '0' + sA;
  while Length(sB) < Length(sA) do sB := '0' + sB;
  res := '';
  carry := 0;
  for i := Length(sA) downto 1 do
  begin
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
  res := '';
  carry := 0;
  for i := Length(sNum) downto 1 do
  begin
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

function AlfaToDec(sAlfa: string): string;
var
  i, posDot, decLen: integer;
  isNeg: boolean;
  resInt, resDec, power, digitVal: string;
  val: string;
begin
  isNeg := IsNegative(sAlfa);
  val := GetAbs(sAlfa);
  posDot := Pos(cDecimalSeparator, val);

  // Parte Inteira
  if posDot > 0 then resInt := Copy(val, 1, posDot - 1)
  else
    resInt := val;
  sAlfa := resInt;
  resInt := '0';
  power := '1';
  for i := Length(sAlfa) downto 1 do
  begin
    resInt := DecSum(resInt, DecMultSmall(power, GetVal(sAlfa[i])));
    power := DecMultSmall(power, 36);
  end;

  // Parte Decimal (Simplificada para a Calculadora: Max 10 casas)
  if posDot > 0 then
  begin
    val := Copy(val, posDot + 1, 10); // Lemos ate 10 casas alfa
    resDec := '';
    // Para simplicidade na conversao de fracoes alfa para dec,
    // usaremos uma aproximacao: AlfaToDec(N) = DecSum(DecMult(AlfaToDec(Int), 36), Digit) / 36^pos
    // Mas para uma UI de calculadora, vamos focar no Inteiro primeiro ou usar Float se pequeno.
    // Como o sMath e para o Infinito, manteremos String:
    // ( d1/36 + d2/36^2 + ... )
  end;

  if isNeg and (resInt <> '0') then AlfaToDec := '-' + resInt
  else
    AlfaToDec := resInt;
end;

function DecToAlfa(sDec: string): string;
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
    val := DecDivModSmall(val, 36, rem);
    res := GetChar(rem) + res;
  until (val = '0') or (val = '');
  if res = '' then res := '0';
  if isNeg and (res <> '0') then DecToAlfa := '-' + res else DecToAlfa := res;
end;

end.
