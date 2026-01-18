unit sSwapMath;

{
  sSwapMath - ADN de Super-Saiyajin para cálculos massivos.
  Esta unidade realiza cálculos aritméticos utilizando o disco (Swap) 
  em vez da RAM, permitindo processar números com Terabytes de dígitos.
  
  Estratégia: Normalização física (adicção de zeros) para igualar os operandos.
  Filosofia: É simples parecer complicado, o complicado é parecer simples.
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math;

procedure SwapSum(const sFileA, sFileB, sFileRes: String);
procedure SwapSub(const sFileA, sFileB, sFileRes: String);
procedure SwapMultiply(const sFileA, sFileB, sFileRes: String);
procedure SwapDivide(const sFileA, sFileB, sFileRes: String);

var
  cDecimalSeparator: Char = '.';
  iBufferSize: Integer = 1024 * 64; // 64KB de buffer para SSD

implementation

type
  TNumInfo = record
    IntLen: Int64;
    DecLen: Int64;
    HasDec: Boolean;
    TotalLen: Int64;
  end;

  TProgressCallback = procedure(const iPos, iTotal: Int64) of object;

var
  cDecimalSeparator: Char = '.';
  iBufferSize: Integer = 1024 * 64; // 64KB de buffer para SSD
  OnProgress: TProgressCallback = nil;

implementation

{ --- Auxiliares de Análise --- }

function GetNumInfo(const sFile: String): TNumInfo;
var
  fs: TFileStream;
  buffer: array[0..4095] of Byte;
  iRead, i: Integer;
  iDecPos: Int64;
begin
  Result.IntLen := 0;
  Result.DecLen := 0;
  Result.HasDec := False;
  Result.TotalLen := 0;
  
  if not TFile.Exists(sFile) then Exit;
  
  fs := TFileStream.Create(sFile, fmOpenRead or fmShareDenyNone);
  try
    Result.TotalLen := fs.Size;
    iDecPos := -1;
    while fs.Position < fs.Size do
    begin
      iRead := fs.Read(buffer[0], 4096);
      for i := 0 to iRead - 1 do
      begin
        if Char(buffer[i]) = cDecimalSeparator then
        begin
          iDecPos := fs.Position - iRead + i;
          Break;
        end;
      end;
      if iDecPos <> -1 then Break;
    end;

    if iDecPos <> -1 then
    begin
      Result.HasDec := True;
      Result.IntLen := iDecPos;
      Result.DecLen := fs.Size - iDecPos - 1;
    end
    else
    begin
      Result.IntLen := fs.Size;
      Result.DecLen := 0;
    end;
  finally
    fs.Free;
  end;
end;

{ --- Normalização --- }

procedure CreateNormalizedFile(const sIn, sOut: String; iTargetInt, iTargetDec: Int64);
var
  fsIn, fsOut: TFileStream;
  Info: TNumInfo;
  i: Int64;
  cZero: Char;
  buffer: array of Byte;
  iRead: Integer;
begin
  cZero := '0';
  Info := GetNumInfo(sIn);
  fsIn := TFileStream.Create(sIn, fmOpenRead);
  fsOut := TFileStream.Create(sOut, fmCreate);
  try
    for i := 1 to (iTargetInt - Info.IntLen) do
      fsOut.Write(cZero, 1);
    
    SetLength(buffer, iBufferSize);
    i := 0;
    while i < Info.IntLen do
    begin
      iRead := fsIn.Read(buffer[0], Min(iBufferSize, Info.IntLen - i));
      fsOut.Write(buffer[0], iRead);
      i := i + iRead;
    end;

    fsOut.Write(cDecimalSeparator, 1);

    if Info.HasDec then
    begin
      fsIn.Position := Info.IntLen + 1;
      i := 0;
      while i < Info.DecLen do
      begin
        iRead := fsIn.Read(buffer[0], Min(iBufferSize, Info.DecLen - i));
        fsOut.Write(buffer[0], iRead);
        i := i + iRead;
      end;
    end;

    for i := 1 to (iTargetDec - Info.DecLen) do
      fsOut.Write(cZero, 1);
  finally
    fsIn.Free;
    fsOut.Free;
  end;
end;

procedure ReverseFile(const sSource, sDest: String);
var
  fsIn, fsOut: TFileStream;
  buffer: array of Byte;
  iRead, i: Integer;
  iTotalBlocks: Int64;
  iRemainder: Integer;
begin
  fsIn := TFileStream.Create(sSource, fmOpenRead);
  fsOut := TFileStream.Create(sDest, fmCreate);
  try
    SetLength(buffer, iBufferSize);
    iTotalBlocks := fsIn.Size div iBufferSize;
    iRemainder := fsIn.Size mod iBufferSize;

    if iRemainder > 0 then
    begin
      fsIn.Position := fsIn.Size - iRemainder;
      fsIn.Read(buffer[0], iRemainder);
      for i := iRemainder - 1 downto 0 do
        fsOut.Write(buffer[i], 1);
    end;

    for i := iTotalBlocks - 1 downto 0 do
    begin
      fsIn.Position := Int64(i) * iBufferSize;
      fsIn.Read(buffer[0], iBufferSize);
      for iRead := iBufferSize - 1 downto 0 do
        fsOut.Write(buffer[iRead], 1);
    end;
  finally
    fsIn.Free;
    fsOut.Free;
  end;
end;


procedure SwapSum(const sFileA, sFileB, sFileRes: String);
var
  InfoA, InfoB: TNumInfo;
  iMaxInt, iMaxDec: Int64;
  sNormA, sNormB, sTempRes: String;
  fsA, fsB, fsRes: TFileStream;
  iPos, iTotal: Int64;
  cDigitA, cDigitB, cRes: Char;
  iSum, iCarry: Integer;
begin
  InfoA := GetNumInfo(sFileA);
  InfoB := GetNumInfo(sFileB);

  iMaxInt := Max(InfoA.IntLen, InfoB.IntLen);
  iMaxDec := Max(InfoA.DecLen, InfoB.DecLen);

  sNormA := sFileA + '.norm';
  sNormB := sFileB + '.norm';
  sTempRes := sFileRes + '.tmp';

  CreateNormalizedFile(sFileA, sNormA, iMaxInt, iMaxDec);
  CreateNormalizedFile(sFileB, sNormB, iMaxInt, iMaxDec);

  fsA := TFileStream.Create(sNormA, fmOpenRead);
  fsB := TFileStream.Create(sNormB, fmOpenRead);
  fsRes := TFileStream.Create(sTempRes, fmCreate);
  try
    iCarry := 0;
    iTotal := fsA.Size;
    for iPos := iTotal - 1 downto 0 do
    begin
      if (iPos mod 1000 = 0) and Assigned(OnProgress) then
        OnProgress(iTotal - iPos, iTotal);

      fsA.Position := iPos;
      fsB.Position := iPos;
      fsA.Read(cDigitA, 1);
      fsB.Read(cDigitB, 1);

      if cDigitA = cDecimalSeparator then
      begin
        fsRes.Write(cDecimalSeparator, 1);
        Continue;
      end;

      iSum := (Ord(cDigitA) - Ord('0')) + (Ord(cDigitB) - Ord('0')) + iCarry;
      iCarry := iSum div 10;
      cRes := Char((iSum mod 10) + Ord('0'));
      fsRes.Write(cRes, 1);
    end;

    if iCarry > 0 then
    begin
      cRes := Char(iCarry + Ord('0'));
      fsRes.Write(cRes, 1);
    end;
  finally
    fsA.Free;
    fsB.Free;
    fsRes.Free;
  end;

  ReverseFile(sTempRes, sFileRes);
  TFile.Delete(sNormA);
  TFile.Delete(sNormB);
  TFile.Delete(sTempRes);
end;

{ --- Operação Principal: SUBTRAÇÃO --- }

procedure SwapSub(const sFileA, sFileB, sFileRes: String);
var
  InfoA, InfoB: TNumInfo;
  iMaxInt, iMaxDec: Int64;
  sNormA, sNormB, sTempRes: String;
  fsA, fsB, fsRes: TFileStream;
  iPos, iTotal: Int64;
  cDigitA, cDigitB, cRes: Char;
  iSub, iBorrow: Integer;
begin
  // Nota: Consideramos A >= B nesta lógica simplificada de swap.
  // Para suporte a negativos, usaríamos o ADN da unit sMath.pas
  InfoA := GetNumInfo(sFileA);
  InfoB := GetNumInfo(sFileB);

  iMaxInt := Max(InfoA.IntLen, InfoB.IntLen);
  iMaxDec := Max(InfoA.DecLen, InfoB.DecLen);

  sNormA := sFileA + '.norm';
  sNormB := sFileB + '.norm';
  sTempRes := sFileRes + '.tmp';

  CreateNormalizedFile(sFileA, sNormA, iMaxInt, iMaxDec);
  CreateNormalizedFile(sFileB, sNormB, iMaxInt, iMaxDec);

  fsA := TFileStream.Create(sNormA, fmOpenRead);
  fsB := TFileStream.Create(sNormB, fmOpenRead);
  fsRes := TFileStream.Create(sTempRes, fmCreate);
  try
    iBorrow := 0;
    iTotal := fsA.Size;
    for iPos := iTotal - 1 downto 0 do
    begin
      if (iPos mod 1000 = 0) and Assigned(OnProgress) then
        OnProgress(iTotal - iPos, iTotal);

      fsA.Position := iPos;
      fsB.Position := iPos;
      fsA.Read(cDigitA, 1);
      fsB.Read(cDigitB, 1);

      if cDigitA = cDecimalSeparator then
      begin
        fsRes.Write(cDecimalSeparator, 1);
        Continue;
      end;

      iSub := (Ord(cDigitA) - Ord('0')) - (Ord(cDigitB) - Ord('0')) - iBorrow;
      if iSub < 0 then
      begin
        iSub := iSub + 10;
        iBorrow := 1;
      end
      else
        iBorrow := 0;

      cRes := Char(iSub + Ord('0'));
      fsRes.Write(cRes, 1);
    end;
  finally
    fsA.Free;
    fsB.Free;
    fsRes.Free;
  end;

  ReverseFile(sTempRes, sFileRes);
  TFile.Delete(sNormA);
  TFile.Delete(sNormB);
  TFile.Delete(sTempRes);
procedure SwapMultiplyDigit(const sFileIn, sFileRes: String; iDigit: Integer; iShift: Integer);
var
  fsIn, fsRes: TFileStream;
  i: Int64;
  cDigit, cRes: Char;
  iProd, iCarry: Integer;
begin
  fsIn := TFileStream.Create(sFileIn, fmOpenRead);
  fsRes := TFileStream.Create(sFileRes + '.tmp', fmCreate);
  try
    iCarry := 0;
    // Adicionar zeros de shift (da direita para a esquerda, serao invertidos depois)
    for i := 1 to iShift do
    begin
      cRes := '0';
      fsRes.Write(cRes, 1);
    end;

    for i := fsIn.Size - 1 downto 0 do
    begin
      fsIn.Position := i;
      fsIn.Read(cDigit, 1);
      if cDigit = cDecimalSeparator then Continue;

      iProd := (Ord(cDigit) - 48) * iDigit + iCarry;
      iCarry := iProd div 10;
      cRes := Char((iProd mod 10) + 48);
      fsRes.Write(cRes, 1);
    end;
    if iCarry > 0 then
    begin
      cRes := Char(iCarry + 48);
      fsRes.Write(cRes, 1);
    end;
  finally
    fsIn.Free;
    fsRes.Free;
  end;
  ReverseFile(sFileRes + '.tmp', sFileRes);
  TFile.Delete(sFileRes + '.tmp');
end;

procedure SwapMultiply(const sFileA, sFileB, sFileRes: String);
var
  InfoA, InfoB: TNumInfo;
  fsB: TFileStream;
  i, iShift, iTotalDecs: Integer;
  cDigit: Char;
  sTempAcc, sTempDigit, sZero: String;
begin
  InfoA := GetNumInfo(sFileA);
  InfoB := GetNumInfo(sFileB);
  iTotalDecs := Integer(InfoA.DecLen + InfoB.DecLen);

  sZero := ExtractFilePath(sFileRes) + 'zero.tmp';
  TFile.WriteAllText(sZero, '0');

  sTempAcc := sFileRes + '.acc';
  TFile.Copy(sZero, sTempAcc, True);

  fsB := TFileStream.Create(sFileB, fmOpenRead);
  try
    iShift := 0;
    for i := fsB.Size - 1 downto 0 do
    begin
      fsB.Position := i;
      fsB.Read(cDigit, 1);
      if cDigit = cDecimalSeparator then Continue;
      
      if cDigit <> '0' then
      begin
        sTempDigit := sFileRes + '.digit';
        SwapMultiplyDigit(sFileA, sTempDigit, Ord(cDigit) - 48, iShift);
        SwapSum(sTempAcc, sTempDigit, sTempAcc + '.new');
        TFile.Delete(sTempAcc);
        TFile.Delete(sTempDigit);
        RenameFile(sTempAcc + '.new', sTempAcc);
      end;
      Inc(iShift);
    end;
  finally
    fsB.Free;
  end;

  // Tratar decimais no final (inserir separador na posicao correta)
  // ... (Logica de limpeza e posicionamento de decimal)
  TFile.Copy(sTempAcc, sFileRes, True);
  TFile.Delete(sTempAcc);
  TFile.Delete(sZero);
function SwapCompare(const sFileA, sFileB: String): Integer;
var
  InfoA, InfoB: TNumInfo;
  sNormA, sNormB: String;
  fsA, fsB: TFileStream;
  i: Int64;
  cA, cB: Char;
begin
  InfoA := GetNumInfo(sFileA);
  InfoB := GetNumInfo(sFileB);
  
  sNormA := sFileA + '.cmpA';
  sNormB := sFileB + '.cmpB';
  CreateNormalizedFile(sFileA, sNormA, Max(InfoA.IntLen, InfoB.IntLen), Max(InfoA.DecLen, InfoB.DecLen));
  CreateNormalizedFile(sFileB, sNormB, Max(InfoA.IntLen, InfoB.IntLen), Max(InfoA.DecLen, InfoB.DecLen));

  Result := 0;
  fsA := TFileStream.Create(sNormA, fmOpenRead);
  fsB := TFileStream.Create(sNormB, fmOpenRead);
  try
    for i := 0 to fsA.Size - 1 do
    begin
      fsA.Read(cA, 1);
      fsB.Read(cB, 1);
      if cA > cB then begin Result := 1; Break; end;
      if cA < cB then begin Result := -1; Break; end;
    end;
  finally
    fsA.Free;
    fsB.Free;
    TFile.Delete(sNormA);
    TFile.Delete(sNormB);
  end;
end;

procedure SwapDivide(const sFileA, sFileB, sFileRes: String);
var
  sQuot, sCurr, sTemp: String;
  iCount, i: Integer;
  fsA: TFileStream;
  cDigit: Char;
begin
  // Divisao Longa em Disco (ADN Saiyajin)
  sQuot := sFileRes + '.quot';
  sCurr := sFileRes + '.curr';
  TFile.WriteAllText(sCurr, '0');
  TFile.WriteAllText(sQuot, '');

  fsA := TFileStream.Create(sFileA, fmOpenRead);
  try
    for i := 0 to fsA.Size - 1 do
    begin
      fsA.Position := i;
      fsA.Read(cDigit, 1);
      if cDigit = cDecimalSeparator then Continue;

      // sCurr := sCurr + cDigit
      sTemp := sCurr + '.new';
      if TFile.ReadAllText(sCurr) = '0' then TFile.WriteAllText(sTemp, cDigit)
      else TFile.WriteAllText(sTemp, TFile.ReadAllText(sCurr) + cDigit);
      TFile.Delete(sCurr);
      RenameFile(sTemp, sCurr);

      iCount := 0;
      while SwapCompare(sCurr, sFileB) >= 0 do
      begin
        sTemp := sCurr + '.sub';
        SwapSub(sCurr, sFileB, sTemp);
        TFile.Delete(sCurr);
        RenameFile(sTemp, sCurr);
        Inc(iCount);
      end;
      
      TFile.AppendAllText(sQuot, IntToStr(iCount));
    end;
  finally
    fsA.Free;
  end;

  TFile.Copy(sQuot, sFileRes, True);
  TFile.Delete(sQuot);
  TFile.Delete(sCurr);
end;

end.

