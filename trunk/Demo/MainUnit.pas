unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ExtCtrls, ComCtrls, TeEngine, TeeProcs, Chart, TeeFunci, Series,
  OPDE_DifferentialEvolution;

type
  TFmDifferentialEvolution = class(TForm)
    Chart: TChart;
    DifferentialEvolution: TNewDifferentialEvolution;
    MainMenu: TMainMenu;
    MiExit: TMenuItem;
    MiFile: TMenuItem;
    MiOptimization: TMenuItem;
    MiReset: TMenuItem;
    MiStart: TMenuItem;
    MiStop: TMenuItem;
    ReferenceFunction: TCustomTeeFunction;
    SeriesOptimized: TLineSeries;
    SeriesReference: TLineSeries;
    StatusBar: TStatusBar;
    MiSingleStep: TMenuItem;
    N1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure MiExitClick(Sender: TObject);
    procedure ReferenceFunctionCalculate(Sender: TCustomTeeFunction;
      const x: Double; var y: Double);
    procedure MiStartClick(Sender: TObject);
    procedure MiStopClick(Sender: TObject);
    procedure MiResetClick(Sender: TObject);
    function DECalculateCosts(Sender: TObject; Data: PDoubleArray;
      Count: Integer): Double;
    procedure DEBestCostChanged(Sender: TObject; BestCost: Double);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DEGenerationChanged(Sender: TObject;
      Generation: Integer);
    procedure MiSingleStepClick(Sender: TObject);
  end;

var
  FmDifferentialEvolution: TFmDifferentialEvolution;

implementation

uses
  Math;

{$R *.dfm}

function TestFunction(x: Double): Double;
begin
//  Result := Log10(2 + Abs(Cos(0.0131537 * x)) +  2 * Sin(0.0645 * x));
  Result := Tanh(4 * x);
end;


{ TFmDifferentialEvolution }

procedure TFmDifferentialEvolution.FormCreate(Sender: TObject);
begin
  DifferentialEvolution.NumberOfThreads := 2;
end;

procedure TFmDifferentialEvolution.DEBestCostChanged(
  Sender: TObject; BestCost: Double);
var
  x, y  : Double;
  xmax  : Double;
  xinc  : Double;
  Best  : TDEPopulationData;
begin
  Best := DifferentialEvolution.BestPopulation;
  if Assigned(Best) then
  begin
    SeriesOptimized.Clear;

    x := ReferenceFunction.StartX;
    xmax := x + ReferenceFunction.NumPoints * ReferenceFunction.Period;
    xinc := ReferenceFunction.Period;
    while x <= xmax do
    begin
      y := (((((Sqr(x) + Best.Data[0]) * Sqr(x) + Best.Data[1]) * Sqr(x) +
        Best.Data[2]) * Sqr(x) + Best.Data[3]) * Sqr(x) + Best.Data[4]) * x;
      SeriesOptimized.AddXY(x, y);
      x := x + xinc;
    end;
  end;

  StatusBar.Panels[1].Text := 'Best Cost: ' + FloatToStrF(BestCost,
    ffGeneral, 4, 4);
end;

function TFmDifferentialEvolution.DECalculateCosts(Sender: TObject;
  Data: PDoubleArray; Count: Integer): Double;
var
  Error : Double;
  x, y  : Double;
  xmax  : Double;
  xinc  : Double;
begin
  Error := 0;
  x := ReferenceFunction.StartX;
  xmax := x + ReferenceFunction.NumPoints * ReferenceFunction.Period;
  xinc := ReferenceFunction.Period;

  while x <= xmax do
  begin
    y := (((((Sqr(x) + Data^[0]) * Sqr(x) + Data^[1]) * Sqr(x) + Data^[2]) *
      Sqr(x) + Data^[3]) * Sqr(x) + Data^[4]) * x;
    Error := Error + Sqr(y - TestFunction(x));
    x := x + xinc;
  end;
  Result := Log10(1E-20 + Sqrt(Error));
end;

procedure TFmDifferentialEvolution.DEGenerationChanged(
  Sender: TObject; Generation: Integer);
begin
  StatusBar.Panels[0].Text := 'Generation: ' + IntToStr(Generation + 1);
end;

procedure TFmDifferentialEvolution.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if DifferentialEvolution.IsRunning then
    DifferentialEvolution.Stop;
end;

procedure TFmDifferentialEvolution.MiExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFmDifferentialEvolution.MiResetClick(Sender: TObject);
begin
  DifferentialEvolution.Reset;
end;

procedure TFmDifferentialEvolution.MiStartClick(Sender: TObject);
begin
  DifferentialEvolution.Start(100);
end;

procedure TFmDifferentialEvolution.MiStopClick(Sender: TObject);
begin
  DifferentialEvolution.Stop;
end;

procedure TFmDifferentialEvolution.ReferenceFunctionCalculate(
  Sender: TCustomTeeFunction; const x: Double; var y: Double);
begin
 y := TestFunction(x);
end;

procedure TFmDifferentialEvolution.MiSingleStepClick(Sender: TObject);
begin
  DifferentialEvolution.Evolve;
end;

end.

