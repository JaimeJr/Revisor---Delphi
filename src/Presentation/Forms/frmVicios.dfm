object frmVicios: TfrmVicios
  Left = 0
  Top = 0
  Caption = 'Cat'#225'logo de V'#237'cios'
  ClientHeight = 640
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object splitterLeft: TSplitter
    Left = 260
    Top = 40
    Height = 556
    ExplicitLeft = 264
    ExplicitTop = 48
    ExplicitHeight = 544
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    ExplicitWidth = 998
    object lblTitulo: TLabel
      Left = 12
      Top = 10
      Width = 142
      Height = 21
      Caption = 'Cat'#225'logo de V'#237'cios'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 596
    Width = 1000
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    ExplicitTop = 588
    ExplicitWidth = 998
    object btnNovo: TButton
      Left = 8
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Novo'
      TabOrder = 0
      OnClick = BtnNovoClick
    end
    object btnSalvar: TButton
      Left = 116
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Salvar'
      TabOrder = 1
      OnClick = BtnSalvarClick
    end
    object btnRemover: TButton
      Left = 224
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Remover'
      TabOrder = 2
      OnClick = BtnRemoverClick
    end
    object btnFechar: TButton
      Left = 892
      Top = 8
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Fechar'
      TabOrder = 3
      OnClick = BtnFecharClick
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 40
    Width = 260
    Height = 556
    Align = alLeft
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 2
    ExplicitHeight = 548
    object lstVicios: TListBox
      Left = 0
      Top = 0
      Width = 260
      Height = 556
      Align = alClient
      ItemHeight = 15
      TabOrder = 0
      OnClick = LstViciosClick
      ExplicitHeight = 548
    end
  end
  object pnlRight: TPanel
    Left = 263
    Top = 40
    Width = 737
    Height = 556
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 3
    ExplicitWidth = 735
    ExplicitHeight = 548
    DesignSize = (
      737
      556)
    object lblID: TLabel
      Left = 16
      Top = 16
      Width = 14
      Height = 15
      Caption = 'ID:'
    end
    object lblNome: TLabel
      Left = 16
      Top = 52
      Width = 36
      Height = 15
      Caption = 'Nome:'
    end
    object lblDescricao: TLabel
      Left = 16
      Top = 88
      Width = 54
      Height = 15
      Caption = 'Descri'#231#227'o:'
    end
    object lblDica: TLabel
      Left = 16
      Top = 208
      Width = 91
      Height = 15
      Caption = 'Dica de corre'#231#227'o:'
    end
    object lblGatilho: TLabel
      Left = 16
      Top = 328
      Width = 69
      Height = 15
      Caption = 'Gatilho local:'
    end
    object lblOrigem: TLabel
      Left = 16
      Top = 400
      Width = 43
      Height = 15
      Caption = 'Origem:'
    end
    object lblFrequencia: TLabel
      Left = 216
      Top = 400
      Width = 61
      Height = 15
      Caption = 'Frequ'#234'ncia:'
    end
    object lblOrigemValor: TLabel
      Left = 72
      Top = 400
      Width = 3
      Height = 15
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblFrequenciaValor: TLabel
      Left = 296
      Top = 400
      Width = 3
      Height = 15
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtID: TEdit
      Left = 16
      Top = 32
      Width = 400
      Height = 23
      TabOrder = 0
      OnChange = EdtIDChange
    end
    object edtNome: TEdit
      Left = 16
      Top = 68
      Width = 400
      Height = 23
      TabOrder = 1
    end
    object memDescricao: TMemo
      Left = 16
      Top = 104
      Width = 703
      Height = 90
      Anchors = [akLeft, akTop, akRight]
      ScrollBars = ssVertical
      TabOrder = 2
      ExplicitWidth = 701
    end
    object memDica: TMemo
      Left = 16
      Top = 224
      Width = 703
      Height = 90
      Anchors = [akLeft, akTop, akRight]
      ScrollBars = ssVertical
      TabOrder = 3
      ExplicitWidth = 701
    end
    object edtGatilho: TEdit
      Left = 16
      Top = 344
      Width = 703
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 4
      ExplicitWidth = 701
    end
    object chkCrossCena: TCheckBox
      Left = 16
      Top = 376
      Width = 300
      Height = 17
      Caption = 'Precisa de compara'#231#227'o cross-cena'
      TabOrder = 5
    end
  end
end
