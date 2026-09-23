program EditorManuscrito;

uses
  Vcl.Forms,
  frmPrincipal in 'src\Presentation\Forms\frmPrincipal.pas' {Form1},
  UValores in 'src\Domain\UValores.pas',
  UManuscrito in 'src\Domain\UManuscrito.pas',
  UEdicaoSugerida in 'src\Domain\UEdicaoSugerida.pas',
  UAnomaliaParser in 'src\Domain\UAnomaliaParser.pas',
  UServicosDominio in 'src\Domain\UServicosDominio.pas',
  UAnomaliaParse in 'src\Domain\UAnomaliaParse.pas',
  UChamada in 'src\Domain\UChamada.pas',
  UIParserManuscrito in 'src\Domain\Contratos\UIParserManuscrito.pas',
  UIDocxWriter in 'src\Domain\Contratos\UIDocxWriter.pas',
  UIDocxReader in 'src\Domain\Contratos\UIDocxReader.pas',
  UIAntesRepository in 'src\Domain\Contratos\UIAntesRepository.pas',
  UINovoRepository in 'src\Domain\Contratos\UINovoRepository.pas',
  UConfigApp in 'src\Infrastructure\Config\UConfigApp.pas',
  UKeyLoader in 'src\Infrastructure\Config\UKeyLoader.pas',
  UIRespostaRepository in 'src\Domain\Contratos\UIRespostaRepository.pas',
  UAntesJsonRepository in 'src\Infrastructure\Repos\UAntesJsonRepository.pas',
  UNovoJsonRepository in 'src\Infrastructure\Repos\UNovoJsonRepository.pas',
  UEnvioJsonRepository in 'src\Infrastructure\Repos\UEnvioJsonRepository.pas',
  UIEnvioRepository in 'src\Domain\Contratos\UIEnvioRepository.pas',
  UViciosJsonRepository in 'src\Infrastructure\Repos\UViciosJsonRepository.pas',
  UIViciosRepository in 'src\Domain\Contratos\UIViciosRepository.pas',
  UVicio in 'src\Domain\UVicio.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
