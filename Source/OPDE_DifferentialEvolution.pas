unit OPDE_DifferentialEvolution;

////////////////////////////////////////////////////////////////////////////////
//                                                                           //
// Version: MPL 1.1 or LGPL 2.1 with linking exception                       //
//                                                                           //
// The contents of this file are subject to the Mozilla Public License       //
// Version 1.1 (the "License"); you may not use this file except in          //
// compliance with the License. You may obtain a copy of the License at      //
// http://www.mozilla.org/MPL/                                               //
//                                                                           //
// Software distributed under the License is distributed on an "AS IS"       //
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the   //
// License for the specific language governing rights and limitations under  //
// the License.                                                              //
//                                                                           //
// Alternatively, the contents of this file may be used under the terms of   //
// the Free Pascal modified version of the GNU Lesser General Public         //
// License Version 2.1 (the "FPC modified LGPL License"), in which case the  //
// provisions of this license are applicable instead of those above.         //
// Please see the file LICENSE.txt for additional information concerning     //
// this license.                                                             //
//                                                                           //
// The code is part of the Object Pascal Differential Evolution Project      //
//                                                                           //
// Portions created by Christian-W. Budde are Copyright (C) 2006-2011        //
// by Christian-W. Budde. All Rights Reserved.                               //
//                                                                           //
////////////////////////////////////////////////////////////////////////////////

interface

{$I DAV_Compiler.inc}

{-$DEFINE StartStopExceptions}

uses
  Types, Classes, SysUtils, SyncObjs;

