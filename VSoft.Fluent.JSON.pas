{***************************************************************************}
{                                                                           }
{           VSoft.Fluent.JSON                                               }
{                                                                           }
{           Copyright (C) 2011 Vincent Parrett                              }
{                                                                           }
{           http://www.finalbuilder.com                                     }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit VSoft.Fluent.JSON;

interface

type
  IFluentJSONBuilder = interface
    ['{9574F82E-B81D-49B9-AA04-60EB87C60E8B}']
    function AddObject: IFluentJSONBuilder; overload;
    function AddObject(const name: string): IFluentJSONBuilder; overload;
    function AddObject(const name: string; value: TObject): IFluentJSONBuilder; overload;
    function AddNull(const name: string): IFluentJSONBuilder;
    function AddString(const name: string; const value: string): IFluentJSONBuilder; overload;
    function AddString(const value: string): IFluentJSONBuilder; overload;
    function AddNumber(const name: string; const value: Integer): IFluentJSONBuilder; overload;
    function AddNumber(const name: string; const value: Double): IFluentJSONBuilder; overload;
    function AddNumber(const value: Integer): IFluentJSONBuilder; overload;
    function AddNumber(const value: Double; const formatStr: string): IFluentJSONBuilder; overload;
    function AddArray(const name: string): IFluentJSONBuilder; overload;
    function AddArray: IFluentJSONBuilder; overload;
    function Up: IFluentJSONBuilder;
    function Mark: IFluentJSONBuilder;
    function Return: IFluentJSONBuilder;
    function ToString: string;
    function ToStringFmt: string;
    function Format(const value: string): string;
  end;

  // factory class
  TFluentJSON = class
    class function CreateJSONBuilder: IFluentJSONBuilder;
  end;

function CreateJSON: IFluentJSONBuilder;

implementation

uses
  Generics.Collections,
  REST.JSON,
  System.SysUtils;

type
  TJSONElementType = (etObject, etArray, etString, etInteger, etDouble, etBoolean, etNull);

  TJSONElement = class
  public
    Parent: TJSONElement;
    ElementType: TJSONElementType;
    Members: TList<TJSONElement>;
    Name: string;
    FormatStr: string;
    StringValue: string;

    Value: record
      case TJSONElementType of
        etBoolean:
          (BoolValue: Boolean);
        etDouble:
          (DoubleValue: Double);
        etInteger:
          (IntegerValue: Int64);
    end;

    function JSONEscapeString(const value: string): string;
    function ToString: string; override;
  public
    constructor Create(const AElementType: TJSONElementType; const formatString: string = '');
    destructor Destroy; override;
  end;

  TFluentJSONBuilder = class(TInterfacedObject, IFluentJSONBuilder)
  private
    FObjects: TList<TJSONElement>;
    FStack: TStack<TJSONElement>;
    FCurrentElement: TJSONElement;
    FMarkedObjects: TList<TJSONElement>;
  protected
    function AddObject: IFluentJSONBuilder; overload;
    function AddObject(const name: string): IFluentJSONBuilder; overload;
    function AddObject(const name: string; value: TObject): IFluentJSONBuilder; overload;
    function AddNull(const name: string): IFluentJSONBuilder;
    function AddString(const name: string; const value: string): IFluentJSONBuilder; overload;
    function AddString(const value: string): IFluentJSONBuilder; overload;
    function AddNumber(const name: string; const value: Integer): IFluentJSONBuilder; overload;
    function AddNumber(const name: string; const value: Double): IFluentJSONBuilder; overload;
    function AddNumber(const value: Integer): IFluentJSONBuilder; overload;
    function AddNumber(const value: Double; const formatStr: string): IFluentJSONBuilder; overload;
    function AddArray(const name: string): IFluentJSONBuilder; overload;
    function AddArray: IFluentJSONBuilder; overload;
    function Up: IFluentJSONBuilder;
    function Mark: IFluentJSONBuilder;
    function Return: IFluentJSONBuilder;
    function ToString: string; override;
    function ToStringFmt: string;
    function Format(const value: string): string;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TFluentJSON }

class function TFluentJSON.CreateJSONBuilder: IFluentJSONBuilder;
begin
  result := TFluentJSONBuilder.Create;
end;

function CreateJSON: IFluentJSONBuilder;
begin
  result := TFluentJSONBuilder.Create;
end;

{ TFluentJSONBuilder }

function TFluentJSONBuilder.AddArray(const name: string): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etObject, etArray]);
  newElement := TJSONElement.Create(etArray);
  newElement.Name := name;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
  begin
    FCurrentElement.Members.Add(newElement);
    FStack.Push(FCurrentElement);
  end;
  FCurrentElement := newElement;
  result := Self;
end;

function TFluentJSONBuilder.AddNumber(const name: string; const value: Double): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etObject, etArray]);
  newElement := TJSONElement.Create(etDouble);
  newElement.Name := name;
  newElement.Value.DoubleValue := value;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
    FCurrentElement.Members.Add(newElement);
  result := Self;
end;

