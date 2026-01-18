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
// procedure SwapSub(const sFileA, sFileB, sFileRes: String);

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
// ... (manteve-se igual)

{ --- Normalização --- }

// ... (manteve-se igual)

{ --- Operação Principal: SOMA --- }

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
end;


end.

