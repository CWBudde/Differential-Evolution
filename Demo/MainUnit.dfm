object FmDifferentialEvolution: TFmDifferentialEvolution
  Left = 0
  Top = 0
  Caption = 'Differential Evolution Demo'
  ClientHeight = 301
  ClientWidth = 562
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Chart: TChart
    Left = 0
    Top = 0
    Width = 562
    Height = 282
    Title.Font.Color = clBlack
    Title.Font.Style = [fsBold]
    Title.Font.Shadow.Color = 9934743
    Title.Font.Shadow.HorizSize = 1
    Title.Font.Shadow.VertSize = 1
    Title.Text.Strings = (
      'Optimize Chart')
    SeriesGroups = <
      item
        Name = 'Group1'
      end>
    Shadow.SmoothBlur = 3
    View3D = False
    View3DWalls = False
    Align = alClient
    TabOrder = 0
    PrintMargins = (
      15
      23
      15
      23)
    ColorPaletteIndex = 13
    object SeriesReference: TLineSeries
      Marks.Arrow.Visible = True
      Marks.Callout.Brush.Color = clBlack
      Marks.Callout.Arrow.Visible = True
      Marks.Visible = False
      Pointer.Brush.Gradient.EndColor = 10708548
      Pointer.Gradient.EndColor = 10708548
      Pointer.HorizSize = 2
      Pointer.InflateMargins = True
      Pointer.Style = psCircle
      Pointer.VertSize = 2
      Pointer.Visible = True
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
      object ReferenceFunction: TCustomTeeFunction
        CalcByValue = False
        Period = 0.020000000000000000
        NumPoints = 101
        StartX = -1.000000000000000000
        OnCalculate = ReferenceFunctionCalculate
      end
    end
    object SeriesOptimized: TLineSeries
      Marks.Arrow.Visible = True
      Marks.Callout.Brush.Color = clBlack
      Marks.Callout.Arrow.Visible = True
      Marks.Visible = False
      Pointer.InflateMargins = True
      Pointer.Style = psRectangle
      Pointer.Visible = False
      XValues.Name = 'X'
      XValues.Order = loAscending
      YValues.Name = 'Y'
      YValues.Order = loNone
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 282
    Width = 562
    Height = 19
    Panels = <
      item
        Width = 96
      end
      item
        Width = 200
      end>
  end
  object DifferentialEvolution: TNewDifferentialEvolution
    CrossOver = 0.900000000000000000
    DifferentialWeight = 0.400000000000000000
    PopulationCount = 1000
    Variables = <
      item
        DisplayName = 'x_0'
        Minimum = -1.000000000000000000
        Maximum = 1.000000000000000000
      end
      item
        DisplayName = 'x_1'
        Minimum = -1.000000000000000000
        Maximum = 1.000000000000000000
      end
      item
        DisplayName = 'x_2'
        Minimum = -1.000000000000000000
        Maximum = 1.000000000000000000
      end
      item
        DisplayName = 'x_3'
        Minimum = -1.000000000000000000
        Maximum = 1.000000000000000000
      end
      item
        DisplayName = 'x_4'
        Minimum = -1.000000000000000000
        Maximum = 1.000000000000000000
      end>
    OnCalculateCosts = DECalculateCosts
    OnBestCostChanged = DEBestCostChanged
    OnGenerationChanged = DEGenerationChanged
    Left = 256
    Top = 40
  end
  object MainMenu: TMainMenu
    Left = 184
    Top = 40
    object MiFile: TMenuItem
      Caption = '&File'
      object MiExit: TMenuItem
        Caption = 'E&xit'
        OnClick = MiExitClick
      end
    end
    object MiOptimization: TMenuItem
      Caption = '&Optimization'
      object MiStart: TMenuItem
        Caption = '&Start'
        ShortCut = 120
        OnClick = MiStartClick
      end
      object MiStop: TMenuItem
        Caption = 'S&top'
        ShortCut = 121
        OnClick = MiStopClick
      end
      object MiReset: TMenuItem
        Caption = '&Reset'
        ShortCut = 119
        OnClick = MiResetClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object MiSingleStep: TMenuItem
        Caption = 'Single Step'
        ShortCut = 118
        OnClick = MiSingleStepClick
      end
    end
  end
end
