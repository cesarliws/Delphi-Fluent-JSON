program FluentJSONTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  VSoft.Fluent.JSON in 'VSoft.Fluent.JSON.pas';

type
  TCustomer = class(TObject)
  private
    FBirthDate: TDateTime;
    FName: string;
  public
    property Name: string read FName write FName;
    property BirthDate: TDateTime read FBirthDate write FBirthDate;
  end;

procedure DoTest;
var
  builder : IFluentJSONBuilder;
  customer1, customer2: TCustomer;
begin
  customer1 := TCustomer.Create;
  customer1.Name := 'Customer Name';
  customer1.BirthDate := Now;

  customer2 := TCustomer.Create;
  customer2.Name := 'Another Customer';
  customer2.BirthDate := Now;

  builder := CreateJSON;

  builder.AddObject()
    .AddString('name1','value1\sdfgsdf')
    .AddString('name2','value2')
    .AddObject('customer', customer1)
    .AddNumber('name3',1234)
    .AddNumber('name4',1234.5678)
    .AddObject('child')
      .AddString('name4','value4')
      .AddNumber('name5',5678)
    .Up
    .AddString('Another','fgdfgdf')
    .AddArray('Array')
    .AddString('element1')
    .AddNumber(123456789)
    .Up
    .AddObject('customer', customer2);

  Writeln(builder.ToString);
  Writeln('');

  Writeln(builder.ToStringFmt);
  Writeln('');
  Readln;

  customer1.Free;
  customer2.Free;
end;

begin
  try
    DoTest;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