type
  EDifferentialEvolution = class(Exception);

  DoubleArray = array [0 .. $0FFFFFF8] of Double;
  PDoubleArray = ^DoubleArray;

  TNewDifferentialEvolution = class;

  TDECalculateCostEvent = function(Sender: TObject; Data: PDoubleArray;
    Count: Integer): Double of object;
  TDEBestCostChangedEvent = procedure(Sender: TObject;
    BestCost: Double) of object;
  TDEGenerationChangedEvent = procedure(Sender: TObject;
    Generation: Integer) of object;

  TDEVariableCollectionItem = class(TCollectionItem)
  private
    FDisplayName : string;
    FMinimum     : Double;
    FMaximum     : Double;
    procedure SetMaximum(const Value: Double);
    procedure SetMinimum(const Value: Double);
  protected
    function GetDisplayName: string; override;
    procedure SetDisplayName(const Value: string); override;
    procedure AssignTo(Dest: TPersistent); override;

    procedure MaximumChanged; virtual;
    procedure MinimumChanged; virtual;
  public
    constructor Create(Collection: TCollection); override;
  published
    property DisplayName;
    property Minimum: Double read FMinimum write SetMinimum;
    property Maximum: Double read FMaximum write SetMaximum;
  end;

  TDEVariableCollection = class(TOwnedCollection)
  protected
    function GetItem(Index: Integer): TDEVariableCollectionItem; virtual;
    procedure SetItem(Index: Integer;
      const Value: TDEVariableCollectionItem); virtual;
    procedure Update(Item: TCollectionItem); override;
    property Items[Index: Integer]: TDEVariableCollectionItem
      read GetItem write SetItem; default;
  public
    constructor Create(AOwner: TComponent);
  end;

  TDEPopulationData = class(TObject)
  private
    FDE    : TNewDifferentialEvolution;
    FData  : PDoubleArray;
    FCount : Cardinal;
    FCost  : Double;
    function GetData(Index: Cardinal): Double;
    procedure SetData(Index: Cardinal; const Value: Double);
  protected
    property DifferentialEvolution: TNewDifferentialEvolution read FDE;
  public
    constructor Create(DifferentialEvaluation: TNewDifferentialEvolution); overload;
    destructor Destroy; override;

    procedure InitializeData;

    property Cost: Double read FCost write FCost;
    property Data[Index: Cardinal]: Double read GetData write SetData;
    property Count: Cardinal read FCount;
  end;

  TDECalculateGenerationCosts = procedure(Generation: PPointerArray) of object;

  TNewDifferentialEvolution = class(TComponent)
  strict private
    FCrossOver           : Double;
    FDifferentialWeight  : Double;
    FBestWeight          : Double;
    FGains               : array [0..3] of Double;
    FVariables           : TDEVariableCollection;
    FOnCalculateCosts    : TDECalculateCostEvent;
    FOnBestCostChanged   : TDEBestCostChangedEvent;
    FOnGenerationChanged : TDEGenerationChangedEvent;
    FCalcGenerationCosts : TDECalculateGenerationCosts;
    FDirectSelection     : Boolean;
    function GetIsRunning: Boolean;
    function GetNumberOfThreads: Cardinal;
    procedure SetBestWeight(const Value: Double);
    procedure SetCrossOver(const Value: Double);
    procedure SetDifferentialWeight(const Value: Double);
    procedure SetDirectSelection(const Value: Boolean);
    procedure SetNumberOfThreads(const Value: Cardinal);
    procedure SetPopulationCount(const Value: Cardinal);
    procedure SetVariables(const Value: TDEVariableCollection);
  private
    FTotalGenerations       : Integer;
    FCurrentGenerationIndex : Integer;
    FCurrentPopulation      : Cardinal;
    FPopulationsCalculated  : Cardinal;
    FPopulationCount        : Cardinal;
    FIsInitialized          : Boolean;
    FDriverThread           : TThread;
    FCostCalculationEvent   : TEvent;
    FCriticalSection        : TCriticalSection;
    FThreads                : array of TThread;
    procedure CreatePopulationData;
    procedure FreePopulationData;
    function FindBest(Generation: PPointerArray): Integer;
    function GetBestPopulation: TDEPopulationData;
    procedure BuildNextGeneration;
    procedure CalculateCostsDirect(Generation: PPointerArray);
    procedure CalculateCostsThreaded(Generation: PPointerArray);
    procedure RandomizePopulation;
    procedure SelectFittest;
    procedure UpdateInternalGains;
  protected
    FBestPopulationIndex : Integer;
    FVariableCount       : Cardinal;
    FCurrentGeneration   : PPointerArray;
    FNextGeneration      : PPointerArray;
    procedure BestWeightChanged; virtual;
    procedure BestIndexChanged; virtual;
    procedure CrossoverChanged; virtual;
    procedure DifferentialWeightChanged; virtual;
    procedure DirectSelectionChanged; virtual;
    procedure GenerationChanged; virtual;
    procedure PopulationCountChanged; virtual;
    procedure NumberOfThreadsChanged; virtual;
    procedure VariableChanged(Index: Integer); virtual;
    procedure VariableCountChanged; virtual;

    procedure CalculateCurrentGeneration;

    property VariableCount: Cardinal read FVariableCount;
    property IsInitialized: Boolean read FIsInitialized;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Start(Evaluations: Integer = 0);
    procedure Stop;
    procedure Reset;

    procedure Evolve;

    property BestPopulation: TDEPopulationData read GetBestPopulation;
  published
    property BestWeight: Double read FBestWeight write SetBestWeight;
    property CrossOver: Double read FCrossOver write SetCrossOver;
    property DifferentialWeight: Double read FDifferentialWeight write SetDifferentialWeight;
    property DirectSelection: Boolean read FDirectSelection write SetDirectSelection default False;
    property IsRunning: Boolean read GetIsRunning;
    property NumberOfThreads: Cardinal read GetNumberOfThreads write SetNumberOfThreads default 0;
    property PopulationCount: Cardinal read FPopulationCount write SetPopulationCount default 15;
    property Variables: TDEVariableCollection read FVariables write SetVariables;
    property OnCalculateCosts: TDECalculateCostEvent read FOnCalculateCosts write FOnCalculateCosts;
    property OnBestCostChanged: TDEBestCostChangedEvent read FOnBestCostChanged write FOnBestCostChanged;
    property OnGenerationChanged: TDEGenerationChangedEvent read FOnGenerationChanged write FOnGenerationChanged;
  end;

