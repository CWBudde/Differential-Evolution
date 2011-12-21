unit OPDE_Chunks;

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

{$I jedi.inc}

uses
  Classes;

type
  // chunk types
  TChunkName = packed record
  case Integer of
   0: (AsUInt32 : Cardinal);
   1: (AsInt32  : Integer);
   2: (AsChar8  : array [0..3] of AnsiChar);
  end;
  PChunkName = ^TChunkName;

  {$A4}

  TCustomChunk = class(TPersistent)
  protected
    function GetChunkNameAsString: AnsiString; virtual; abstract;
    function GetChunkName: TChunkName; virtual; abstract;
    function GetChunkSize: Cardinal; virtual; abstract;
  public
    procedure ReadFromStream(Stream: TStream; ChunkSize: Cardinal); virtual; abstract;
    procedure WriteToStream(Stream: TStream); virtual; abstract;

    property ChunkName: TChunkName read GetChunkName;
    property ChunkNameAsString: AnsiString read GetChunkNameAsString;
    property ChunkSize: Cardinal read GetChunkSize;
  end;

  TCustomDefinedChunk = class(TCustomChunk)
  protected
    function GetChunkNameAsString: AnsiString; override;
    function GetChunkName: TChunkName; override;
    class function GetClassChunkName: TChunkName; virtual; abstract;
  public
    property ChunkName: TChunkName read GetClassChunkName;
  end;

  TChunkDifferentialEvolutionHeader = class(TCustomDefinedChunk)
  private
    FJitter              : Double;
    FBestWeight          : Double;
    FDither              : Double;
    FCrossOver           : Double;
    FDifferentialWeight  : Double;
    FFlags               : Cardinal;
    FPopulationCount     : Cardinal;
    FNumberOfThreads     : Cardinal;
    function GetDirectSelection: Boolean;
    function GetDitherPerGeneration: Boolean;
    procedure SetDirectSelection(const Value: Boolean);
    procedure SetDitherPerGeneration(const Value: Boolean);
  protected
    class function GetClassChunkName: TChunkName; override;
    function GetChunkSize: Cardinal; override;

    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; virtual;

    procedure ReadFromStream(Stream: TStream; ChunkSize: Cardinal); override;
    procedure WriteToStream(Stream: TStream); override;

    property BestWeight: Double read FBestWeight write FBestWeight;
    property CrossOver: Double read FCrossOver write FCrossOver;
    property Dither: Double read FDither write FDither;
    property DitherPerGeneration: Boolean read GetDitherPerGeneration write SetDitherPerGeneration;
    property DifferentialWeight: Double read FDifferentialWeight write FDifferentialWeight;
    property DirectSelection: Boolean read GetDirectSelection write SetDirectSelection;
    property Jitter: Double read FJitter write FJitter;
    property NumberOfThreads: Cardinal read FNumberOfThreads write FNumberOfThreads;
    property PopulationCount: Cardinal read FPopulationCount write FPopulationCount;
  end;

(*
  TChunkDifferentialEvolutionPopulation = class(TCustomDefinedChunk)
  private
    FData  : PDoubleArray;
    FCount : Cardinal;
    FCost  : Double;
  protected
    class function GetClassChunkName: TChunkName; override;
    function GetChunkSize: Cardinal; override;

    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; virtual;

    procedure ReadFromStream(Stream: TStream; ChunkSize: Cardinal); override;
    procedure WriteToStream(Stream: TStream); override;

    property Cost: Double read FCost write FCost;
    property Data[Index: Cardinal]: Double read GetData write SetData;
    property DataPointer: PDoubleArray read FData;
    property Count: Cardinal read FCount;
  end;
*)

implementation

uses
  OPDE_DifferentialEvolution;

{ TCustomDefinedChunk }

function TCustomDefinedChunk.GetChunkName: TChunkName;
begin
  Result := GetClassChunkName;
end;

function TCustomDefinedChunk.GetChunkNameAsString: AnsiString;
begin
  Result := AnsiString(GetClassChunkName);
end;


{ TChunkDifferentialEvolutionHeader }

