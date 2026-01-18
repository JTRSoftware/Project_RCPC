unit sSwapMath;

{$mode delphi}

interface

uses
  SysUtils, Classes, Math;

type
  TNumInfo = record
    IntLen: Int64;
    DecLen: Int64;
    HasDec: Boolean;
    TotalLen: Int64;
  end;

  TProgressCallback = procedure(const iPos, iTotal: Int64) of object;

procedure SwapSum(const sFileA, sFileB, sFileRes: String);
procedure SwapSub(const sFileA, sFileB, sFileRes: String);
procedure SwapMultiply(const sFileA, sFileB, sFileRes: String);
procedure SwapDivide(const sFileA, sFileB, sFileRes: String);

var
  cDecimalSeparator: Char = '.';
  iBufferSize: Integer = 1024 * 512; 
  OnProgress: TProgressCallback = nil;

implementation

{ --- Auxiliares de Análise --- }

function GetNumInfo(const sFile: String): TNumInfo;
var
  fs: TFileStream;
  buffer: array[0..65535] of Byte;
  iRead, i: Integer;
  iDecPos: Int64;
begin
  Result.IntLen := 0;
  Result.DecLen := 0;
  Result.HasDec := False;
  Result.TotalLen := 0;
  
  if not FileExists(sFile) then Exit;
  
  fs := TFileStream.Create(sFile, fmOpenRead or fmShareDenyNone);
  try
    Result.TotalLen := fs.Size;
    iDecPos := -1;
    while fs.Position < fs.Size do
    begin
      iRead := fs.Read(buffer[0], SizeOf(buffer));
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

procedure ReverseFile(const sSource, sDest: String);
var
  fsIn, fsOut: TFileStream;
  buffer, revBuffer: array of Byte;
  iRead, i: Integer;
  iTotalBlocks: Int64;
  iRemainder: Integer;
begin
  fsIn := TFileStream.Create(sSource, fmOpenRead);
  fsOut := TFileStream.Create(sDest, fmCreate);
  try
    SetLength(buffer, iBufferSize);
    SetLength(revBuffer, iBufferSize);
    iTotalBlocks := fsIn.Size div iBufferSize;
    iRemainder := fsIn.Size mod iBufferSize;

    if iRemainder > 0 then
    begin
      fsIn.Position := fsIn.Size - iRemainder;
      fsIn.Read(buffer[0], iRemainder);
      for i := 0 to iRemainder - 1 do
        revBuffer[i] := buffer[iRemainder - 1 - i];
      fsOut.Write(revBuffer[0], iRemainder);
    end;

    for i := iTotalBlocks - 1 downto 0 do
    begin
      fsIn.Position := Int64(i) * iBufferSize;
      fsIn.Read(buffer[0], iBufferSize);
      for iRead := 0 to iBufferSize - 1 do
        revBuffer[iRead] := buffer[iBufferSize - 1 - iRead];
      fsOut.Write(revBuffer[0], iBufferSize);
    end;
  finally
    fsIn.Free;
    fsOut.Free;
  end;
end;

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
      iRead := fsIn.Read(buffer[0], Min(Int64(iBufferSize), Info.IntLen - i));
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
        iRead := fsIn.Read(buffer[0], Min(Int64(iBufferSize), Info.DecLen - i));
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

function SwapCompare(const sFileA, sFileB: String): Integer;
var
  InfoA, InfoB: TNumInfo;
  fsA, fsB: TFileStream;
  cA, cB: Char;
  iPos: Int64;
begin
  InfoA := GetNumInfo(sFileA);
  InfoB := GetNumInfo(sFileB);
  
  if InfoA.IntLen > InfoB.IntLen then Exit(1);
  if InfoA.IntLen < InfoB.IntLen then Exit(-1);
  
  fsA := TFileStream.Create(sFileA, fmOpenRead);
  fsB := TFileStream.Create(sFileB, fmOpenRead);
  try
    for iPos := 0 to InfoA.IntLen - 1 do
    begin
      fsA.Read(cA, 1);
      fsB.Read(cB, 1);
      if cA > cB then Exit(1);
      if cA < cB then Exit(-1);
    end;
    for iPos := 1 to Max(InfoA.DecLen, InfoB.DecLen) do
    begin
      cA := '0'; cB := '0';
      if iPos <= InfoA.DecLen then begin fsA.Position := InfoA.IntLen + iPos; fsA.Read(cA, 1); end;
      if iPos <= InfoB.DecLen then begin fsB.Position := InfoB.IntLen + iPos; fsB.Read(cB, 1); end;
      if cA > cB then Exit(1);
      if cA < cB then Exit(-1);
    end;
    Result := 0;
  finally
    fsA.Free;
    fsB.Free;
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
    iCarry := 0; iTotal := fsA.Size;
    for iPos := iTotal - 1 downto 0 do
    begin
      fsA.Position := iPos; fsB.Position := iPos;
      fsA.Read(cDigitA, 1); fsB.Read(cDigitB, 1);
      if cDigitA = cDecimalSeparator then begin fsRes.Write(cDecimalSeparator, 1); Continue; end;
      iSum := (Ord(cDigitA) - 48) + (Ord(cDigitB) - 48) + iCarry;
      iCarry := iSum div 10;
      cRes := Char((iSum mod 10) + 48);
      fsRes.Write(cRes, 1);
    end;
    if iCarry > 0 then begin cRes := Char(iCarry + 48); fsRes.Write(cRes, 1); end;
  finally
    fsA.Free; fsB.Free; fsRes.Free;
  end;
  ReverseFile(sTempRes, sFileRes);
  DeleteFile(sNormA); DeleteFile(sNormB); DeleteFile(sTempRes);