procedure Register;

implementation

uses
  Math;

resourcestring
  RCStrCrossOverBoundError = 'CrossOver must be 0 <= x <= 1';
  RCStrDiffWeightBoundError = 'Differential Weight must be 0 <= x <= 2';
  RCStrBestWeightBoundError = 'Best Weight must be 0 <= x <= 2';
  RCStrPopulationCountError = 'At least 4 populations are required!';
  RCStrIndexOutOfBounds = 'Index out of bounds (%d)';
  RCStrOptimizerIsAlreadyRunning = 'Optimizer is already running';
  RCStrOptimizerIsRunning = 'Optimizer is running';
  RCStrOptimizerIsNotRunning = 'Optimizer is not running';
  RCStrNoCostFunction = 'No cost function specified!';

type
  TDriverThread = class(TThread)
  protected
    FOwner: TNewDifferentialEvolution;
    procedure Execute; override;
  public
    constructor Create(Owner: TNewDifferentialEvolution); virtual;
  end;

  TCostCalculatorThread = class(TThread)
  protected
    FOwner      : TNewDifferentialEvolution;
    FGeneration : PPointerArray;
    procedure Execute; override;
  public
    constructor Create(Owner: TNewDifferentialEvolution;
      Generation: PPointerArray); virtual;
  end;

{ TDriverThread }

constructor TDriverThread.Create(Owner: TNewDifferentialEvolution);
begin
  FOwner := Owner;
  inherited Create(False);
end;

procedure TDriverThread.Execute;
begin
  inherited;

  while not Terminated do
  begin
    FOwner.CalculateCurrentGeneration;

    Synchronize(FOwner.GenerationChanged);

    Inc(FOwner.FCurrentGenerationIndex);
    if (FOwner.FTotalGenerations > 0) and (FOwner.FCurrentGenerationIndex >= FOwner.FTotalGenerations) then
    begin
      FreeOnTerminate := True;
      Terminate;
      FOwner.FDriverThread := nil;
    end;
  end;
end;


{ TCostCalculatorThread }

constructor TCostCalculatorThread.Create(Owner: TNewDifferentialEvolution;
  Generation: PPointerArray);
begin
  FOwner := Owner;
  FGeneration := Generation;
  inherited Create(False);
end;

procedure TCostCalculatorThread.Execute;
var
  Population : Cardinal;
begin
  inherited;

  while not Terminated do
    with FOwner do
    begin
      FCriticalSection.Enter;
      try
        Population := FCurrentPopulation;
        if Population >= PopulationCount then
        begin
          Terminate;
          Exit;
        end;
        Inc(FCurrentPopulation);
      finally
        FCriticalSection.Leave;
      end;

      Assert(Population < PopulationCount);

      with TDEPopulationData(FGeneration^[Population]) do
        FCost := OnCalculateCosts(Self, FData, VariableCount);

      FCriticalSection.Enter;
      try
        Inc(FPopulationsCalculated);
      finally
        FCriticalSection.Leave;
      end;

      if FOwner.FPopulationsCalculated = FOwner.PopulationCount then
      begin
        FCostCalculationEvent.SetEvent;
        Terminate;
      end;
      Assert(FPopulationsCalculated <= FOwner.PopulationCount);
    end;
end;


{ TDEVariableCollectionItem }

constructor TDEVariableCollectionItem.Create
  (Collection: TCollection);
begin
  inherited;
  FDisplayName := 'Variable ' + IntToStr(Index);
  FMinimum := 0;
  FMaximum := 1;
end;

procedure TDEVariableCollectionItem.AssignTo
  (Dest: TPersistent);