constructor TChunkDifferentialEvolutionHeader.Create;
begin
  inherited;
  FJitter             := 0;
  FFlags              := 0;
  FBestWeight         := 0;
  FDither             := 0;
  FPopulationCount    := 16;
  FNumberOfThreads    := 0;
  FCrossOver          := 0;
  FDifferentialWeight := 0;
end;

class function TChunkDifferentialEvolutionHeader.GetClassChunkName: TChunkName;
begin
  Result.AsChar8 := 'DEhd';
end;

function TChunkDifferentialEvolutionHeader.GetDirectSelection: Boolean;
begin
  Result := (FFlags and $1) <> 0;
end;

function TChunkDifferentialEvolutionHeader.GetDitherPerGeneration: Boolean;
begin
  Result := (FFlags and $2) <> 0;
end;

procedure TChunkDifferentialEvolutionHeader.SetDirectSelection(
  const Value: Boolean);
begin
  FFlags := (FFlags and $FFFFFFFE) or (Integer(Value = True) and $1);
end;

procedure TChunkDifferentialEvolutionHeader.SetDitherPerGeneration(
  const Value: Boolean);
begin
  FFlags := (FFlags and $FFFFFFFD) or ((Integer(Value = True) and $1) shl 1);
end;

procedure TChunkDifferentialEvolutionHeader.AssignTo(Dest: TPersistent);
begin
  if Dest is TChunkDifferentialEvolutionHeader then
    with TChunkDifferentialEvolutionHeader(Dest) do
    begin
      FJitter             := Self.FJitter;
      FFlags              := Self.FFlags;
      FBestWeight         := Self.FBestWeight;
      FDither             := Self.FDither;
      FPopulationCount    := Self.FPopulationCount;
      FNumberOfThreads    := Self.FNumberOfThreads;
      FCrossOver          := Self.FCrossOver;
      FDifferentialWeight := Self.FDifferentialWeight;
    end
  else
  if Dest is TNewDifferentialEvolution then
    with TNewDifferentialEvolution(Dest) do
    begin
      Jitter             := Self.FJitter;
      BestWeight         := Self.FBestWeight;
      Dither             := Self.FDither;
      PopulationCount    := Self.FPopulationCount;
      NumberOfThreads    := Self.FNumberOfThreads;
      CrossOver          := Self.FCrossOver;
      DifferentialWeight := Self.FDifferentialWeight;
    end
  else
    inherited;
end;

function TChunkDifferentialEvolutionHeader.GetChunkSize: Cardinal;
begin
  Result := 5 * SizeOf(Double) + 3 * SizeOf(Integer);
end;

procedure TChunkDifferentialEvolutionHeader.ReadFromStream(Stream: TStream;
  ChunkSize: Cardinal);
begin
  with Stream do
  begin
    Assert(ChunkSize >= GetChunkSize);
    Read(FJitter, SizeOf(Double));
    Read(FBestWeight, SizeOf(Double));
    Read(FDither, SizeOf(Double));
    Read(FCrossOver, SizeOf(Double));
    Read(FDifferentialWeight, SizeOf(Double));
    Read(FFlags, SizeOf(Cardinal));
    Read(FPopulationCount, SizeOf(Cardinal));
    Read(FNumberOfThreads, SizeOf(Cardinal));
  end;
end;

procedure TChunkDifferentialEvolutionHeader.WriteToStream(Stream: TStream);
var
  ChunkName : TChunkName;
  ChunkSize : Cardinal;
begin
  with Stream do
  begin
    ChunkName := GetChunkName;
    Write(ChunkName.AsUInt32, SizeOf(Cardinal));

    ChunkSize := GetChunkSize;
    Write(ChunkSize, SizeOf(Cardinal));

    Write(FJitter, SizeOf(Double));
    Write(FBestWeight, SizeOf(Double));
    Write(FDither, SizeOf(Double));
    Write(FCrossOver, SizeOf(Double));
    Write(FDifferentialWeight, SizeOf(Double));
    Write(FFlags, SizeOf(Cardinal));
    Write(FPopulationCount, SizeOf(Cardinal));
    Write(FNumberOfThreads, SizeOf(Cardinal));
  end;
end;

end.
