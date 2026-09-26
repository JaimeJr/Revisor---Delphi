object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'Editor de Manuscrito'
  ClientHeight = 720
  ClientWidth = 1280
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object splitterPrincipal: TSplitter
    Left = 300
    Top = 44
    Height = 654
    ExplicitLeft = 304
    ExplicitTop = 56
    ExplicitHeight = 640
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    ExplicitWidth = 1278
    object lblStatusAPI: TLabel
      Left = 1033
      Top = 13
      Width = 3
      Height = 15
    end
    object btnImportar: TButton
      Left = 8
      Top = 8
      Width = 90
      Height = 28
      Caption = 'Importar'
      TabOrder = 0
      OnClick = BtnImportarClick
    end
    object btnExportar: TButton
      Left = 106
      Top = 8
      Width = 90
      Height = 28
      Caption = 'Exportar'
      TabOrder = 1
      OnClick = BtnExportarClick
    end
    object btnVicios: TButton
      Left = 218
      Top = 8
      Width = 90
      Height = 28
      Caption = 'V'#237'cios'
      TabOrder = 2
      OnClick = BtnViciosClick
    end
    object btnRevisar: TButton
      Left = 330
      Top = 8
      Width = 160
      Height = 28
      Caption = 'Revisar selecionados'
      TabOrder = 3
      OnClick = BtnRevisarClick
    end
    object btnDesfazer: TButton
      Left = 647
      Top = 8
      Width = 180
      Height = 28
      Caption = 'Desfazer'
      TabOrder = 4
      OnClick = BtnDesfazerClick
    end
    object btnMarcarRevisados: TButton
      Left = 496
      Top = 9
      Width = 145
      Height = 25
      Caption = 'Revisado Manualmente'
      TabOrder = 5
      OnClick = btnMarcarRevisadosClick
    end
    object btnStatusAPI: TButton
      Left = 952
      Top = 9
      Width = 75
      Height = 25
      Caption = 'Status API'
      TabOrder = 6
      OnClick = btnStatusAPIClick
    end
  end
  object pnlArvore: TPanel
    Left = 0
    Top = 44
    Width = 300
    Height = 654
    Align = alLeft
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    ExplicitHeight = 646
    object treeEstrutura: TTreeView
      Left = 0
      Top = 0
      Width = 300
      Height = 654
      Align = alClient
      Indent = 19
      ReadOnly = True
      TabOrder = 0
      OnChange = TreeEstruturaChange
      ExplicitHeight = 646
    end
  end
  object pnlConteudo: TPanel
    Left = 303
    Top = 44
    Width = 977
    Height = 654
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 2
    ExplicitWidth = 975
    ExplicitHeight = 646
    object lblTituloCena: TLabel
      Left = 0
      Top = 0
      Width = 977
      Height = 21
      Align = alTop
      Alignment = taCenter
      Caption = 'Selecione uma cena na '#225'rvore'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ExplicitWidth = 229
    end
    object pnlCenaTopo: TPanel
      Left = 0
      Top = 21
      Width = 977
      Height = 36
      Align = alTop
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 0
      ExplicitWidth = 975
      object btnMarcarTodos: TButton
        Left = 8
        Top = 4
        Width = 120
        Height = 26
        Caption = 'Marcar todos'
        TabOrder = 0
        OnClick = BtnMarcarTodosClick
      end
      object btnDesmarcarTodos: TButton
        Left = 136
        Top = 4
        Width = 130
        Height = 26
        Caption = 'Desmarcar todos'
        TabOrder = 1
        OnClick = BtnDesmarcarTodosClick
      end
      object btnMarcarSuspeitos: TButton
        Left = 344
        Top = 4
        Width = 121
        Height = 26
        Caption = 'Marcar Suspeitos'
        TabOrder = 2
        OnClick = btnMarcarSuspeitosClick
      end
    end
    object pnlRodapeConteudo: TPanel
      Left = 0
      Top = 614
      Width = 977
      Height = 40
      Align = alBottom
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 1
      ExplicitTop = 606
      ExplicitWidth = 975
      object lblContador: TLabel
        Left = 966
        Top = 11
        Width = 3
        Height = 15
        Alignment = taRightJustify
        Layout = tlCenter
      end
      object cmbVicio: TComboBox
        Left = 8
        Top = 8
        Width = 240
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = CmbVicioChange
      end
    end
    object scrollParagrafos: TScrollBox
      Left = 0
      Top = 57
      Width = 977
      Height = 557
      HorzScrollBar.Smooth = True
      HorzScrollBar.Tracking = True
      HorzScrollBar.Visible = False
      VertScrollBar.Smooth = True
      VertScrollBar.Tracking = True
      Align = alClient
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      TabOrder = 2
      OnResize = ScrollParagrafosResize
      ExplicitWidth = 975
      ExplicitHeight = 549
    end
  end
  object statusBar: TStatusBar
    Left = 0
    Top = 698
    Width = 1280
    Height = 22
    Panels = <
      item
        Width = 500
      end
      item
        Width = 300
      end
      item
        Width = 200
      end>
    ExplicitTop = 690
    ExplicitWidth = 1278
  end
  object dlgAbrirDocx: TOpenDialog
    Filter = 'Documentos Word (*.docx)|*.docx|Todos os arquivos (*.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 1160
    Top = 8
  end
  object dlgSalvarDocx: TSaveDialog
    DefaultExt = 'docx'
    Filter = 'Documentos Word (*.docx)|*.docx|Todos os arquivos (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 1220
    Top = 8
  end
end