function TFluentJSONBuilder.AddObject: IFluentJSONBuilder;
begin
  result := AddObject('');
end;

function TFluentJSONBuilder.AddNumber(const name: string; const value: Integer): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etObject, etArray]);
  newElement := TJSONElement.Create(etInteger);
  newElement.Name := name;
  newElement.Value.IntegerValue := value;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
    FCurrentElement.Members.Add(newElement);
  result := Self;
end;

function TFluentJSONBuilder.AddNumber(const value: Integer): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etArray]);
  newElement := TJSONElement.Create(etInteger);
  newElement.Name := '';
  newElement.Value.IntegerValue := value;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
    FCurrentElement.Members.Add(newElement);
  result := Self;
end;

function TFluentJSONBuilder.AddArray: IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etArray]);
  newElement := TJSONElement.Create(etArray);
  newElement.Name := '';
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
  begin
    FCurrentElement.Members.Add(newElement);
    FStack.Push(FCurrentElement);
  end;
  FCurrentElement := newElement;
  result := Self;
end;

function TFluentJSONBuilder.AddNull(const name: string): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etObject, etArray]);
  newElement := TJSONElement.Create(etNull);
  newElement.Name := name;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
    FCurrentElement.Members.Add(newElement);
  result := Self;
end;

function TFluentJSONBuilder.AddNumber(const value: Double; const formatStr: string): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etArray]);
  newElement := TJSONElement.Create(etInteger);
  newElement.Name := '';
  newElement.Value.DoubleValue := value;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
    FCurrentElement.Members.Add(newElement);
  result := Self;
end;

function TFluentJSONBuilder.AddObject(const name: string): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  newElement := TJSONElement.Create(etObject);
  newElement.Parent := FCurrentElement;
  newElement.Name := name;
  if FCurrentElement = nil then
    FObjects.Add(newElement)
  else
  begin
    FCurrentElement.Members.Add(newElement);
    FStack.Push(FCurrentElement);
  end;
  FCurrentElement := newElement;
  result := Self;
end;

function TFluentJSONBuilder.AddString(const value: string): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etArray]);
  newElement := TJSONElement.Create(etString);
  newElement.Name := '';
  newElement.StringValue := value;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
    FCurrentElement.Members.Add(newElement);
  result := Self;
end;

function TFluentJSONBuilder.AddString(const name, value: string): IFluentJSONBuilder;
var
  newElement: TJSONElement;
begin
  Assert(FCurrentElement <> nil);
  Assert(FCurrentElement.ElementType in [etObject, etArray]);
  newElement := TJSONElement.Create(etString);
  newElement.Name := name;
  newElement.StringValue := value;
  newElement.Parent := FCurrentElement;
  if FCurrentElement <> nil then
    FCurrentElement.Members.Add(newElement);
  result := Self;
end;

constructor TFluentJSONBuilder.Create;
begin
  FObjects := TList<TJSONElement>.Create;
  FStack := TStack<TJSONElement>.Create;
  FMarkedObjects := TList<TJSONElement>.Create;
  FCurrentElement := nil;
end;

destructor TFluentJSONBuilder.Destroy;
var
  element: TJSONElement;
begin
  for element in FObjects do
  begin
    element.Free;
  end;
  FObjects.Free;
  FStack.Free;
  inherited;
end;

function TFluentJSONBuilder.AddObject(const name: string; value: TObject): IFluentJSONBuilder;
begin
  AddObject(name);
  FCurrentElement.Members.Add(TJSONElement.Create(etObject, TJson.ObjectToJsonString(value)));
  Up;
  result := Self;
end;

function TFluentJSONBuilder.ToStringFmt: string;
begin
  result := Format(ToString);
end;

function TFluentJSONBuilder.Format(const value: string): string;
const
  DEFAULT_INDENT = '  ';
var
  c: Char;
  indent: string;
  isEOL: Boolean;
  isEscape: Boolean;
  isInString: Boolean;
