unit mainunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, SysUtils, SynEdit, SynHighlighterAny, Forms,
  Controls, Dialogs, ComCtrls, Menus, ActnList, StdCtrls, ExtCtrls,
  XMLPropStorage, LazSerial;

type

  { TMainForm }

  TMainForm = class(TForm)
    acAbrir: TAction;
    acEnviar: TAction;
    acSalir: TAction;
    acConfigPuertoSerie: TAction;
    acPreferencias: TAction;
    acLineaActual: TAction;
    acRangoLineas: TAction;
    acCicloVacio: TAction;
    acConectar: TAction;
    acDesconectar: TAction;
    acDetener: TAction;
    ActionList1: TActionList;
    imgAcciones: TImageList;
    imBookMarks: TImageList;
    MenuItem10: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    mnDetener: TMenuItem;
    mmPuertoSerie: TMemo;
    PuertoSerie: TLazSerial;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    mnEnviarLineaActual: TMenuItem;
    mnEnviarRangoLineas: TMenuItem;
    mnCicloEnVacio: TMenuItem;
    mnDepurar: TMenuItem;
    mnPreferencias: TMenuItem;
    mnHerramientas: TMenuItem;
    mnSalir: TMenuItem;
    OpenDialog1: TOpenDialog;
    Editor: TSynEdit;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    SynAnySyn1: TSynAnySyn;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    XMLPropStorage1: TXMLPropStorage;
    procedure acAbrirExecute(Sender: TObject);
    procedure acCicloVacioExecute(Sender: TObject);
    procedure acConectarExecute(Sender: TObject);
    procedure acConfigPuertoSerieExecute(Sender: TObject);
    procedure acDesconectarExecute(Sender: TObject);
    procedure acDetenerExecute(Sender: TObject);
    procedure acEnviarExecute(Sender: TObject);
    procedure acRangoLineasExecute(Sender: TObject);
    procedure acSalirExecute(Sender: TObject);
    procedure EditorMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure FormCreate(Sender: TObject);
    procedure PuertoSerieRxData(Sender: TObject);
  private
    { private declarations }
    Stop: boolean;
    Titulo: string;
    procedure EnviarPuertoSerie(Cadena: string);
    procedure ProcesaLinea(aCadena: string; Vacio: boolean = False);
    procedure Inactivo(TSender: TObject; var done: boolean);
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses SynEditTypes;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.acAbrirExecute(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Editor.ClearAll;
    Editor.Lines.LoadFromFile(OpenDialog1.FileName);
    Caption := Titulo + ' [' + OpenDialog1.FileName + ']';
  end;
end;

procedure TMainForm.acCicloVacioExecute(Sender: TObject);
var
  Indice: integer;
  R: TModalResult;
begin
  R := MessageDlg('Depurar', '¿Deseas ejecutar el ciclo en vacio?',
    mtConfirmation, mbYesNo, 0, mbNo);
  if r <> mrYes then
    Exit;
  Indice := 0;
  Stop := False;
  acDetener.Enabled := True;
  while (Indice < Editor.Lines.Count) and (Stop = False) do
  begin
    ProcesaLinea(Editor.Lines[Indice], True);
    Indice := Indice + 1;
  end;
end;

procedure TMainForm.acConectarExecute(Sender: TObject);
begin
  if not PuertoSerie.Active then
  begin
    try
      PuertoSerie.Open;
    except
      On E: Exception do
      begin
        MessageDlg('Puerto Serie', 'Error comunicando por el puerto ' +
          PuertoSerie.Device, mtError, [mbYes], 0);
        PuertoSerie.Active := False;
      end;
    end;
  end;
end;

procedure TMainForm.acConfigPuertoSerieExecute(Sender: TObject);
begin
  PuertoSerie.ShowSetupDialog;
end;

procedure TMainForm.acDesconectarExecute(Sender: TObject);
begin
  if PuertoSerie.Active then
  begin
    Stop := True;
    PuertoSerie.Close;
  end;
end;

procedure TMainForm.acDetenerExecute(Sender: TObject);
begin
  Stop := True;
end;

procedure TMainForm.acEnviarExecute(Sender: TObject);
var
  Linea: string;
begin
  //ShowMessage (Sender.ClassName);
  Linea := UpperCase(Trim(Editor.Lines[Editor.CaretY - 1]));
  ProcesaLinea(Linea);
end;

procedure TMainForm.acRangoLineasExecute(Sender: TObject);
var
  P1: TPoint;
  P2: TPoint;
  Indice: integer;
  R: TModalResult;
begin
  P1 := Editor.BlockBegin;
  P2 := Editor.BlockEnd;
  R := MessageDlg('Depurar', '¿Desear enviar el rango de líneas a la impresora?',
    mtConfirmation, mbYesNo, 0, mbNo);
  if R <> mrYes then
    Exit;
  Indice := P1.Y - 1;
  Stop := False;
  while (Indice < P2.Y) and (Stop = False) do
  begin
    ProcesaLinea(Editor.Lines[Indice], True);
    // mmPuertoSerie.Lines.Add(Editor.Lines[Indice]);
    Indice := Indice + 1;
  end;
end;

procedure TMainForm.acSalirExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.EditorMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  StatusBar1.Panels[0].Text := Format('%d:%d', [Editor.CaretY, Editor.CaretX]);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Stop := True;
  Editor.SelectionMode := smline;
  Titulo := Caption;
  Application.OnIdle := @Inactivo;
end;

procedure TMainForm.PuertoSerieRxData(Sender: TObject);
var
  Cadena: string;
begin
  Cadena := PuertoSerie.ReadData;
  mmPuertoSerie.Lines.Add(Cadena);
end;

procedure TMainForm.EnviarPuertoSerie(Cadena: string);
begin

  if not PuertoSerie.Active then
  begin
    mmPuertoSerie.Lines.Add('El puerto serie no está abierto');
    Stop := True;
    Exit;
  end;
  PuertoSerie.WriteData(Cadena);

end;

procedure TMainForm.ProcesaLinea(aCadena: string; Vacio: boolean);
var
  PrimerCaracter: string;
  P: SizeInt;
begin
  if Length(aCadena) < 1 then
    Exit;

  PrimerCaracter := Copy(aCadena, 1, 1);
  if PrimerCaracter = ';' then
    Exit;

  P := Pos(';', aCadena);
  if P > 0 then
  begin
    aCadena := Copy(aCadena, 0, P - 1);
  end;

  if (PrimerCaracter = 'M') and (Vacio = False) then
    //Enviar al puerto serie
    EnviarPuertoSerie(aCadena);

  if PrimerCaracter = 'G' then
  begin
    //Enviar solo orden de movimiento.
    P := Pos('E', aCadena);
    if P > 0 then
    begin
      aCadena := Copy(aCadena, 0, P - 1);
    end;
    P := Pos('F', aCadena);
    if P > 0 then
    begin
      aCadena := Copy(aCadena, 0, P - 1);
    end;
    EnviarPuertoSerie(aCadena);
  end;
end;

procedure TMainForm.Inactivo(TSender: TObject; var done: boolean);
var
  B: TBaudRate;
  I: longint;
begin
  acDesconectar.Enabled := PuertoSerie.Active;
  acConectar.Enabled := not PuertoSerie.Active;
  acEnviar.Enabled := Editor.Lines.Count > 0;
  acLineaActual.Enabled := Editor.Lines.Count > 0;
  acDetener.Enabled := not Stop;
  acCicloVacio.Enabled := (Stop) and (Editor.Lines.Count > 0);
  acRangoLineas.Enabled := Editor.SelAvail;
  //Estado de la conexión
  if PuertoSerie.Active then
  begin
    B := PuertoSerie.BaudRate;
    I := ConstsBaud[B];
    StatusBar1.Panels[1].Text :=
      'Conectado ' + PuertoSerie.Device + ' Baudios: ' + IntToStr(I);
  end
  else
  begin
    StatusBar1.Panels[1].Text := 'Desconectado';
  end;
  done := True;
end;

end.
