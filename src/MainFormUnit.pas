// [xx.xx.2006] Ruzzz <ruzzzua@gmail.com>
// [07.10.2010] Небольшая реанимация :)

unit MainFormUnit;

interface

uses
  Windows, Forms, ExtCtrls, Controls, StdCtrls, Classes, Graphics, SysUtils,
  Buttons, Menus, Clipbrd, XPMan;

const
  DEFAULT_RATIO = 10;
  SCREENSHOT_HINT = '[Drag Me]';

type
  TMainForm = class(TForm)
    // GUI
    FCoolBevel: TBevel;
    FColorPanel: TShape;
    FTimer: TTimer;
    FCapturedImage: TImage;
    FRatioLabel: TLabel;
    TrayIcon: TTrayIcon;
    TrayPopupMenu: TPopupMenu;
    TrayItemExit: TMenuItem;
    CopyButton: TSpeedButton;
    FInfoText: TLabel;
    XPManifest: TXPManifest;
    procedure FTimerTimer(Sender: TObject);
    procedure FCapturedImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FCapturedImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FCapturedImageMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure TrayItemExitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TrayIconClick(Sender: TObject);
    procedure CopyButtonClick(Sender: TObject);

  private
    FRatio: Integer;
    FCaptureAreaRect: TRect;
    FCaptureAreaCenter: TPoint;
    FIsCapture,
    FIsLock: Boolean;
    FIsClosing: Boolean;
    FHasShot: Boolean;
    procedure SetColor(color: TColor);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FTimerTimer(Sender: TObject);
var
  Canvas: TCanvas;
  OurWndRect, SourceRect: TRect;
  CursorPos: TPoint;
  DesktopDC: HDC;
begin
  if FIsLock or IsIconic(Application.Handle) then Exit;
  FIsLock := true;
  try
    // Cursor over our window? 
    GetCursorPos(CursorPos);
    GetWindowRect(self.Handle, OurWndRect);
    if PtInRect(OurWndRect, CursorPos) then Exit;

    // Calc area of screen for capture
    SourceRect := Rect(CursorPos.X, CursorPos.Y, CursorPos.X, CursorPos.Y);
    InflateRect(SourceRect, Round(FCaptureAreaCenter.X / FRatio),
      Round(FCaptureAreaCenter.Y / FRatio));

    // Иногда остаются пустые области
    FCapturedImage.Canvas.FillRect(FCaptureAreaRect);
    Canvas := TCanvas.Create;
    try
      DesktopDC := GetDC(0);
      try
        Canvas.Handle := DesktopDC;
        FCapturedImage.Canvas.CopyRect(FCaptureAreaRect, Canvas, SourceRect);
        FHasShot := True;
        SetColor(FCapturedImage.Canvas.Pixels[Round(FCaptureAreaCenter.X),
          Round(FCaptureAreaCenter.Y)]);
      finally
        ReleaseDC(0, DesktopDC);
      end;
    finally
      Canvas.Free;
    end;
  finally
    FIsLock := false;
  end;
  Application.ProcessMessages;
end;

procedure TMainForm.CopyButtonClick(Sender: TObject);
begin
  Clipboard.SetTextBuf(PChar(FInfoText.Caption));
end;

procedure TMainForm.FCapturedImageMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  isInsideClientArea: Boolean;
begin
  if Button <> mbLeft then Exit;
  if FHasShot then
  begin
    isInsideClientArea := PtInRect(FCaptureAreaRect, Point(X, Y));
    if isInsideClientArea then
      SetColor(FCapturedImage.Canvas.Pixels[X, Y]);
  end;
  FIsCapture := true;
  FTimer.Enabled := true;
end;

procedure TMainForm.FCapturedImageMouseUp(Sender: TObject; Button:
  TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (not FIsCapture) or (Button <> mbLeft) then Exit;
  FTimer.Enabled := false;
  FIsCapture := false;
end;

procedure TMainForm.FCapturedImageMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  isInsideClientArea: Boolean;
begin
  if FHasShot then
  begin
    isInsideClientArea := PtInRect(FCaptureAreaRect, Point(X, Y));
    if FIsCapture and isInsideClientArea then
      SetColor(FCapturedImage.Canvas.Pixels[X, Y]);
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FIsClosing;
  if not CanClose then
  begin
    Application.Minimize;
    Hide;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  X, Y: Integer;
  HelpText: String;
begin
  FHasShot := False;
  FIsClosing := False;
  FRatio := DEFAULT_RATIO;
  FCaptureAreaRect := Rect(0, 0, FCapturedImage.Width, FCapturedImage.Height);
  X := Round((FCaptureAreaRect.Right - FCaptureAreaRect.Left) / 2);
  Y := Round((FCaptureAreaRect.Bottom - FCaptureAreaRect.Top) / 2);
  FCaptureAreaCenter := Point(X, Y);

  Self.DoubleBuffered := true;
  FCapturedImage.Canvas.FillRect(Rect(0, 0, FCapturedImage.Width,
    FCapturedImage.Height));

  HelpText := SCREENSHOT_HINT;
  FCapturedImage.Canvas.TextOut(
    FCaptureAreaCenter.X - FCapturedImage.Canvas.TextWidth(HelpText) div 2,
    FCaptureAreaCenter.Y - FCapturedImage.Canvas.TextHeight(HelpText) div 2,
    HelpText);

  FRatioLabel.Caption := 'x' + IntToStr(FRatio);
end;

procedure TMainForm.SetColor(color: TColor);
var
  R, G, B: String;
begin
  FColorPanel.Brush.Color := color;
  R := IntToHex(GetRValue(color), 2);
  G := IntToHex(GetGValue(color), 2);
  B := IntToHex(GetBValue(color), 2);
  FInfoText.Caption := R + G + B;
end;

procedure TMainForm.TrayIconClick(Sender: TObject);
begin
  if Visible then
  begin
    Application.Minimize;
    Hide;
  end
  else
  begin
    Show;
    Application.Restore;
  end;
end;

procedure TMainForm.TrayItemExitClick(Sender: TObject);
begin
  FIsClosing := True;
  Close;
end;

procedure TMainForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta > 0 then Inc(FRatio) else Dec(FRatio);
  if FRatio < 1 then FRatio := 1
  else if FRatio > 25 then FRatio := 25;
  FRatioLabel.Caption := 'x' + IntToStr(FRatio);
end;

end.