begin
  if Dest is TDEVariableCollectionItem then
    with TDEVariableCollectionItem(Dest) do
    begin
      FDisplayName := Self.FDisplayName;
      FMinimum := Self.FMinimum;
      FMaximum := Self.FMaximum;
    end
  else
    inherited;
end;

procedure TDEVariableCollectionItem.MaximumChanged;
begin
  Changed(False);
  (*
    Assert(Collection.Owner is TNewDifferentialEvolution);
    TNewDifferentialEvolution(Collection.Owner).VariableChanged(Index);
    Collection.EndUpdate;
  *)
end;

procedure TDEVariableCollectionItem.MinimumChanged;
begin
  Changed(False);
  (*
    Assert(Collection.Owner is TNewDifferentialEvolution);
    TNewDifferentialEvolution(Collection.Owner).VariableChanged(Index);
  *)
end;

function TDEVariableCollectionItem.GetDisplayName: string;
begin
  Result := FDisplayName;
end;

procedure TDEVariableCollectionItem.SetDisplayName
  (const Value: string);
begin
  FDisplayName := Value;
  inherited;
end;

procedure TDEVariableCollectionItem.SetMaximum
  (const Value: Double);
begin
  if FMaximum <> Value then
  begin
    FMaximum := Value;
    MaximumChanged;
  end;
end;

procedure TDEVariableCollectionItem.SetMinimum
  (const Value: Double);
begin
  if FMinimum <> Value then
  begin
    FMinimum := Value;
    MinimumChanged;
  end;
end;


{ TDEVariableCollection }

constructor TDEVariableCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TDEVariableCollectionItem);
end;

function TDEVariableCollection.GetItem(Index: Integer)
  : TDEVariableCollectionItem;
begin
  Result := TDEVariableCollectionItem
    (inherited GetItem(Index));
end;

procedure TDEVariableCollection.SetItem(Index: Integer;
  const Value: TDEVariableCollectionItem);
begin
  inherited SetItem(Index, Value);
end;

procedure TDEVariableCollection.Update
  (Item: TCollectionItem);
begin
  inherited;

  if (Owner is TNewDifferentialEvolution) then
    if Assigned(Item) then
      TNewDifferentialEvolution(Owner).VariableChanged(Item.Index)
    else
      TNewDifferentialEvolution(Owner).VariableCountChanged;
end;


{ TDEPopulationData }

constructor TDEPopulationData.Create(
  DifferentialEvaluation: TNewDifferentialEvolution);
begin
  FDE := DifferentialEvaluation;
  FCount := FDE.VariableCount;
  GetMem(FData, FCount * SizeOf(Double));
end;

destructor TDEPopulationData.Destroy;
begin
  FreeMem(FData);
  inherited;
end;

procedure TDEPopulationData.InitializeData;
var
  Index  : Integer;
  Offset : Double;
  Scale  : Double;
begin
  Assert(FCount = FDE.VariableCount);

  for Index := 0 to FCount - 1 do
    with FDE.Variables[Index] do
    begin
      Offset := Minimum;
      Scale := Maximum - Minimum;
      FData[Index] := Offset + Random * Scale;
    end;
end;

function TDEPopulationData.GetData(Index: Cardinal): Double;
begin
  if (Index <= FCount) then
    Result := FData^[Index]
  else
    raise Exception.CreateFmt(RCStrIndexOutOfBounds, [Index]);
end;

procedure TDEPopulationData.SetData(Index: Cardinal; const Value: Double);
begin
  if (Index <= FCount) then
    if FData^[Index] <> Value then
    begin
      FData^[Index] := Value;

      // TODO: recalculate costs
    end
    else
  else
    raise Exception.CreateFmt(RCStrIndexOutOfBounds, [Index]);
end;


{ TNewDifferentialEvolution }

