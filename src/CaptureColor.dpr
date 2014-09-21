program CaptureColor;

uses
  Forms,
  MainFormUnit in 'MainFormUnit.pas' {MainForm};

{$R *.res}

const
  AppName: String = 'Capture Color 1.0 by Ruzzz';

begin
  Application.Initialize;
  Application.Title := AppName;
  Application.CreateForm(TMainForm, MainForm);
  MainForm.Left := Screen.WorkAreaWidth - MainForm.Width - 15;
  MainForm.Top := Screen.WorkAreaHeight - MainForm.Height - 15;
  MainForm.Caption := AppName;
  Application.Run;
end.
