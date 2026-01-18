unit sMath;

{$mode delphi}

{
  Unidade de cálculos básicos com strings (Versão Lazarus/FPC).
  Isto serve para que processadores pequenos consigam realizar cálculos 
  com números muito grandes.
}

interface

uses
  SysUtils;

function Sum(sA, sB: String): String;
function Sub(sA, sB: String): String;
function Multiply(sA, sB: String): String;
function Divide(sA, sB: String): String;

var
  cDecimalSeparator: Char = '.';

implementation

{ --- Utilitários de Sinal e Limpeza --- }

function IsNegative(const sV: String): Boolean;
begin
  Result := (sV <> '') and (sV[1] = '-');
end;

function GetAbs(const sV: String): String;
begin
  if IsNegative(sV) then
    Result := Copy(sV, 2, MaxInt)
  else
    Result := sV;
end;

function CleanNumber(sV: String): String;
var
  iPos: Integer;
  bNeg: Boolean;
  sVal: String;
begin
  bNeg := IsNegative(sV);
  sVal := GetAbs(sV);
  
  if sVal = '' then 
  begin
    Result := '0';
    Exit;
  end;

  while (Length(sVal) > 1) and (sVal[1] = '0') and (sVal[2] <> cDecimalSeparator) do
    Delete(sVal, 1, 1);
    
  iPos := Pos(cDecimalSeparator, sVal);
  if iPos > 0 then
  begin
    while (Length(sVal) > iPos) and (sVal[Length(sVal)] = '0') do
      Delete(sVal, Length(sVal), 1);
    if sVal[Length(sVal)] = cDecimalSeparator then
      Delete(sVal, Length(sVal), 1);
  end;
  
  if (sVal = '') or (sVal = cDecimalSeparator) then 
    sVal := '0';

  if bNeg and (sVal <> '0') then
    Result := '-' + sVal
  else
    Result := sVal;
end;

procedure AlignDecimals(var sA, sB: String);
var
  iPosA, iPosB: Integer;
  iDecA, iDecB: Integer;
begin
  iPosA := Pos(cDecimalSeparator, sA);
  iPosB := Pos(cDecimalSeparator, sB);

  if iPosA = 0 then iDecA := 0 else iDecA := Length(sA) - iPosA;
  if iPosB = 0 then iDecB := 0 else iDecB := Length(sB) - iPosB;

  while iDecA < iDecB do
  begin
    if iPosA = 0 then
    begin
      sA := sA + cDecimalSeparator;
      iPosA := Length(sA);
    end;
    sA := sA + '0';
    Inc(iDecA);
  end;
  while iDecB < iDecA do
  begin
    if iPosB = 0 then
    begin
      sB := sB + cDecimalSeparator;
      iPosB := Length(sB);
    end;
    sB := sB + '0';
    Inc(iDecB);
  end;

  if iPosA = 0 then iPosA := Length(sA) + 1;
  if iPosB = 0 then iPosB := Length(sB) + 1;

  while iPosA < iPosB do
  begin
    sA := '0' + sA;
    Inc(iPosA);
  end;
  while iPosB < iPosA do
  begin
    sB := '0' + sB;
    Inc(iPosB);
  end;
end;

function IsGreaterOrEqual(sA, sB: String): Boolean;
var
  sT1, sT2: String;
begin
  sT1 := GetAbs(sA);
  sT2 := GetAbs(sB);
  AlignDecimals(sT1, sT2);
  Result := sT1 >= sT2;
end;

function InternalSum(sA, sB: String): String;
var
  i: Integer;
  iSum, iCarry: Integer;
  sRes: String;
begin
  AlignDecimals(sA, sB);
  sRes := '';
  iCarry := 0;
  for i := Length(sA) downto 1 do
  begin
    if sA[i] = cDecimalSeparator then
    begin
      sRes := cDecimalSeparator + sRes;
      continue;
    end;
    iSum := (Ord(sA[i]) - Ord('0')) + (Ord(sB[i]) - Ord('0')) + iCarry;
    iCarry := iSum div 10;
    sRes := Char((iSum mod 10) + Ord('0')) + sRes;
  end;
  if iCarry > 0 then
    sRes := Char(iCarry + Ord('0')) + sRes;
  Result := sRes;
end;

function InternalSub(sA, sB: String): String;
var
  i: Integer;
  iSub, iBorrow: Integer;
  sRes: String;
  bNegative: Boolean;
  sTemp: String;
begin
  AlignDecimals(sA, sB);
  bNegative := False;
  if sA < sB then
  begin
    sTemp := sA;
    sA := sB;
    sB := sTemp;
    bNegative := True;
  end;

  sRes := '';
  iBorrow := 0;
  for i := Length(sA) downto 1 do
  begin
    if sA[i] = cDecimalSeparator then
    begin
      sRes := cDecimalSeparator + sRes;
      continue;
    end;
    iSub := (Ord(sA[i]) - Ord('0')) - (Ord(sB[i]) - Ord('0')) - iBorrow;
    if iSub < 0 then
    begin
      iSub := iSub + 10;
      iBorrow := 1;
    end
    else
      iBorrow := 0;
    sRes := Char(iSub + Ord('0')) + sRes;
  end;
  
  Result := sRes;
  if bNegative then
    Result := '-' + Result;
end;