constructor TNewDifferentialEvolution.Create(AOwner: TComponent);
begin
  inherited;
  FVariables := TDEVariableCollection.Create(Self);

  FPopulationCount := 15;
  FDirectSelection := False;
  FIsInitialized := False;
  FBestWeight := 0;
  FCrossOver := 0.9;
  FDifferentialWeight := 0.4;
  FCalcGenerationCosts := CalculateCostsDirect;
  FTotalGenerations := 0;
  FCurrentGenerationIndex := 0;

  UpdateInternalGains;
end;

destructor TNewDifferentialEvolution.Destroy;
begin
  if IsRunning then
    Stop;

  // eventually free cost calculation event
  if Assigned(FCostCalculationEvent) then
    FreeAndNil(FCostCalculationEvent);

  if Assigned(FCriticalSection) then
    FreeAndNil(FCriticalSection);

  FreePopulationData;
  FreeAndNil(FVariables);
  inherited;
end;

procedure TNewDifferentialEvolution.CreatePopulationData;
var
  Index: Integer;
begin
  // allocated memory
  GetMem(FCurrentGeneration, FPopulationCount * SizeOf(TDEPopulationData));
  GetMem(FNextGeneration, FPopulationCount * SizeOf(TDEPopulationData));

  // actually create population data
  for Index := 0 to FPopulationCount - 1 do
  begin
    FCurrentGeneration[Index] := TDEPopulationData.Create(Self);
    FNextGeneration[Index] := TDEPopulationData.Create(Self);
  end;
end;

procedure TNewDifferentialEvolution.FreePopulationData;
var
  Index: Integer;
begin
  // check whether memory has been allocated at all
  if not(Assigned(FCurrentGeneration) and Assigned(FNextGeneration)) then
    Exit;

  // free population data
  for Index := 0 to FPopulationCount - 1 do
  begin
    TDEPopulationData(FCurrentGeneration[Index]).Free;
    TDEPopulationData(FNextGeneration[Index]).Free;
  end;

  // free memory
  FreeMem(FCurrentGeneration, FPopulationCount * SizeOf(TDEPopulationData));
  FreeMem(FNextGeneration, FPopulationCount * SizeOf(TDEPopulationData));

  FCurrentGeneration := nil;
  FNextGeneration := nil;
end;

procedure TNewDifferentialEvolution.Start(Evaluations: Integer);
begin
  if IsRunning then
    raise EDifferentialEvolution.Create(RCStrOptimizerIsAlreadyRunning);

  if not Assigned(FOnCalculateCosts) then
    raise EDifferentialEvolution.Create(RCStrNoCostFunction);

  FTotalGenerations := FTotalGenerations + Evaluations;

  // create population data
  if not Assigned(FCurrentGeneration) then
    CreatePopulationData;

  // start driver thread
  if not Assigned(FDriverThread) then
    FDriverThread := TDriverThread.Create(Self);
end;

procedure TNewDifferentialEvolution.Stop;
begin
  {$IFDEF StartStopExceptions}
  if not IsRunning then
    raise EDifferentialEvolution.Create(RCStrOptimizerIsNotRunning);
  {$ENDIF}

  if Assigned(FDriverThread) then
  begin
    FDriverThread.Terminate;
    FDriverThread.WaitFor;
    FreeAndNil(FDriverThread);
  end;
end;

procedure TNewDifferentialEvolution.Reset;
begin
  if not IsRunning then
  begin
    FTotalGenerations := 0;
    FreePopulationData;
  end
  else
    FTotalGenerations := FTotalGenerations - FCurrentGenerationIndex;

  FCurrentGenerationIndex := 0;

  FIsInitialized := False;
end;

procedure TNewDifferentialEvolution.Evolve;
begin
  {$IFDEF StartStopExceptions}
  if IsRunning then
    raise EDifferentialEvolution.Create(RCStrOptimizerIsRunning);
  {$ENDIF}

  // create population data
  if not Assigned(FCurrentGeneration) then
    CreatePopulationData;

  CalculateCurrentGeneration;
