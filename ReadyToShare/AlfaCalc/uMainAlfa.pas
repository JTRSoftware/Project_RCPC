unit uMainAlfa;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  sMath, sHexMath, sAlfaMath, sSwapMath, sHexSwapMath, sAlfaSwapMath;

type

  { TfrmAlfaCalc }

  TfrmAlfaCalc = class(TForm)
    chkAlfadecimal: TCheckBox;
    chkDecimal: TCheckBox;
    chkHexaDecimal: TCheckBox;
    chkUseSwap: TCheckBox;
    chkAutoConvert: TCheckBox;
    lblDisplayAlfa: TEdit;
    lblDisplayDecimal: TEdit;
    lblDisplayHex: TEdit;
    lblOp: TLabel;
    mHistory: TMemo;
    pchkAlfaDecimal: TPanel;
    pchkDecimal: TPanel;
    pchkHexaDecimal: TPanel;
    pchkUseSwap: TPanel;
    pchkAutoConvert: TPanel;
    pnlDisplay: TPanel;
    pnlButtons: TPanel;
    // Operadores
    btnPlus: TButton;
    btnMinus: TButton;
    btnMult: TButton;
    btnDiv: TButton;
    btnEqual: TButton;
    btnClear: TButton;
    btnDot: TButton;
    // Digitos 0-9
    btn0, btn1, btn2, btn3, btn4, btn5, btn6, btn7, btn8, btn9: TButton;
    // Letras A-Z
    btnA, btnB, btnC, btnD, btnE, btnF, btnG, btnH, btnI, btnJ, btnK,
    btnL, btnM, btnN, btnO, btnP, btnQ, btnR, btnS, btnT, btnU, btnV,
    btnW, btnX, btnY, btnZ: TButton;

    procedure btnAlfaClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnOpClick(Sender: TObject);
    procedure btnEqualClick(Sender: TObject);
    procedure chkDecimalClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    sValA: string;
    sValB: string;
    sOp: string;
    bNewVal: boolean;
    FUpdating: boolean; // Flag para evitar recursividade nas CheckBoxes
    procedure UpdateDisplay(sV: string);
    procedure AddChar(const C: char);
    procedure SetOp(const Op: string);
    procedure ExecuteEqual;
    procedure UpdateButtonState;
    function ExecuteSwapOp(sA, sB, Op: string): string;
  public

  end;

var
  frmAlfaCalc: TfrmAlfaCalc;

implementation

{$R *.lfm}

procedure TfrmAlfaCalc.FormCreate(Sender: TObject);
begin
  Self.Color := $1A1A1A;
  Self.KeyPreview := True; // Ativa a deteção de teclas no formulário
  FUpdating := False;      // Inicializa a flag
  sValA := '0';
  sOp := '';
  bNewVal := True;
  UpdateDisplay('0');
  lblOp.Caption := '';
  mHistory.Lines.Clear;

  // Define o estilo Bold inicial (Decimal é o padrão)
  lblDisplayDecimal.Font.Style := [fsBold];
  lblDisplayHex.Font.Style := [];
  lblDisplayAlfa.Font.Style := [];

  UpdateButtonState;
end;

procedure TfrmAlfaCalc.UpdateButtonState;
var
  i: integer;
  btn: TButton;
begin
  // Desativa botoes conforme a escala
  for i := 0 to pnlButtons.ControlCount - 1 do
  begin
    if pnlButtons.Controls[i] is TButton then
    begin
      btn := TButton(pnlButtons.Controls[i]);
      if (Length(btn.Caption) = 1) and (btn.Caption[1] in ['A'..'Z']) then
      begin
        if chkDecimal.Checked then btn.Enabled := False
        else if chkHexaDecimal.Checked then btn.Enabled := (btn.Caption[1] <= 'F')
        else
          btn.Enabled := True;
      end;
    end;
  end;
end;

function TfrmAlfaCalc.ExecuteSwapOp(sA, sB, Op: string): string;
var
  sFileA, sFileB, sFileRes: string;
  f: TFileStream;
