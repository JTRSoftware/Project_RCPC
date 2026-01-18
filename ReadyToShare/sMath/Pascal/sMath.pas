unit sMath;

{
  sMath - Versao Turbo Pascal (16-bit).
  Limite de String: 255 caracteres.
  ADN de Super-Saiyajin adaptado para 16 bits.
}

interface

function Sum(sA, sB: String): String;
function Sub(sA, sB: String): String;
function Multiply(sA, sB: String): String;
function Divide(sA, sB: String): String;
function CleanNumber(sV: String): String;

var
  cDecimalSeparator: Char;

implementation

function IsNegative(sV: String): Boolean;
begin
  IsNegative := (Length(sV) > 0) and (sV[1] = '-');
end;

function GetAbs(sV: String): String;
begin
  if IsNegative(sV) then GetAbs := Copy(sV, 2, 255)
  else GetAbs := sV;
end;

function CleanNumber(sV: String): String;
var
  neg: Boolean;
  val: String;
  dot: Byte;
begin
  neg := IsNegative(sV);
  val := GetAbs(sV);
  while (Length(val) > 1) and (val[1] = '0') and (val[2] <> cDecimalSeparator) do 
    Delete(val, 1, 1);
  
  dot := 0;
  for dot := 1 to Length(val) do if val[dot] = cDecimalSeparator then Break;
  if (dot <= Length(val)) and (val[dot] = cDecimalSeparator) then
  begin
    while (Length(val) > dot) and (val[Length(val)] = '0') do Delete(val, Length(val), 1);
    if val[Length(val)] = cDecimalSeparator then Delete(val, Length(val), 1);
  end;
  
  if (val = '') or (val = cDecimalSeparator) then val := '0';
  if neg and (val <> '0') then CleanNumber := '-' + val
  else CleanNumber := val;
end;

procedure AlignDecimals(var sA, sB: String);
var 
  iPosA, iPosB, iDecA, iDecB: Byte;
  i: Byte;
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

function InternalSum(sA, sB: String): String;
var 
  i: Byte; iSum, iCarry: Integer; sRes: String;
begin
  AlignDecimals(sA, sB);
  sRes := ''; iCarry := 0;
  for i := Length(sA) downto 1 do begin
    if sA[i] = cDecimalSeparator then sRes := cDecimalSeparator + sRes
    else begin
      iSum := (Ord(sA[i]) - 48) + (Ord(sB[i]) - 48) + iCarry;
      iCarry := iSum div 10;
      sRes := Char((iSum mod 10) + 48) + sRes;
    end;
  end;
  if iCarry > 0 then begin
    Str(iCarry, sA);
    sRes := sA + sRes;
  end;
  InternalSum := sRes;
end;

function InternalSub(sA, sB: String): String;
var 
  i: Byte; iSub, iBorrow: Integer; sRes, sTemp: String; bNeg: Boolean;
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
      sRes := Char(iSub + 48) + sRes;
    end;
  end;
  if bNeg then sRes := '-' + sRes;
  InternalSub := sRes;
end;

function Sum(sA, sB: String): String;
begin
  if IsNegative(sA) and IsNegative(sB) then Sum := '-' + InternalSum(GetAbs(sA), GetAbs(sB))
  else if IsNegative(sA) then Sum := InternalSub(GetAbs(sB), GetAbs(sA))
  else if IsNegative(sB) then Sum := InternalSub(GetAbs(sA), GetAbs(sB))
  else Sum := InternalSum(sA, sB);
end;

function Sub(sA, sB: String): String;
begin
  if IsNegative(sB) then Sub := Sum(sA, GetAbs(sB))
  else if IsNegative(sA) then Sub := '-' + InternalSum(GetAbs(sA), sB)
  else Sub := InternalSub(sA, sB);
end;

function Multiply(sA, sB: String): String;
var
  i, j, iPos: Byte;
  iDecA, iDecB, iTotalDecs: Byte;
  sIntA, sIntB, sRes, sFinal, sTemp: String;
  iDigitA, iDigitB, iProd, iCarry: Integer;
  resNeg: Boolean;
begin
  resNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA); sB := GetAbs(sB);
  
  iPos := 0; for i := 1 to Length(sA) do if sA[i] = cDecimalSeparator then iPos := i;
  if iPos > 0 then iDecA := Length(sA) - iPos else iDecA := 0;
  sIntA := ''; for i := 1 to Length(sA) do if sA[i] <> cDecimalSeparator then sIntA := sIntA + sA[i];
  
  iPos := 0; for i := 1 to Length(sB) do if sB[i] = cDecimalSeparator then iPos := i;
  if iPos > 0 then iDecB := Length(sB) - iPos else iDecB := 0;
  sIntB := ''; for i := 1 to Length(sB) do if sB[i] <> cDecimalSeparator then sIntB := sIntB + sB[i];
  
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
      sRes := Char((iProd mod 10) + 48) + sRes;
    end;
    if iCarry > 0 then begin Str(iCarry, sTemp); sRes := sTemp + sRes; end;
    for j := 1 to (Length(sIntB) - i) do sRes := sRes + '0';
    sFinal := InternalSum(sFinal, sRes);
  end;
  
  if iTotalDecs > 0 then begin
    while Length(sFinal) <= iTotalDecs do sFinal := '0' + sFinal;
    Insert(cDecimalSeparator, sFinal, Length(sFinal) - iTotalDecs + 1);
  end;
  if resNeg and (sFinal <> '0') then Multiply := '-' + CleanNumber(sFinal)
  else Multiply := CleanNumber(sFinal);
end;

function Divide(sA, sB: String): String;
var
  sQuot, sCurr, sTempA, sTempB: String;
  iCount, iPrec, i: Integer;
  bHasDec, resNeg: Boolean;
begin
  if CleanNumber(sB) = '0' then begin Divide := '0'; Exit; end;
  resNeg := IsNegative(sA) xor IsNegative(sB);
  sA := GetAbs(sA); sB := GetAbs(sB);
  
  sQuot := ''; sCurr := '0'; iPrec := 0; bHasDec := False;
  sTempA := sA; sTempB := sB;
  AlignDecimals(sTempA, sTempB);
  { Simplificar strings removendo separador para dividir como inteiros }
  sA := ''; for i := 1 to Length(sTempA) do if sTempA[i] <> cDecimalSeparator then sA := sA + sTempA[i];
  sB := ''; for i := 1 to Length(sTempB) do if sTempB[i] <> cDecimalSeparator then sB := sB + sTempB[i];
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
      sCurr := InternalSub(sCurr, sB);
      sCurr := CleanNumber(sCurr);
      Inc(iCount);
    end;
    if (sQuot <> '') or (iCount > 0) or (i = Length(sA)) then
      sQuot := sQuot + Char(iCount + 48);
    if (i >= Length(sA)) and (sCurr = '0') then Break;
    if iPrec >= 10 then Break;
  end;
  if resNeg and (sQuot <> '0') then Divide := '-' + CleanNumber(sQuot)
  else Divide := CleanNumber(sQuot);
end;

begin
  cDecimalSeparator := '.';
end.