end;

procedure TNewDifferentialEvolution.RandomizePopulation;
var
  Index : Integer;
begin
  for Index := 0 to FPopulationCount - 1 do
    TDEPopulationData(FCurrentGeneration[Index]).InitializeData;

  FBestPopulationIndex := -1;
end;

procedure TNewDifferentialEvolution.CalculateCostsDirect(Generation: PPointerArray);
var
  Index : Integer;
begin
  for Index := 0 to FPopulationCount - 1 do
    with TDEPopulationData(Generation^[Index]) do
      FCost := FOnCalculateCosts(Self, FData, VariableCount);
end;

procedure TNewDifferentialEvolution.CalculateCostsThreaded(
  Generation: PPointerArray);
var
  Index : Integer;
begin
  FCurrentPopulation := 0;
  FPopulationsCalculated := 0;

  for Index := 0 to Length(FThreads) - 1 do
    FThreads[Index] := TCostCalculatorThread.Create(Self, Generation);

  if FCostCalculationEvent.WaitFor(INFINITE) <> wrSignaled then
    raise EDifferentialEvolution.Create('Error receiving signal');

  for Index := 0 to Length(FThreads) - 1 do
  begin
    FThreads[Index].WaitFor;
    FreeAndNil(FThreads[Index]);
  end;

  FCostCalculationEvent.ResetEvent;

  if FPopulationsCalculated <> FPopulationCount then
    Assert(FPopulationsCalculated = FPopulationCount);
end;

procedure TNewDifferentialEvolution.BuildNextGeneration;
var
  RandomPopIndex  : array [0..2] of Integer;
  PopIndex        : Integer;
  VarIndex        : Cardinal;
  VarCount        : Cardinal;
  BasePopulation  : TDEPopulationData;
  NewPopulation   : TDEPopulationData;
begin
  Assert(FBestPopulationIndex >= 0);

  for PopIndex := 0 to FPopulationCount - 1 do
  begin
    // Find 3 different populations randomly
    repeat
      RandomPopIndex[0] := Random(FPopulationCount);
    until (RandomPopIndex[0] <> PopIndex) and (RandomPopIndex[0] <> FBestPopulationIndex);

    repeat
      RandomPopIndex[1] := Random(FPopulationCount);
    until (RandomPopIndex[1] <> PopIndex) and
      (RandomPopIndex[1] <> FBestPopulationIndex) and
      (RandomPopIndex[1] <> RandomPopIndex[0]);

    repeat
      RandomPopIndex[2] := Random(FPopulationCount);
    until (RandomPopIndex[2] <> PopIndex) and
      (RandomPopIndex[2] <> FBestPopulationIndex) and
      (RandomPopIndex[2] <> RandomPopIndex[1]) and
      (RandomPopIndex[2] <> RandomPopIndex[0]);

    BasePopulation := TDEPopulationData(FCurrentGeneration[PopIndex]);
    NewPopulation := TDEPopulationData(FNextGeneration[PopIndex]);

    // generate trial vector with crossing-over
    VarIndex := Random(FVariableCount);
    VarCount := 0;

    // build mutation
    repeat
      NewPopulation.FData[VarIndex] := BasePopulation.FData[VarIndex] +
        TDEPopulationData(FCurrentGeneration[RandomPopIndex[0]]).FData[VarIndex] * FGains[1] +
        TDEPopulationData(FCurrentGeneration[RandomPopIndex[1]]).FData[VarIndex] * FGains[2] +
        TDEPopulationData(FCurrentGeneration[RandomPopIndex[2]]).FData[VarIndex] * FGains[3] +
        TDEPopulationData(FCurrentGeneration[FBestPopulationIndex]).FData[VarIndex] * FGains[0];
      Inc(VarIndex);
      if VarIndex >= FVariableCount then
        VarIndex := 0;
      Inc(VarCount);
    until (VarCount >= FVariableCount) or (Random >= FCrossOver);

    // copy original population
    while (VarCount < FVariableCount) do
    begin
      NewPopulation.FData[VarIndex] := BasePopulation.FData[VarIndex];
      Inc(VarIndex);
      if VarIndex >= FVariableCount then
        VarIndex := 0;
      Inc(VarCount);
    end;
  end;