function Sum(sA, sB: String): String;
begin
  if IsNegative(sA) and IsNegative(sB) then
    Result := '-' + InternalSum(GetAbs(sA), GetAbs(sB))
  else if IsNegative(sA) then
    Result := InternalSub(GetAbs(sB), GetAbs(sA))
  else if IsNegative(sB) then
    Result := InternalSub(GetAbs(sA), GetAbs(sB))
  else
    Result := InternalSum(sA, sB);
    
  Result := CleanNumber(Result);
end;

function Sub(sA, sB: String): String;
begin
  if IsNegative(sB) then
    Result := Sum(sA, GetAbs(sB))
  else if IsNegative(sA) then
    Result := '-' + InternalSum(GetAbs(sA), sB)
  else
    Result := InternalSub(sA, sB);
    
  Result := CleanNumber(Result);
end;

function Multiply(sA, sB: String): String;
var
  i, j, iPos, iDecA, iDecB, iTotalDecs: Integer;
  sIntA, sIntB: String;
  iDigitA, iDigitB, iProduct, iCarry: Integer;
  sCurrentRes, sFinalRes: String;
  bResNeg: Boolean;
begin
  bResNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA);
  sB := GetAbs(sB);

  iPos := Pos(cDecimalSeparator, sA);
  if iPos > 0 then iDecA := Length(sA) - iPos else iDecA := 0;
  sIntA := StringReplace(sA, cDecimalSeparator, '', [rfReplaceAll]);
  
  iPos := Pos(cDecimalSeparator, sB);
  if iPos > 0 then iDecB := Length(sB) - iPos else iDecB := 0;
  sIntB := StringReplace(sB, cDecimalSeparator, '', [rfReplaceAll]);
  
  iTotalDecs := iDecA + iDecB;
  
  sFinalRes := '0';
  for i := Length(sIntB) downto 1 do
  begin
    iDigitB := Ord(sIntB[i]) - Ord('0');
    if iDigitB = 0 then Continue;
    sCurrentRes := '';
    iCarry := 0;
    for j := Length(sIntA) downto 1 do
    begin
      iDigitA := Ord(sIntA[j]) - Ord('0');
      iProduct := iDigitA * iDigitB + iCarry;
      iCarry := iProduct div 10;
      sCurrentRes := Char((iProduct mod 10) + Ord('0')) + sCurrentRes;
    end;
    if iCarry > 0 then
      sCurrentRes := IntToStr(iCarry) + sCurrentRes;
    
    for j := 1 to (Length(sIntB) - i) do
      sCurrentRes := sCurrentRes + '0';
      
    sFinalRes := InternalSum(sFinalRes, sCurrentRes);
  end;
  
  if iTotalDecs > 0 then
  begin
    while Length(sFinalRes) <= iTotalDecs do
      sFinalRes := '0' + sFinalRes;
    Insert(cDecimalSeparator, sFinalRes, Length(sFinalRes) - iTotalDecs + 1);
  end;
  
  if bResNeg then
    Result := '-' + sFinalRes
  else
    Result := sFinalRes;
    
  Result := CleanNumber(Result);
end;

function Divide(sA, sB: String): String;
var
  sQuotient, sCurrent: String;
  iCount, iPrecision, i: Integer;
  bHasDecimal, bResNeg: Boolean;
  sTempA, sTempB: String;
begin
  bResNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA);
  sB := GetAbs(sB);

  if CleanNumber(sB) = '0' then
  begin
    Result := '0';
    Exit;
  end;

  sTempA := sA;
  sTempB := sB;
  AlignDecimals(sTempA, sTempB);
  sTempA := StringReplace(sTempA, cDecimalSeparator, '', [rfReplaceAll]);
  sTempB := StringReplace(sTempB, cDecimalSeparator, '', [rfReplaceAll]);
  sTempA := CleanNumber(sTempA);
  sTempB := CleanNumber(sTempB);

  sQuotient := '';
  sCurrent := '';
  iPrecision := 0;
  bHasDecimal := False;

  for i := 1 to Length(sTempA) + 10 do 
  begin
    if i <= Length(sTempA) then
      sCurrent := sCurrent + sTempA[i]
    else
    begin
      if not bHasDecimal then
      begin
        if sQuotient = '' then sQuotient := '0';
        sQuotient := sQuotient + cDecimalSeparator;
        bHasDecimal := True;
      end;
      sCurrent := sCurrent + '0';
      Inc(iPrecision);
    end;

    sCurrent := CleanNumber(sCurrent);
    iCount := 0;
    while IsGreaterOrEqual(sCurrent, sTempB) do
    begin
      sCurrent := InternalSub(sCurrent, sTempB);
      Inc(iCount);
    end;
    
    if (sQuotient <> '') or (iCount > 0) or (i = Length(sTempA)) then
    begin
        if bHasDecimal and (sQuotient[Length(sQuotient)] = cDecimalSeparator) and (iCount = 0) and (i <= Length(sTempA)) then
        else if (sQuotient <> '') or (iCount > 0) or (i = Length(sTempA)) or bHasDecimal then
            sQuotient := sQuotient + IntToStr(iCount);
    end;

    if (i >= Length(sTempA)) and (CleanNumber(sCurrent) = '0') then Break;
    if iPrecision >= 10 then Break;
  end;

  if bResNeg and (sQuotient <> '0') then
    Result := '-' + sQuotient
  else
    Result := sQuotient;

  Result := CleanNumber(Result);
end;

end.
