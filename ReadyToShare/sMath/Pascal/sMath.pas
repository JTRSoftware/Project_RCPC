unit sMath;

{
  sMath - Versao Turbo Pascal (16-bit).
  Limite de String: 255 caracteres.
}

interface

function Sum(sA, sB: String): String;
function Sub(sA, sB: String): String;
function Multiply(sA, sB: String): String;
function Divide(sA, sB: String): String;

var
  cDecimalSeparator: Char;

implementation

{ ... (AlignDecimals, Sum, Sub ja implementados) ... }

function Multiply(sA, sB: String): String;
var
  i, j, iPos: Byte;
  iDecA, iDecB, iTotalDecs: Byte;
  sIntA, sIntB, sRes, sFinal: String;
  iDigitA, iDigitB, iProd, iCarry: Integer;
begin
  iPos := Pos(cDecimalSeparator, sA);
  if iPos > 0 then iDecA := Length(sA) - iPos else iDecA := 0;
  sIntA := '';
  for i := 1 to Length(sA) do if sA[i] <> cDecimalSeparator then sIntA := sIntA + sA[i];
  
  iPos := Pos(cDecimalSeparator, sB);
  if iPos > 0 then iDecB := Length(sB) - iPos else iDecB := 0;
  sIntB := '';
  for i := 1 to Length(sB) do if sB[i] <> cDecimalSeparator then sIntB := sIntB + sB[i];
  
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
    if iCarry > 0 then sRes := IntToStr(iCarry) + sRes;
    for j := 1 to (Length(sIntB) - i) do sRes := sRes + '0';
    sFinal := Sum(sFinal, sRes);
  end;
  
  if iTotalDecs > 0 then begin
    while Length(sFinal) <= iTotalDecs do sFinal := '0' + sFinal;
    Insert(cDecimalSeparator, sFinal, Length(sFinal) - iTotalDecs + 1);
  end;
  Multiply := sFinal;
end;

function Divide(sA, sB: String): String;
var
  sQuot, sCurr, sTempA, sTempB: String;
  iCount, iPrec, i: Integer;
  bHasDec: Boolean;
begin
  if sB = '0' then begin Divide := '0'; Exit; end;
  
  { Simplificacao para 16-bit: Divisao de inteiros pela RAM }
  sQuot := ''; sCurr := ''; iPrec := 0; bHasDec := False;
  sTempA := sA; sTempB := sB;
  
  for i := 1 to Length(sTempA) + 10 do begin
    if i <= Length(sTempA) then sCurr := sCurr + sTempA[i]
    else begin
      if not bHasDec then begin 
        if sQuot = '' then sQuot := '0';
        sQuot := sQuot + cDecimalSeparator; 
        bHasDec := True; 
      end;
      sCurr := sCurr + '0'; Inc(iPrec);
    end;
    
    iCount := 0;
    while (Length(sCurr) > Length(sTempB)) or 
          ((Length(sCurr) = Length(sTempB)) and (sCurr >= sTempB)) do begin
      sCurr := Sub(sCurr, sTempB);
      Inc(iCount);
      { Limpeza de zeros a esquerda em sCurr }
      while (Length(sCurr) > 1) and (sCurr[1] = '0') do Delete(sCurr, 1, 1);
    end;
    
    if (sQuot <> '') or (iCount > 0) or (i = Length(sTempA)) then
      sQuot := sQuot + Char(iCount + 48);
      
    if (i >= Length(sTempA)) and (sCurr = '0') then Break;
    if iPrec >= 10 then Break;
  end;
  Divide := sQuot;
end;

function IntToStr(I: LongInt): String;
var S: String;
begin
  Str(I, S);
  IntToStr := S;
end;

function StrToInt(S: String): LongInt;
var I: LongInt; E: Integer;
begin
  Val(S, I, E);
  StrToInt := I;
end;

function Pos(C: Char; S: String): Byte;
var I: Byte;
begin
  Pos := 0;
  for I := 1 to Length(S) do
    if S[I] = C then begin Pos := I; Exit; end;
end;

procedure AlignDecimals(var sA, sB: String);
var iPosA, iPosB, iDecA, iDecB: Byte;
begin
  iPosA := Pos(cDecimalSeparator, sA);
  iPosB := Pos(cDecimalSeparator, sB);
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

function Sum(sA, sB: String): String;
var i: Byte; iSum, iCarry: Integer; sRes: String;
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
  if iCarry > 0 then sRes := Char(iCarry + 48) + sRes;
  Sum := sRes;
end;

function Sub(sA, sB: String): String;
var i: Byte; iSub, iBorrow: Integer; sRes, sTemp: String; bNeg: Boolean;
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
  Sub := sRes;
end;

begin
  cDecimalSeparator := '.';
end.