begin
  sFileA := GetTempFileName('', 'A');
  sFileB := GetTempFileName('', 'B');
  sFileRes := GetTempFileName('', 'R');

  f := TFileStream.Create(sFileA, fmCreate);
  f.Write(sA[1], Length(sA));
  f.Free;
  f := TFileStream.Create(sFileB, fmCreate);
  f.Write(sB[1], Length(sB));
  f.Free;

  if chkDecimal.Checked then
  begin
    if Op = '+' then SwapSum(sFileA, sFileB, sFileRes)
    else if Op = '-' then SwapSub(sFileA, sFileB, sFileRes);
  end
  else if chkHexaDecimal.Checked then
  begin
    if Op = '+' then HexSwapSum(sFileA, sFileB, sFileRes)
    else if Op = '-' then HexSwapSub(sFileA, sFileB, sFileRes);
  end
  else
  begin
    if Op = '+' then AlfaSwapSum(sFileA, sFileB, sFileRes)
    else if Op = '-' then AlfaSwapSub(sFileA, sFileB, sFileRes);
  end;

  f := TFileStream.Create(sFileRes, fmOpenRead);
  SetLength(Result, f.Size);
  f.Read(Result[1], f.Size);
  f.Free;

  DeleteFile(sFileA);
  DeleteFile(sFileB);
  DeleteFile(sFileRes);
end;

procedure TfrmAlfaCalc.UpdateDisplay(sV: string);
var
  sDec, sHex, sAlfa: string;
begin
  // Por defeito, os displays inativos ficam com o sinal de proibido
  sDec  := '🚫';
  sHex  := '🚫';
  sAlfa := '🚫';

  // Determina o valor conforme a escala ativa e se a conversão automática está ligada
  if chkDecimal.Checked then
  begin
    sDec := sV;
    if chkAutoConvert.Checked then
    begin
      sHex  := DecToHex(sDec);
      sAlfa := DecToAlfa(sDec);
    end;
  end
  else if chkHexaDecimal.Checked then
  begin
    sHex := sV;
    if chkAutoConvert.Checked then
    begin
      sDec  := HexToDec(sHex);
      sAlfa := DecToAlfa(sDec);
    end;
  end
  else // Alfadecimal
  begin
    sAlfa := sV;
    if chkAutoConvert.Checked then
    begin
      sDec := AlfaToDec(sAlfa);
      sHex := DecToHex(sDec);
    end;
  end;

  // Atualiza os 3 displays
  lblDisplayDecimal.Text := sDec;
  lblDisplayHex.Text     := sHex;
  lblDisplayAlfa.Text    := sAlfa;

  // Garante que o cursor está no fim
  lblDisplayDecimal.SelStart := Length(lblDisplayDecimal.Text);
  lblDisplayHex.SelStart := Length(lblDisplayHex.Text);
  lblDisplayAlfa.SelStart := Length(lblDisplayAlfa.Text);
end;

procedure TfrmAlfaCalc.AddChar(const C: char);
var
  upC: char;
begin
  upC := UpCase(C);
  // Aceita 0-9, A-Z e o separador decimal
  if not ((upC in ['0'..'9', 'A'..'Z']) or (C = cDecimalSeparator) or (C = ',')) then
    Exit;

  if (C = ',') then upC := cDecimalSeparator
  else
    upC := upC;

  // Validar se o carater pertence à escala selecionada (Catch Key Protection)
  if (upC in ['A'..'Z']) then
  begin
    if chkDecimal.Checked then Exit;
    if chkHexaDecimal.Checked and (upC > 'F') then Exit;
  end;

  // Impedir múltiplos separadores decimais
  if (upC = cDecimalSeparator) and (not bNewVal) then
  begin
    if chkDecimal.Checked and (Pos(cDecimalSeparator, lblDisplayDecimal.Text) > 0) then Exit;
    if chkHexaDecimal.Checked and (Pos(cDecimalSeparator, lblDisplayHex.Text) > 0) then Exit;
    if chkAlfadecimal.Checked and (Pos(cDecimalSeparator, lblDisplayAlfa.Text) > 0) then Exit;
  end;

  if bNewVal then
  begin
    UpdateDisplay(upC);
    bNewVal := False;
  end
  else
  begin
    // Obtém o valor atual do display correspondente à escala ativa
    if chkDecimal.Checked then UpdateDisplay(lblDisplayDecimal.Text + upC)
    else if chkHexaDecimal.Checked then UpdateDisplay(lblDisplayHex.Text + upC)
    else
      UpdateDisplay(lblDisplayAlfa.Text + upC);
  end;
