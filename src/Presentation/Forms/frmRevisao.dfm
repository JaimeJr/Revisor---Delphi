object frmRevisao: TfrmRevisao
  Left = 0
  Top = 0
  Caption = 'Revis'#227'o'
  ClientHeight = 640
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    ExplicitWidth = 1098
    object lblTitulo: TLabel
      Left = 12
      Top = 11
      Width = 59
      Height = 21
      Caption = 'Revis'#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblStatusParse: TLabel
      Left = 1085
      Top = 15
      Width = 3
      Height = 15
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 574
    Width = 1100
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    ExplicitTop = 566
    ExplicitWidth = 1098
    object btnRecusarTudo: TButton
      Left = 8
      Top = 8
      Width = 120
      Height = 28
      Caption = 'Recusar tudo'
      TabOrder = 0
      OnClick = BtnRecusarTudoClick
    end
    object btnReenviar: TButton
      Left = 136
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Reenviar...'
      TabOrder = 1
      OnClick = BtnReenviarClick
    end
    object btnAceitarSelecionadas: TButton
      Left = 320
      Top = 8
      Width = 170
      Height = 28
      Caption = 'Aceitar selecionadas'
      TabOrder = 2
      OnClick = BtnAceitarSelecionadasClick
    end
    object btnAceitarTudo: TButton
      Left = 498
      Top = 8
      Width = 120
      Height = 28
      Caption = 'Aceitar tudo'
      TabOrder = 3
      OnClick = BtnAceitarTudoClick
    end
    object btnExibirRespostaBruta: TButton
      Left = 850
      Top = 8
      Width = 240
      Height = 28
      Caption = 'Exibir resposta bruta'
      TabOrder = 4
      Visible = False
      OnClick = BtnExibirRespostaBrutaClick
    end
  end
  object statusBar: TStatusBar
    Left = 0
    Top = 618
    Width = 1100
    Height = 22
    Panels = <
      item
        Width = 180
      end
      item
        Width = 180
      end
      item
        Width = 250
      end>
    ExplicitTop = 610
    ExplicitWidth = 1098
  end
  object pnlBody: TPanel
    Left = 0
    Top = 44
    Width = 1100
    Height = 530
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 2
    ExplicitWidth = 1098
    ExplicitHeight = 522
    object splitterLista: TSplitter
      Left = 340
      Top = 0
      Height = 530
      ExplicitLeft = 336
      ExplicitTop = 8
      ExplicitHeight = 528
    end
    object pnlLista: TPanel
      Left = 0
      Top = 0
      Width = 340
      Height = 530
      Align = alLeft
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 0
      ExplicitHeight = 522
      object lstEdicoes: TListView
        Left = 0
        Top = 0
        Width = 340
        Height = 530
        Align = alClient
        Checkboxes = True
        Columns = <
          item
            Caption = 'Par'#225'grafo'
            Width = 90
          end
          item
            Caption = 'V'#237'cio'
            Width = 110
          end
          item
            Caption = 'Motivo'
            Width = 120
          end>
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnSelectItem = LstEdicoesSelectItem
        OnItemChecked = LstEdicoesItemChecked
      end
    end
    object pnlMemos: TPanel
      Left = 343
      Top = 0
      Width = 757
      Height = 530
      Align = alClient
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 1
      ExplicitWidth = 755
      ExplicitHeight = 522
      object splitterMemos: TSplitter
        Left = 376
        Top = 0
        Height = 530
        ExplicitLeft = 372
        ExplicitTop = 8
        ExplicitHeight = 528
      end
      object pnlAntigo: TPanel
        Left = 0
        Top = 0
        Width = 376
        Height = 530
        Align = alLeft
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        ExplicitHeight = 522
        object lblAntigo: TLabel
          Left = 0
          Top = 0
          Width = 376
          Height = 15
          Align = alTop
          Caption = '   Texto original'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitWidth = 85
        end
        object memAntigo: TMemo
          Left = 0
          Top = 15
          Width = 376
          Height = 515
          Align = alClient
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
          ExplicitHeight = 507
        end
      end
      object pnlNovo: TPanel
        Left = 379
        Top = 0
        Width = 378
        Height = 530
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 1
        ExplicitWidth = 376
        ExplicitHeight = 522
        object lblNovo: TLabel
          Left = 0
          Top = 0
          Width = 378
          Height = 15
          Align = alTop
          Caption = '   Texto sugerido'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Layout = tlCenter
          ExplicitWidth = 92
        end
        object memNovo: TMemo
          Left = 0
          Top = 15
          Width = 378
          Height = 515
          Align = alClient
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
          ExplicitWidth = 376
          ExplicitHeight = 507
        end
      end
    end
  end
end
