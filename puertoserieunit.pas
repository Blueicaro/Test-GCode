unit PuertoSerieUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ButtonPanel;

type

  { TPuertoSerieFrm }

  TPuertoSerieFrm = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbVelocidad: TComboBox;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  PuertoSerieFrm: TPuertoSerieFrm;

implementation

{$R *.lfm}

{ TPuertoSerieFrm }

procedure TPuertoSerieFrm.FormCreate(Sender: TObject);
begin

end;

end.