end;

function TNewDifferentialEvolution.FindBest(Generation: PPointerArray): Integer;
var
  Best  : Double;
  Index : Integer;
begin
  Result := 0;
  Best := TDEPopulationData(Generation[0]).Cost;

  for Index := 1 to FPopulationCount - 1 do
    if (TDEPopulationData(Generation[Index]).Cost < Best) then
      Result := Index;
end;

procedure TNewDifferentialEvolution.SelectFittest;
var
  Best      : Double;
  BestIndex : Integer;
  Index     : Integer;
  Cur, Next : TDEPopulationData;
begin
  BestIndex := FBestPopulationIndex;
  Best := TDEPopulationData(FCurrentGeneration[BestIndex]).Cost;
  for Index := 0 to FPopulationCount - 1 do
  begin
    Cur := TDEPopulationData(FCurrentGeneration[Index]);
    Next := TDEPopulationData(FNextGeneration[Index]);
    if (Next.Cost < Cur.Cost) then
    begin
      Assert(Next.Count = Cur.Count);
      Assert(Next.FDE = Cur.FDE);
      Move(Next.FData^, Cur.FData^, Cur.Count * SizeOf(Double));
      Cur.FCost := Next.FCost;
      if Cur.FCost < Best then
      begin
        BestIndex := Index;
        Best := Cur.FCost;
      end;
    end;
  end;

  if BestIndex <> FBestPopulationIndex then
  begin
    FBestPopulationIndex := BestIndex;
    if Assigned(FDriverThread) then
      TThread.Synchronize(FDriverThread, BestIndexChanged)
    else
      BestIndexChanged;
  end;
end;

procedure TNewDifferentialEvolution.CalculateCurrentGeneration;
begin
  if not IsInitialized then
  begin
    RandomizePopulation;
    FCalcGenerationCosts(FCurrentGeneration);
    FBestPopulationIndex := FindBest(FCurrentGeneration);
    FIsInitialized := True;
  end;

  BuildNextGeneration;
  FCalcGenerationCosts(FNextGeneration);
  SelectFittest;
end;

procedure TNewDifferentialEvolution.GenerationChanged;
begin
  if Assigned(FOnGenerationChanged) then
    FOnGenerationChanged(Self, FCurrentGenerationIndex);
end;

function TNewDifferentialEvolution.GetBestPopulation: TDEPopulationData;
begin
  if FBestPopulationIndex >= 0 then
    Result := TDEPopulationData(FCurrentGeneration[FBestPopulationIndex])
  else
    Result := nil;
end;

function TNewDifferentialEvolution.GetIsRunning: Boolean;
begin
  Result := Assigned(FDriverThread);
end;

function TNewDifferentialEvolution.GetNumberOfThreads: Cardinal;
begin
  Result := Length(FThreads);
end;

procedure TNewDifferentialEvolution.UpdateInternalGains;
begin
  FGains[1] :=  FDifferentialWeight;
  FGains[2] := -FDifferentialWeight;
end;


procedure TNewDifferentialEvolution.CrossoverChanged;
begin
  // nothing here yet
end;

procedure TNewDifferentialEvolution.DifferentialWeightChanged;
begin
  FGains[1] :=  FDifferentialWeight;
  FGains[2] := -FDifferentialWeight;
end;

procedure TNewDifferentialEvolution.DirectSelectionChanged;
begin
  // nothing here yet
end;