begin
  isEOL      := True;
  isInString := False;
  isEscape   := False;

  for c in value do
  begin
    if not isInString and ((c = '{') or (c = '[')) then
    begin
      result := result + c + sLineBreak;
      indent := indent + DEFAULT_INDENT;
      result := result + indent;
      isEOL  := True;
    end
    else
    if not isInString and (c = ',') then
    begin
      isEOL := False;
      result := result + c + sLineBreak + indent;
    end
    else
    if not isInString and ((c = '}') or (c = ']')) then
    begin
      Delete(indent, 1, Length(DEFAULT_INDENT));
      if not isEOL then
      begin
        result := result + sLineBreak;
      end;
      result := result + indent + c;
    end
    else
    begin
      isEOL := False;
      result := result + c;
    end;

    isEscape := (c = '\') and not isEscape;
    if not isEscape and (c = '"') then
    begin
      isInString := not isInString;
    end;
  end;
end;

function TFluentJSONBuilder.Mark: IFluentJSONBuilder;
begin
  result := Self;
  Assert(FCurrentElement <> nil);
  FMarkedObjects.Add(FCurrentElement);
end;

function TFluentJSONBuilder.Return: IFluentJSONBuilder;
begin
  result := Self;
  Assert(FMarkedObjects.Count > 0);
  FCurrentElement := FMarkedObjects.Last;
end;

function TFluentJSONBuilder.ToString: string;
var
  element: TJSONElement;
begin
  result := '';
  for element in FObjects do
  begin
    result := result + element.ToString;
  end;
end;

function TFluentJSONBuilder.Up: IFluentJSONBuilder;
begin
  if FStack.Count > 0 then
    FCurrentElement := FStack.Pop
  else
    FCurrentElement := nil;
  result := Self;

end;

{ TJSONElement }

constructor TJSONElement.Create(const AElementType: TJSONElementType; const formatString: string = '');
begin
  ElementType := AElementType;
  if ElementType in [etObject, etArray] then
    Members := TList<TJSONElement>.Create
  else
    Members := nil;
  FormatStr := formatString;
end;

destructor TJSONElement.Destroy;
var
  element: TJSONElement;
begin
  if Members <> nil then
  begin
    for element in Members do
    begin
      element.Free;
    end;
    Members.Free;
  end;
  inherited;
end;

function TJSONElement.JSONEscapeString(const value: string): string;
var
  c: Char;
  i: Integer;
  count: Integer;
begin
  result := '';
  count := Length(value);
  for i := 1 to count do
  begin
    c := value[i];
    case c of
      '"' : result := result + '\"';
      '\' : result := result + '\\';
      '/' : result := result + '\/';
      #8 : result := result + '\b';
      #9 : result := result + '\t';
      #10 : result := result + '\n';
      #12 : result := result + '\f';
      #13 : result := result + '\r';
    else
      // TODO : Deal with unicode characters properly!
      result := result + c;
    end;
  end;
end;

function TJSONElement.ToString: string;
var
  member: TJSONElement;
  i: Integer;
  formatSettings: TFormatSettings;
  objectValue: string;
begin
  formatSettings := TFormatSettings.Create;
  formatSettings.DecimalSeparator := '.';
  result := '';
  case ElementType of
    etObject:
      begin
        if Parent <> nil then
          result := '"' + JSONEscapeString(Self.Name) + '":';

        if FormatStr <> '' then
        begin
          objectValue := Trim(FormatStr);
          if objectValue[1] = '{' then
          begin
            Delete(objectValue, 1, 1);
          end;

          i := Length(objectValue);
          if objectValue[i] = '}' then
          begin
            Delete(objectValue, i, 1);
          end;

          result := result + objectValue;
        end
        else
        begin
          result := result + '{';
          if Members.Count > 0 then
          begin
            for i := 0 to Self.Members.Count - 1 do
            begin
              member := Self.Members[i];
              result := result + member.ToString;
              if i < Self.Members.Count - 1 then
                result := result + ',';
            end;
          end;
          result := result + '}';
        end;
      end;
    etArray:
      begin
        if Parent <> nil then
        begin
          case Parent.ElementType of
            etObject:
              result := result + '"' + JSONEscapeString(Self.Name) + '":[';
            etArray:
              result := result + '[';
          end;
        end;
        if Members.Count > 0 then
        begin
          for i := 0 to Members.Count - 1 do
          begin
            member := Members[i];
            if i > 0 then
              result := result + ',';
            result := result + member.ToString;
          end;
        end;
        result := result + ']';
      end;
    etString:
      begin
        if ((Self.Parent <> nil) and (Self.Parent.ElementType = etArray)) or (Self.Name = '') then
          result := '"' + JSONEscapeString(Self.StringValue) + '"'
        else
          result := '"' + JSONEscapeString(Self.Name) + '":"' + JSONEscapeString(Self.StringValue) + '"';
      end;
    etInteger:
      begin
        if ((Self.Parent <> nil) and (Self.Parent.ElementType = etArray)) or (Self.Name = '') then
          result := IntToStr(Self.Value.IntegerValue)
        else
          result := '"' + JSONEscapeString(Self.Name) + '":' + IntToStr(Self.Value.IntegerValue);
      end;
    etDouble:
      begin
        if ((Self.Parent <> nil) and (Self.Parent.ElementType = etArray)) or (Self.Name = '') then
          result := FloatToStr(Self.Value.DoubleValue, formatSettings)
        else
          result := '"' + JSONEscapeString(Self.Name) + '":' + FloatToStr(Self.Value.DoubleValue, formatSettings);
      end;
    etBoolean:
      begin
        if ((Self.Parent <> nil) and (Self.Parent.ElementType = etArray)) or (Self.Name = '') then
          result := LowerCase(BoolToStr(Self.Value.BoolValue, True))
        else
          result := '"' + JSONEscapeString(Self.Name) + '":' + LowerCase(BoolToStr(Self.Value.BoolValue, True));
      end;
    etNull:
      begin
        if ((Self.Parent <> nil) and (Self.Parent.ElementType = etArray)) or (Self.Name = '') then
          result := 'null'
        else
          result := '"' + JSONEscapeString(Self.Name) + '":null';
      end;
  end;
end;

end.