end;

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
    iBorrow := 0; iTotal := fsA.Size;
    for iPos := iTotal - 1 downto 0 do
    begin
      fsA.Position := iPos; fsB.Position := iPos;
      fsA.Read(cDigitA, 1); fsB.Read(cDigitB, 1);
      if cDigitA = cDecimalSeparator then begin fsRes.Write(cDecimalSeparator, 1); Continue; end;
      iSub := (Ord(cDigitA) - 48) - (Ord(cDigitB) - 48) - iBorrow;
      if iSub < 0 then begin iSub := iSub + 10; iBorrow := 1; end else iBorrow := 0;
      cRes := Char(iSub + 48);
      fsRes.Write(cRes, 1);
    end;
  finally
    fsA.Free; fsB.Free; fsRes.Free;
  end;
  ReverseFile(sTempRes, sFileRes);
  DeleteFile(sNormA); DeleteFile(sNormB); DeleteFile(sTempRes);
end;

procedure SwapMultiplyDigit(const sFileIn, sFileRes: String; iDigit: Integer; iShift: Int64);
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
    for i := 1 to iShift do begin cRes := '0'; fsRes.Write(cRes, 1); end;
    for i := fsIn.Size - 1 downto 0 do
    begin
      fsIn.Position := i; fsIn.Read(cDigit, 1);
      if cDigit = cDecimalSeparator then Continue;
      iProd := (Ord(cDigit) - 48) * iDigit + iCarry;
      iCarry := iProd div 10;
      cRes := Char((iProd mod 10) + 48);
      fsRes.Write(cRes, 1);
    end;
    if iCarry > 0 then begin cRes := Char(iCarry + 48); fsRes.Write(cRes, 1); end;
  finally
    fsIn.Free; fsRes.Free;
  end;
  ReverseFile(sFileRes + '.tmp', sFileRes);
  DeleteFile(sFileRes + '.tmp');
end;

procedure SwapMultiply(const sFileA, sFileB, sFileRes: String);
var
  fsB: TFileStream;
  i: Int64;
  iShift: Int64;
  cDigit: Char;
  sAcc, sDigitPart, sTempNew: String;
  InfoA, InfoB: TNumInfo;
  iTotalDecs: Int64;
  SL: TStringList;
begin
  InfoA := GetNumInfo(sFileA);
  InfoB := GetNumInfo(sFileB);
  iTotalDecs := InfoA.DecLen + InfoB.DecLen;

  sAcc := sFileRes + '.acc';
  SL := TStringList.Create;
  try
    SL.Text := '0';
    SL.SaveToFile(sAcc);
  finally
    SL.Free;
  end;

  fsB := TFileStream.Create(sFileB, fmOpenRead);
  try
    iShift := 0;
    for i := fsB.Size - 1 downto 0 do
    begin
      fsB.Position := i; fsB.Read(cDigit, 1);
      if cDigit = cDecimalSeparator then Continue;
      if cDigit <> '0' then
      begin
        sDigitPart := sFileRes + '.digit';
        SwapMultiplyDigit(sFileA, sDigitPart, Ord(cDigit) - 48, iShift);
        sTempNew := sFileRes + '.new';
        SwapSum(sAcc, sDigitPart, sTempNew);
        DeleteFile(sAcc); DeleteFile(sDigitPart);
        RenameFile(sTempNew, sAcc);
      end;
      Inc(iShift);
    end;
  finally
    fsB.Free;
  end;
  
  if FileExists(sFileRes) then DeleteFile(sFileRes);
  RenameFile(sAcc, sFileRes);
end;

procedure SwapDivide(const sFileA, sFileB, sFileRes: String);
var
  fsA, fsQ: TFileStream;
  i: Int64;
  cDigit: Char;
  sCurr, sQuot, sSub, sTemp: String;
  iCount: Integer;
  SL: TStringList;
begin
  sCurr := sFileRes + '.curr';
  sQuot := sFileRes + '.quot';
  SL := TStringList.Create;
  try
    SL.Text := '0'; SL.SaveToFile(sCurr);
    SL.Text := ''; SL.SaveToFile(sQuot);
  finally
    SL.Free;
  end;

  fsA := TFileStream.Create(sFileA, fmOpenRead);
  fsQ := TFileStream.Create(sQuot, fmOpenWrite);
  try
    for i := 0 to fsA.Size - 1 do
    begin
      fsA.Position := i; fsA.Read(cDigit, 1);
      if cDigit = cDecimalSeparator then Continue;

      sTemp := sCurr + '.tmp';
      // Manual append using TStringList or Streams for safety
      SL := TStringList.Create;
      try
        SL.LoadFromFile(sCurr);
        if SL.Text = '0' then SL.Text := cDigit
        else SL.Text := SL.Text + cDigit;
        SL.SaveToFile(sTemp);
      finally
        SL.Free;
      end;
      DeleteFile(sCurr); RenameFile(sTemp, sCurr);

      iCount := 0;
      while SwapCompare(sCurr, sFileB) >= 0 do
      begin
        sSub := sCurr + '.sub';
        SwapSub(sCurr, sFileB, sSub);
        DeleteFile(sCurr); RenameFile(sSub, sCurr);
        Inc(iCount);
      end;
      cDigit := Char(iCount + 48);
      fsQ.Write(cDigit, 1);
    end;
  finally
    fsA.Free; fsQ.Free;
  end;
  if FileExists(sFileRes) then DeleteFile(sFileRes);
  RenameFile(sQuot, sFileRes);
  DeleteFile(sCurr);
end;

end.