procedure TNewDifferentialEvolution.NumberOfThreadsChanged;
begin
  if NumberOfThreads > 0 then
  begin
    if not Assigned(FCostCalculationEvent) then
      FCostCalculationEvent := TEvent.Create;
    if not Assigned(FCriticalSection) then
      FCriticalSection := TCriticalSection.Create;
    FCalcGenerationCosts := CalculateCostsThreaded;
  end
  else
  begin
    FCalcGenerationCosts := CalculateCostsDirect;
    if Assigned(FCostCalculationEvent) then
      FreeAndNil(FCostCalculationEvent);
    if Assigned(FCriticalSection) then
      FreeAndNil(FCriticalSection)
  end;
end;

procedure TNewDifferentialEvolution.PopulationCountChanged;
begin
  // nothing here yet
end;

procedure TNewDifferentialEvolution.BestIndexChanged;
var
  BestCost : Double;
begin
  if Assigned(FOnBestCostChanged) then
  begin
    BestCost := TDEPopulationData(FCurrentGeneration[FBestPopulationIndex]).Cost;
    FOnBestCostChanged(Self, BestCost);
  end;
end;

procedure TNewDifferentialEvolution.BestWeightChanged;
begin
  FGains[0] := FBestWeight;
  FGains[3] := -FBestWeight;
end;

procedure TNewDifferentialEvolution.VariableChanged(Index: Integer);
begin
  // nothing here yet
end;

procedure TNewDifferentialEvolution.VariableCountChanged;
begin
  FVariableCount := FVariables.Count;
end;

procedure TNewDifferentialEvolution.SetBestWeight(const Value: Double);
begin
  // check if new differential weight is within its bounds [0..2]
  if (Value < 0) or (Value > 2) then
    raise EDifferentialEvolution.Create(RCStrBestWeightBoundError);

  if FBestWeight <> Value then
  begin
    FBestWeight := Value;
    BestWeightChanged;
  end;
end;

procedure TNewDifferentialEvolution.SetCrossOver(const Value: Double);
begin
  // check if new crossover value is within its bounds [0..1]
  if (Value < 0) or (Value > 1) then
    raise EDifferentialEvolution.Create(RCStrCrossOverBoundError);

  if FCrossOver <> Value then
  begin
    FCrossOver := Value;
    CrossoverChanged;
  end;
end;

procedure TNewDifferentialEvolution.SetDifferentialWeight(const Value: Double);
begin
  // check if new differential weight is within its bounds [0..2]
  if (Value < 0) or (Value > 2) then
    raise EDifferentialEvolution.Create(RCStrDiffWeightBoundError);

  if FDifferentialWeight <> Value then
  begin
    FDifferentialWeight := Value;
    DifferentialWeightChanged;
  end;
end;

procedure TNewDifferentialEvolution.SetDirectSelection(const Value: Boolean);
begin
  if FDirectSelection <> Value then
  begin
    FDirectSelection := Value;
    DirectSelectionChanged;
  end;
end;

procedure TNewDifferentialEvolution.SetNumberOfThreads(const Value: Cardinal);
begin
  if Value <> NumberOfThreads then
  begin
    SetLength(FThreads, Value);
    NumberOfThreadsChanged;
  end;
end;

procedure TNewDifferentialEvolution.SetPopulationCount(const Value: Cardinal);
begin
  // check that at least 4 populations are specified
  if (Value < 4) then
    raise EDifferentialEvolution.Create(RCStrPopulationCountError);

  if FPopulationCount <> Value then
  begin
    FPopulationCount := Value;
    PopulationCountChanged;
  end;
end;

procedure TNewDifferentialEvolution.SetVariables(const Value
  : TDEVariableCollection);
begin
  FVariables.Assign(Value);
  FVariableCount := FVariables.Count;
end;

procedure Register;
begin
  RegisterComponents('Object Pascal Differential Evolution',
    [TNewDifferentialEvolution]);
end;

end.
