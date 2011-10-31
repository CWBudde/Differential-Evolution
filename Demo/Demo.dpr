program Demo;

uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {FmDifferentialEvolution};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFmDifferentialEvolution, FmDifferentialEvolution);
  Application.Run;
end.

