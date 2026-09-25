object frmLoading: TfrmLoading
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Aguarde'
  ClientHeight = 120
  ClientWidth = 380
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCloseQuery = FormCloseQuery
  OnShow = FormShow
  TextHeight = 15
  object pnlClient: TPanel
    Left = 0
    Top = 0
    Width = 380
    Height = 120
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    ExplicitWidth = 378
    ExplicitHeight = 112
    object lblMensagem: TLabel
      Left = 16
      Top = 20
      Width = 348
      Height = 40
      AutoSize = False
      Caption = 'Aguarde...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      WordWrap = True
    end
    object barra: TProgressBar
      Left = 16
      Top = 76
      Width = 348
      Height = 20
      Style = pbstMarquee
      TabOrder = 0
    end
  end
end