end;

procedure TfrmAlfaCalc.SetOp(const Op: string);
begin
  // Se já temos uma operação pendente (sOp) e o utilizador já digitou o segundo valor (bNewVal = False),
  // calculamos o resultado intermédio antes de definir o novo operador.
  if (sOp <> '') and (not bNewVal) then
    ExecuteEqual;

  if chkDecimal.Checked then sValA := lblDisplayDecimal.Text
  else if chkHexaDecimal.Checked then sValA := lblDisplayHex.Text
  else
    sValA := lblDisplayAlfa.Text;

  sOp := Op;
  lblOp.Caption := sOp;
  bNewVal := True;

  // Bloqueia mudança de escala durante o cálculo
  chkDecimal.Enabled := False;
  chkHexaDecimal.Enabled := False;
  chkAlfadecimal.Enabled := False;
end;

procedure TfrmAlfaCalc.ExecuteEqual;
var
  sRes: string;
  StartTime: QWord;
  TotalTime: Double;
begin
  if sOp = '' then Exit;

  if chkDecimal.Checked then sValB := lblDisplayDecimal.Text
  else if chkHexaDecimal.Checked then sValB := lblDisplayHex.Text
  else
    sValB := lblDisplayAlfa.Text;

  StartTime := GetTickCount64; // Início do cronómetro
  sRes := '0';
  if chkUseSwap.Checked and ((sOp = '+') or (sOp = '-')) then
  begin
    sRes := ExecuteSwapOp(sValA, sValB, sOp);
  end
  else if chkDecimal.Checked then
  begin
    if sOp = '+' then sRes := sMath.Sum(sValA, sValB)
    else if sOp = '-' then sRes := sMath.Sub(sValA, sValB)
    else if sOp = '*' then sRes := sMath.Multiply(sValA, sValB)
    else if sOp = '/' then sRes := sMath.Divide(sValA, sValB);
  end
  else if chkHexaDecimal.Checked then
  begin
    if sOp = '+' then sRes := HexSum(sValA, sValB)
    else if sOp = '-' then sRes := HexSub(sValA, sValB)
    else if sOp = '*' then sRes := HexMultiply(sValA, sValB)
    else if sOp = '/' then sRes := HexDivide(sValA, sValB);
  end
  else
  begin
    if sOp = '+' then sRes := AlfaSum(sValA, sValB)
    else if sOp = '-' then sRes := AlfaSub(sValA, sValB)
    else if sOp = '*' then sRes := AlfaMultiply(sValA, sValB)
    else if sOp = '/' then sRes := AlfaDivide(sValA, sValB);
  end;
  TotalTime := (GetTickCount64 - StartTime) / 1000.0; // Tempo em segundos

  // Regista no histórico
  mHistory.Lines.Add(Format('%s %s %s = %s', [sValA, sOp, sValB, sRes]));
  mHistory.Lines.Add(Format('(Tempo: %n s)', [TotalTime]));
  mHistory.Lines.Add(''); // Linha vazia como solicitado
  mHistory.SelStart := Length(mHistory.Text);

  UpdateDisplay(sRes);

  // O segredo para manter o resultado:
  // sValA passa a ser o resultado para permitir continuar a operação
  sValA := sRes;
  bNewVal := True;
  lblOp.Caption := Format('= (%n s)', [TotalTime]);
  sOp := '';
end;

procedure TfrmAlfaCalc.btnAlfaClick(Sender: TObject);
begin
  if Sender is TButton then AddChar(TButton(Sender).Caption[1]);
end;

