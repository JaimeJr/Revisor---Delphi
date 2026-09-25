object frmReenvio: TfrmReenvio
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Observa'#231#227'o para a IA'
  ClientHeight = 300
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  DesignSize = (
    640
    300)
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    ExplicitWidth = 638
    object lblInstrucao: TLabel
      Left = 16
      Top = 12
      Width = 608
      Height = 45
      AutoSize = False
      Caption = 
        'Descreva o ajuste desejado na nova an'#225'lise. A observa'#231#227'o tem pri' +
        'oridade sobre as regras gerais do prompt.'#13#10'Exemplos: "manter fra' +
        'ses curtas", "evitar reescrever di'#225'logo", "preservar repeti'#231#227'o i' +
        'ntencional".'
      WordWrap = True
    end
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 256
    Width = 640
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    ExplicitTop = 248
    ExplicitWidth = 638
    object btnCancelar: TButton
      Left = 416
      Top = 8
      Width = 100
      Height = 28
      Cancel = True
      Caption = 'Cancelar'
      TabOrder = 0
      OnClick = BtnCancelarClick
    end
    object btnReenviar: TButton
      Left = 524
      Top = 8
      Width = 100
      Height = 28
      Caption = 'Reenviar'
      Default = True
      TabOrder = 1
      OnClick = BtnReenviarClick
    end
  end
  object memObservacao: TMemo
    Left = 16
    Top = 72
    Width = 606
    Height = 172
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 2
    ExplicitWidth = 604
    ExplicitHeight = 164
  end
end