procedure TfrmAlfaCalc.btnClearClick(Sender: TObject);
begin
  sValA := '0';
  sOp := '';
  bNewVal := True;
  UpdateDisplay('0');
  lblOp.Caption := '';
  
  // Re-habilita a mudança de escala
  chkDecimal.Enabled := True;
  chkHexaDecimal.Enabled := True;
  chkAlfadecimal.Enabled := True;
end;

procedure TfrmAlfaCalc.btnOpClick(Sender: TObject);
begin
  if Sender is TButton then SetOp(TButton(Sender).Caption);
end;

procedure TfrmAlfaCalc.btnEqualClick(Sender: TObject);
begin
  ExecuteEqual;
end;

procedure TfrmAlfaCalc.chkDecimalClick(Sender: TObject);
var
  sDecValue: string;
  sNewValue: string;
begin
  if FUpdating then Exit;
  if Sender = chkUseSwap then Exit;

  // Se o click foi no AutoConvert, só precisamos de atualizar o que está no ecrã
  if Sender = chkAutoConvert then
  begin
    if lblDisplayDecimal.Font.Style = [fsBold] then UpdateDisplay(lblDisplayDecimal.Text)
    else if lblDisplayHex.Font.Style = [fsBold] then UpdateDisplay(lblDisplayHex.Text)
    else UpdateDisplay(lblDisplayAlfa.Text);
    Exit;
  end;

  FUpdating := True;
  try
    // 1. Antes de mudar, obtemos a "Verdade Decimal" do que está no ecrã
    // Nota: O display com Bold NUNCA terá o símbolo 🚫
    if lblDisplayDecimal.Font.Style = [fsBold] then sDecValue := lblDisplayDecimal.Text
    else if lblDisplayHex.Font.Style = [fsBold] then sDecValue := HexToDec(lblDisplayHex.Text)
    else sDecValue := AlfaToDec(lblDisplayAlfa.Text);

    if not TCheckBox(Sender).Checked then
    begin
      TCheckBox(Sender).Checked := True;
    end
    else
    begin
      // 2. Mudança de Escala
      if Sender <> chkDecimal then chkDecimal.Checked := False;
      if Sender <> chkHexaDecimal then chkHexaDecimal.Checked := False;
      if Sender <> chkAlfadecimal then chkAlfadecimal.Checked := False;

      // 3. Atualizar Estilos
      lblDisplayDecimal.Font.Style := [];
      lblDisplayHex.Font.Style := [];
      lblDisplayAlfa.Font.Style := [];

      if chkDecimal.Checked then lblDisplayDecimal.Font.Style := [fsBold]
      else if chkHexaDecimal.Checked then lblDisplayHex.Font.Style := [fsBold]
      else lblDisplayAlfa.Font.Style := [fsBold];

      // 4. Reset de operações pendentes
      sOp := '';
      lblOp.Caption := '';
      bNewVal := True;

      // 5. CONVERSÃO CRUCIAL: Converter a Verdade Decimal para a NOVA escala
      // Isto impede que '35' (Dec) seja lido como '35' (Hex)
      if chkDecimal.Checked then sNewValue := sDecValue
      else if chkHexaDecimal.Checked then sNewValue := DecToHex(sDecValue)
      else sNewValue := DecToAlfa(sDecValue);

      UpdateButtonState;
      UpdateDisplay(sNewValue); 
      
      sValA := sNewValue; 
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TfrmAlfaCalc.FormKeyPress(Sender: TObject; var Key: char);
begin
  case Key of
    '0'..'9', 'a'..'z', 'A'..'Z', '.', ',': AddChar(Key);
    '+', '-', '*', '/': SetOp(Key);
    '=', #13: ExecuteEqual; // #13 = Enter
  end;
end;

procedure TfrmAlfaCalc.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = 27 then btnClearClick(nil); // 27 = Escape
end;

procedure TfrmAlfaCalc.FormShow(Sender: TObject);
begin
  // Forçar escala Alfadecimal no arranque de forma segura
  chkAlfadecimal.Checked := True;
  chkDecimalClick(chkAlfadecimal);
end;

end.
