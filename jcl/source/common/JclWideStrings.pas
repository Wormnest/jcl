{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: WStrUtils.PAS, released on 2004-01-25

The Initial Developers of the Original Code are: Andreas Hausladen <Andreas dott Hausladen att gmx dott de>
All Rights Reserved.

Contributors:
  Robert Marquardt (marquardt)
  Robert Rossmair (rrossmair)

You may retrieve the latest version of this file at the Project JEDI's JCL home page,
located at http://jcl.sourceforge.net

This is a lightweight Unicode unit. For more features use JclUnicode.

Known Issues:
-----------------------------------------------------------------------------}

unit JclWideStrings;

{$I jcl.inc}

interface

uses
  Classes, SysUtils;

const
  BOM_LSB_FIRST = WideChar($FEFF);
  BOM_MSB_FIRST = WideChar($FFFE);

type
  TWideFileOptionsType =
   (
    foAnsiFile,  // loads/writes an ANSI file
    foUnicodeLB  // reads/writes BOM_LSB_FIRST/BOM_MSB_FIRST
   );
  TWideFileOptions = set of TWideFileOptionsType;

  TSearchFlag = (
    sfCaseSensitive,    // match letter case
    sfIgnoreNonSpacing, // ignore non-spacing characters in search
    sfSpaceCompress,    // handle several consecutive white spaces as one white space
                        // (this applies to the pattern as well as the search text)
    sfWholeWordOnly     // match only text at end/start and/or surrounded by white spaces
  );
  TSearchFlags = set of TSearchFlag;

  TWStrings = class;
  TWStringList = class;

  TWStringListSortCompare = function(List: TWStringList; Index1, Index2: Integer): Integer;

  TWStrings = class(TPersistent)
  private
    FDelimiter: WideChar;
    FQuoteChar: WideChar;
    FNameValueSeparator: WideChar;
    FLineSeparator: WideString;
    FUpdateCount: Integer;
    function GetCommaText: WideString;
    function GetDelimitedText: WideString;
    function GetName(Index: Integer): WideString;
    function GetValue(const Name: WideString): WideString;
    procedure ReadData(Reader: TReader);
    procedure SetCommaText(const Value: WideString);
    procedure SetDelimitedText(const Value: WideString);
    procedure SetValue(const Name, Value: WideString);
    procedure WriteData(Writer: TWriter);
    function GetValueFromIndex(Index: Integer): WideString;
    procedure SetValueFromIndex(Index: Integer; const Value: WideString);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function ExtractName(const S: WideString): WideString;
    function GetP(Index: Integer): PWideString; virtual; abstract;
    function Get(Index: Integer): WideString; 
    function GetCapacity: Integer; virtual;
    function GetCount: Integer; virtual; abstract;
    function GetObject(Index: Integer): TObject; virtual;
    function GetTextStr: WideString; virtual;
    procedure Put(Index: Integer; const S: WideString); virtual; abstract;
    procedure PutObject(Index: Integer; AObject: TObject); virtual; abstract;
    procedure SetCapacity(NewCapacity: Integer); virtual;
    procedure SetTextStr(const Value: WideString); virtual;
    procedure SetUpdateState(Updating: Boolean); virtual;
    property UpdateCount: Integer read FUpdateCount;
    function CompareStrings(const S1, S2: WideString): Integer; virtual;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    function Add(const S: WideString): Integer; virtual;
    function AddObject(const S: WideString; AObject: TObject): Integer; virtual;
    procedure Append(const S: WideString);
    procedure AddStrings(Strings: TWStrings); overload; virtual;
    procedure AddStrings(Strings: TStrings); overload; virtual;
    procedure Assign(Source: TPersistent); override;
    function CreateAnsiStringList: TStrings;
    procedure AddStringsTo(Dest: TStrings); virtual;
    procedure BeginUpdate;
    procedure Clear; virtual; abstract;
    procedure Delete(Index: Integer); virtual; abstract;
    procedure EndUpdate;
    function Equals(Strings: TWStrings): Boolean; overload;
    function Equals(Strings: TStrings): Boolean; overload;
    procedure Exchange(Index1, Index2: Integer); virtual;
    function GetText: PWideChar; virtual;
    function IndexOf(const S: WideString): Integer; virtual;
    function IndexOfName(const Name: WideString): Integer; virtual;
    function IndexOfObject(AObject: TObject): Integer; virtual;
    procedure Insert(Index: Integer; const S: WideString); virtual;
    procedure InsertObject(Index: Integer; const S: WideString;
      AObject: TObject); virtual;
    procedure LoadFromFile(const FileName: AnsiString;
      WideFileOptions: TWideFileOptions = []); virtual;
    procedure LoadFromStream(Stream: TStream;
      WideFileOptions: TWideFileOptions = []); virtual;
    procedure Move(CurIndex, NewIndex: Integer); virtual;
    procedure SaveToFile(const FileName: AnsiString;
      WideFileOptions: TWideFileOptions = []); virtual;
    procedure SaveToStream(Stream: TStream;
      WideFileOptions: TWideFileOptions = []); virtual;
    procedure SetText(Text: PWideChar); virtual;
    function GetDelimitedTextEx(ADelimiter, AQuoteChar: WideChar): WideString;
    procedure SetDelimitedTextEx(ADelimiter, AQuoteChar: WideChar; const Value: WideString);
    property Capacity: Integer read GetCapacity write SetCapacity;
    property CommaText: WideString read GetCommaText write SetCommaText;
    property Count: Integer read GetCount;
    property Delimiter: WideChar read FDelimiter write FDelimiter;
    property DelimitedText: WideString read GetDelimitedText write SetDelimitedText;
    property Names[Index: Integer]: WideString read GetName;
    property Objects[Index: Integer]: TObject read GetObject write PutObject;
    property QuoteChar: WideChar read FQuoteChar write FQuoteChar;
    property Values[const Name: WideString]: WideString read GetValue write SetValue;
    property ValueFromIndex[Index: Integer]: WideString read GetValueFromIndex write SetValueFromIndex;
    property NameValueSeparator: WideChar read FNameValueSeparator write FNameValueSeparator;
    property LineSeparator: WideString read FLineSeparator write FLineSeparator;
    property PStrings[Index: Integer]: PWideString read GetP;
    property Strings[Index: Integer]: WideString read Get write Put; default;
    property Text: WideString read GetTextStr write SetTextStr;
  end;

  // do not replace by JclUnicode.TWideStringList (speed and size issue)
  PWStringItem = ^TWStringItem;
  TWStringItem = record
    FString: WideString;
    FObject: TObject;
  end;

  TWStringList = class(TWStrings)
  private
    FList: TList;
    FSorted: Boolean;
    FDuplicates: TDuplicates;
    FCaseSensitive: Boolean;
    FOnChange: TNotifyEvent;
    FOnChanging: TNotifyEvent;
    procedure SetSorted(Value: Boolean);
    procedure SetCaseSensitive(const Value: Boolean);
  protected
    function GetItem(Index: Integer): PWStringItem;
    procedure Changed; virtual;
    procedure Changing; virtual;
    function GetP(Index: Integer): PWideString; override;
    function GetCapacity: Integer; override;
    function GetCount: Integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const Value: WideString); override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure SetCapacity(NewCapacity: Integer); override;
    procedure SetUpdateState(Updating: Boolean); override;
    function CompareStrings(const S1, S2: WideString): Integer; override;
  public
    constructor Create;
    destructor Destroy; override;
    function AddObject(const S: WideString; AObject: TObject): Integer; override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Exchange(Index1, Index2: Integer); override;
    function Find(const S: WideString; var Index: Integer): Boolean; virtual;
    // Find() also works with unsorted lists
    function IndexOf(const S: WideString): Integer; override;
    procedure InsertObject(Index: Integer; const S: WideString;
      AObject: TObject); override;
    procedure Sort; virtual;
    procedure CustomSort(Compare: TWStringListSortCompare); virtual;
    property Duplicates: TDuplicates read FDuplicates write FDuplicates;
    property Sorted: Boolean read FSorted write SetSorted;
    property CaseSensitive: Boolean read FCaseSensitive write SetCaseSensitive;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TNotifyEvent read FOnChanging write FOnChanging;
  end;

  TWideStringList = TWStringList;
  TWideStrings = TWStrings;

// WideChar functions
function CharToWideChar(Ch: AnsiChar): WideChar;
function WideCharToChar(Ch: WideChar): AnsiChar;

// PWideChar functions
procedure MoveWideChar(const Source; var Dest; Count: Integer);

function StrAllocW(WideSize: Cardinal): PWideChar;
function StrNewW(const S: WideString): PWideChar;
procedure StrDisposeW(var P: PWideChar);
function StrLICompW(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
function StrLICompW2(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
function StrCompW(S1, S2: PWideChar): Integer;
function StrLCompW(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
function StrIComp(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
function StrPosW(S, SubStr: PWideChar): PWideChar;
function StrLenW(P: PWideChar): Integer;
function StrScanW(P: PWideChar; Ch: WideChar): PWideChar;
function StrEndW(P: PWideChar): PWideChar;
function StrCopyW(Dest, Source: PWideChar): PWideChar;
function StrECopyW(Dest, Source: PWideChar): PWideChar;
function StrLCopyW(Dest, Source: PWideChar; MaxLen: Cardinal): PWideChar;
function StrCatW(Dest, Source: PWideChar): PWideChar;
function StrLCatW(Dest, Source: PWideChar; MaxLen: Cardinal): PWideChar;
function StrMoveW(Dest: PWideChar; const Source: PWideChar; Count: Cardinal): PWideChar;
function StrPCopyW(Dest: PWideChar; const Source: WideString): PWideChar;
function StrPLCopyW(Dest: PWideChar; const Source: WideString; MaxLen: Cardinal): PWideChar;
function StrRScanW(const Str: PWideChar; Chr: WideChar): PWideChar;

// WideString functions
function WidePos(const SubStr, S: WideString): Integer;
function WideQuotedStr(const S: WideString; Quote: WideChar): WideString;
function WideExtractQuotedStr(var Src: PWideChar; Quote: WideChar): WideString;
{$IFNDEF RTL140_UP}
function WideCompareText(const S1, S2: WideString): Integer;
function WideCompareStr(const S1, S2: WideString): Integer;
function WideUpperCase(const S: WideString): WideString;
function WideLowerCase(const S: WideString): WideString;
{$ENDIF ~RTL140_UP}
function TrimW(const S: WideString): WideString;
function TrimLeftW(const S: WideString): WideString;
function TrimRightW(const S: WideString): WideString;

function TrimLeftLengthW(const S: WideString): Integer;
function TrimRightLengthW(const S: WideString): Integer;

implementation

uses
  {$IFDEF HAS_UNIT_RTLCONSTS}
  RTLConsts,
  {$ELSE}
  {$IFDEF FPC}
  rtlconst,
  {$ELSE ~FPC}
  Consts,
  {$ENDIF ~FPC}
  {$ENDIF HAS_UNIT_RTLCONSTS}
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF MSWINDOWS}
  Math;

{$IFDEF BORLAND}
  {$IFNDEF RTL140_UP}
    {$DEFINE RTL130_DOWN}
  {$ENDIF ~RTL140_UP}
{$ENDIF BORLAND}

{$IFDEF RTL130_DOWN // Delphi 5 Math unit has no Sign function }
function Sign(A: Integer): Integer;
begin
  if A < 0 then
    Result := -1
  else if A > 0 then
    Result := 1
  else
    Result := 0;
end;
{$ENDIF RTL130_DOWN}

procedure SwapWordByteOrder(P: PChar; Len: Cardinal);
var
  B: Char;
begin
  while Len > 0 do
  begin
    B := P[0];
    P[0] := P[1];
    P[1] := B;
    Inc(P, 2);
    Dec(Len);
  end;
end;

//=== WideChar functions =====================================================

function CharToWideChar(Ch: Char): WideChar;
var
  WS: WideString;
begin
  WS := Ch;
  Result := WS[1];
end;

function WideCharToChar(Ch: WideChar): AnsiChar;
var
  S: AnsiString;
begin
  S := Ch;
  Result := S[1];
end;

//=== PWideChar functions ====================================================

procedure MoveWideChar(const Source; var Dest; Count: Integer);
begin
  Move(Source, Dest, Count * SizeOf(WideChar));
end;

function StrAllocW(WideSize: Cardinal): PWideChar;
begin
  if WideSize > 0 then
    Result := AllocMem(WideSize * SizeOf(WideChar))
  else
    Result := nil;
end;

function StrNewW(const S: WideString): PWideChar;
begin
  Result := nil;
  if S <> '' then
  begin
    Result := StrAllocW(Length(S) + 1);
    MoveWideChar(S[1], Result^, Length(S));
  end;
end;

procedure StrDisposeW(var P: PWideChar);
begin
  if P <> nil then
    FreeMem(P);
  P := nil;
end;

function StrLICompW(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
var
  P1, P2: WideString;
begin
  SetString(P1, S1, Min(MaxLen, Cardinal(StrLenW(S1))));
  SetString(P2, S2, Min(MaxLen, Cardinal(StrLenW(S2))));
  Result := WideCompareText(P1, P2);
end;

function StrLICompW2(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
var
  P1, P2: WideString;
begin
  // faster than the JclUnicode.StrLICompW function
  SetString(P1, S1, Min(MaxLen, Cardinal(StrLenW(S1))));
  SetString(P2, S2, Min(MaxLen, Cardinal(StrLenW(S2))));
  Result := WideCompareText(P1, P2);
end;

function StrCompW(S1, S2: PWideChar): Integer;
var
  NullWide: WideChar;
begin
  Result := 0;
  if S1 = S2 then // "equal" and "nil" case
    Exit;
  NullWide := #0;

  if S1 = nil then
    S1 := @NullWide
  else
  if S2 = nil then
    S2 := @NullWide;
  while (S1^ = S2^) and (S1^ <> #0) and (S2^ <> #0) do
  begin
    Inc(S1);
    Inc(S2);
  end;
  Result := Sign(Integer(S1^) - Integer(S2^));
end;

function StrLCompW(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
var
  NullWide: WideChar;
begin
  Result := 0;
  if S1 = S2 then // "equal" and "nil" case
    Exit;
  NullWide := #0;

  if S1 = nil then
    S1 := @NullWide
  else
  if S2 = nil then
    S2 := @NullWide;
  while (MaxLen > 0) and (S1^ = S2[0]) and (S1^ <> #0) and (S2^ <> #0) do
  begin
    Inc(S1);
    Inc(S2);
    Dec(MaxLen);
  end;
  Result := Sign(Integer(S1^) - Integer(S2^));
end;

function StrIComp(S1, S2: PWideChar; MaxLen: Cardinal): Integer;
var
  NullWide: WideChar;
begin
  Result := 0;
  if S1 = S2 then // "equal" and "nil" case
    Exit;
  NullWide := #0;

  if S1 = nil then
    S1 := @NullWide
  else
  if S2 = nil then
    S2 := @NullWide;
  while (MaxLen > 0) and (S1^ = S2^) and (S1^ <> #0) and (S2^ <> #0) do
  begin
    Inc(S1);
    Inc(S2);
    Dec(MaxLen);
  end;
  Result := Sign(Integer(S1^) - Integer(S2^));
end;

function StrPosW(S, SubStr: PWideChar): PWideChar;
var
  P: PWideChar;
  I: Integer;
begin
  Result := nil;
  if (S = nil) or (SubStr = nil) or (S^ = #0) or (SubStr^ = #0) then
    Exit;
  Result := S;
  while Result^ <> #0 do
  begin
    if Result^ <> SubStr^ then
      Inc(Result)
    else
    begin
      P := Result + 1;
      I := 1;
      while (P^ <> #0) and (P^ = SubStr[I]) do
      begin
        Inc(I);
        Inc(P);
      end;
      if SubStr[I] = #0 then
        Exit
      else
        Inc(Result);
    end;
  end;
  Result := nil;
end;

function StrLenW(P: PWideChar): Integer;
begin
  Result := 0;
  if P <> nil then
    while P[Result] <> #0 do
      Inc(Result);
end;

function StrScanW(P: PWideChar; Ch: WideChar): PWideChar;
begin
  Result := P;
  if Result <> nil then
    while (Result^ <> #0) and (Result^ <> Ch) do
      Inc(Result);
end;

function StrEndW(P: PWideChar): PWideChar;
begin
  Result := P;
  if Result <> nil then
    while Result^ <> #0 do
      Inc(Result);
end;

function StrCopyW(Dest, Source: PWideChar): PWideChar;
begin
  Result := Dest;
  if Dest <> nil then
  begin
    if Source <> nil then
      while Source^ <> #0 do
      begin
        Dest^ := Source^;
        Inc(Source);
        Inc(Dest);
      end;
    Dest^ := #0;
  end;
end;

function StrECopyW(Dest, Source: PWideChar): PWideChar;
begin
  if Dest <> nil then
  begin
    if Source <> nil then
      while Source^ <> #0 do
      begin
        Dest^ := Source^;
        Inc(Source);
        Inc(Dest);
      end;
    Dest^ := #0;
  end;
  Result := Dest;
end;

function StrLCopyW(Dest, Source: PWideChar; MaxLen: Cardinal): PWideChar;
begin
  Result := Dest;
  if (Dest <> nil) and (MaxLen > 0) then
  begin
    if Source <> nil then
      while (MaxLen > 0) and (Source^ <> #0) do
      begin
        Dest^ := Source^;
        Inc(Source);
        Inc(Dest);
        Dec(MaxLen);
      end;
    Dest^ := #0;
  end;
end;

function StrCatW(Dest, Source: PWideChar): PWideChar;
begin
  Result := Dest;
  while Dest^ <> #0 do
    Inc(Dest);
  StrCopyW(Dest, Source);
end;

function StrLCatW(Dest, Source: PWideChar; MaxLen: Cardinal): PWideChar;
begin
  Result := Dest;
  while Dest^ <> #0 do
  begin
    Inc(Dest);
    if MaxLen = 0 then
      Exit;
    Dec(MaxLen);
  end;
  StrLCopyW(Dest, Source, MaxLen);
end;

function StrMoveW(Dest: PWideChar; const Source: PWideChar; Count: Cardinal): PWideChar;
begin
  Result := Dest;
  Move(Source^, Dest^, Integer(Count) * SizeOf(WideChar));
end;

function StrPCopyW(Dest: PWideChar; const Source: WideString): PWideChar;
begin
  Result := StrLCopyW(Dest, PWideChar(Source), Length(Source));
end;

function StrPLCopyW(Dest: PWideChar; const Source: WideString; MaxLen: Cardinal): PWideChar;
begin
  Result := StrLCopyW(Dest, PWideChar(Source), MaxLen);
end;

function StrRScanW(const Str: PWideChar; Chr: WideChar): PWideChar;
var
  P: PWideChar;
begin
  Result := nil;
  if Str <> nil then
  begin
    P := Str;
    repeat
      if P^ = Chr then
        Result := P;
      Inc(P);
    until P^ = #0;
  end;
end;

//=== WideString functions ===================================================

function WidePos(const SubStr, S: WideString): Integer;
var
  P: PWideChar;
begin
  P := StrPosW(PWideChar(S), PWideChar(SubStr));
  if P <> nil then
    Result := P - PWideChar(S) + 1
  else
    Result := 0;
end;

// original code by Mike Lischke (extracted from JclUnicode.pas)

function WideQuotedStr(const S: WideString; Quote: WideChar): WideString;
var
  P, Src,
  Dest: PWideChar;
  AddCount: Integer;
begin
  AddCount := 0;
  P := StrScanW(PWideChar(S), Quote);
  while P <> nil do
  begin
    Inc(P);
    Inc(AddCount);
    P := StrScanW(P, Quote);
  end;

  if AddCount = 0 then
    Result := Quote + S + Quote
  else
  begin
    SetLength(Result, Length(S) + AddCount + 2);
    Dest := PWideChar(Result);
    Dest^ := Quote;
    Inc(Dest);
    Src := PWideChar(S);
    P := StrScanW(Src, Quote);
    repeat
      Inc(P);
      MoveWideChar(Src^, Dest^, P - Src);
      Inc(Dest, P - Src);
      Dest^ := Quote;
      Inc(Dest);
      Src := P;
      P := StrScanW(Src, Quote);
    until P = nil;
    P := StrEndW(Src);
    MoveWideChar(Src^, Dest^, P - Src);
    Inc(Dest, P - Src);
    Dest^ := Quote;
  end;
end;

// original code by Mike Lischke (extracted from JclUnicode.pas)

function WideExtractQuotedStr(var Src: PWideChar; Quote: WideChar): WideString;
var
  P, Dest: PWideChar;
  DropCount: Integer;
begin
  Result := '';
  if (Src = nil) or (Src^ <> Quote) then
    Exit;

  Inc(Src);
  DropCount := 1;
  P := Src;
  Src := StrScanW(Src, Quote);
  while Src <> nil do   // count adjacent pairs of quote chars
  begin
    Inc(Src);
    if Src^ <> Quote then
      Break;
    Inc(Src);
    Inc(DropCount);
    Src := StrScanW(Src, Quote);
  end;

  if Src = nil then
    Src := StrEndW(P);
  if (Src - P) <= 1 then
    Exit;

  if DropCount = 1 then
    SetString(Result, P, Src - P - 1)
  else
  begin
    SetLength(Result, Src - P - DropCount);
    Dest := PWideChar(Result);
    Src := StrScanW(P, Quote);
    while Src <> nil do
    begin
      Inc(Src);
      if Src^ <> Quote then
        Break;
      MoveWideChar(P^, Dest^, Src - P);
      Inc(Dest, Src - P);
      Inc(Src);
      P := Src;
      Src := StrScanW(Src, Quote);
    end;
    if Src = nil then
      Src := StrEndW(P);
    MoveWideChar(P^, Dest^, Src - P - 1);
  end;
end;


function TrimW(const S: WideString): WideString;
// available from Delphi 7 up
{$IFDEF RTL150_UP}
begin
  Result := Trim(S);
end;
{$ELSE ~RTL150_UP}
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do
    Inc(I);
  if I > L then
    Result := ''
  else
  begin
    while S[L] <= ' ' do
      Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
end;
{$ENDIF ~RTL150_UP}

function TrimLeftW(const S: WideString): WideString;
// available from Delphi 7 up
{$IFDEF RTL150_UP}
begin
  Result := TrimLeft(S);
end;
{$ELSE ~RTL150_UP}
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do
    Inc(I);
  Result := Copy(S, I, Maxint);
end;
{$ENDIF ~RTL150_UP}

function TrimRightW(const S: WideString): WideString;
// available from Delphi 7 up
{$IFDEF RTL150_UP}
begin
  Result := TrimRight(S);
end;
{$ELSE ~RTL150_UP}
var
  I: Integer;
begin
  I := Length(S);
  while (I > 0) and (S[I] <= ' ') do
    Dec(I);
  Result := Copy(S, 1, I);
end;
{$ENDIF ~RTL150_UP}

// functions missing in Delphi 5 / FPC
{$IFNDEF RTL140_UP}

function WideCompareText(const S1, S2: WideString): Integer;
begin
  {$IFDEF MSWINDOWS}
  if Win32Platform = VER_PLATFORM_WIN32_WINDOWS then
    Result := AnsiCompareText(string(S1), string(S2))
  else
    Result := CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE,
      PWideChar(S1), Length(S1), PWideChar(S2), Length(S2)) - 2;
  {$ELSE ~MSWINDOWS}
  { TODO : Don't cheat here }
  Result := CompareText(S1, S2);
  {$ENDIF MSWINDOWS}
end;

function WideCompareStr(const S1, S2: WideString): Integer;
begin
  {$IFDEF MSWINDOWS}
  if Win32Platform = VER_PLATFORM_WIN32_WINDOWS then
    Result := AnsiCompareStr(string(S1), string(S2))
  else
    Result := CompareStringW(LOCALE_USER_DEFAULT, 0,
      PWideChar(S1), Length(S1), PWideChar(S2), Length(S2)) - 2;
  {$ELSE ~MSWINDOWS}
  { TODO : Don't cheat here }
  Result := CompareString(S1, S2);
  {$ENDIF ~MSWINDOWS}
end;

function WideUpperCase(const S: WideString): WideString;
begin
  Result := S;
  if Result <> '' then
    {$IFDEF MSWINDOWS}
    CharUpperBuffW(Pointer(Result), Length(Result));
    {$ELSE ~MSWINDOWS}
    { TODO : Don't cheat here }
    Result := UpperCase(Result);
    {$ENDIF ~MSWINDOWS}
end;

function WideLowerCase(const S: WideString): WideString;
begin
  Result := S;
  if Result <> '' then
    {$IFDEF MSWINDOWS}
    CharLowerBuffW(Pointer(Result), Length(Result));
    {$ELSE ~MSWINDOWS}
    { TODO : Don't cheat here }
    Result := LowerCase(Result);
    {$ENDIF ~MSWINDOWS}
end;

{$ENDIF ~RTL140_UP}

function TrimLeftLengthW(const S: WideString): Integer;
var
  Len: Integer;
begin
  Len := Length(S);
  Result := 1;
  while (Result <= Len) and (S[Result] <= #32) do
    Inc(Result);
  Result := Len - Result + 1;
end;

function TrimRightLengthW(const S: WideString): Integer;
begin
  Result := Length(S);
  while (Result > 0) and (S[Result] <= #32) do
    Dec(Result);
end;

//=== { TWStrings } ==========================================================

constructor TWStrings.Create;
begin
  inherited Create;
  // FLineSeparator := WideChar($2028);
  {$IFDEF MSWINDOWS}
  FLineSeparator := WideChar(13) + '' + WideChar(10); // compiler wants it this way
  {$ENDIF MSWINDOWS}
  {$IFDEF UNIX}
  FLineSeparator := WideChar(10);
  {$ENDIF UNIX}
  FNameValueSeparator := '=';
  FDelimiter := ',';
  FQuoteChar := '"';
end;

function TWStrings.Add(const S: WideString): Integer;
begin
  Result := AddObject(S, nil);
end;

function TWStrings.AddObject(const S: WideString; AObject: TObject): Integer;
begin
  Result := Count;
  InsertObject(Result, S, AObject);
end;

procedure TWStrings.AddStrings(Strings: TWStrings);
var
  I: Integer;
begin
  for I := 0 to Strings.Count - 1 do
    AddObject(Strings.GetP(I)^, Strings.Objects[I]);
end;

procedure TWStrings.AddStrings(Strings: TStrings);
var
  I: Integer;
begin
  for I := 0 to Strings.Count - 1 do
    AddObject(Strings.Strings[I], Strings.Objects[I]);
end;

procedure TWStrings.AddStringsTo(Dest: TStrings);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Dest.AddObject(GetP(I)^, Objects[I]);
end;

procedure TWStrings.Append(const S: WideString);
begin
  Add(S);
end;

procedure TWStrings.Assign(Source: TPersistent);
begin
  if Source is TWStrings then
  begin
    BeginUpdate;
    try
      Clear;
      FDelimiter := TWStrings(Source).FDelimiter;
      FNameValueSeparator := TWStrings(Source).FNameValueSeparator;
      FQuoteChar := TWStrings(Source).FQuoteChar;
      AddStrings(TWStrings(Source));
    finally
      EndUpdate;
    end;
  end
  else
  if Source is TStrings then
  begin
    BeginUpdate;
    try
      Clear;
      {$IFDEF RTL150_UP}
      FNameValueSeparator := CharToWideChar(TStrings(Source).NameValueSeparator);
      {$ENDIF RTL150_UP}
      {$IFDEF RTL140_UP}
      FQuoteChar := CharToWideChar(TStrings(Source).QuoteChar);
      FDelimiter := CharToWideChar(TStrings(Source).Delimiter);
      {$ENDIF RTL140_UP}
      AddStrings(TStrings(Source));
    finally
      EndUpdate;
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TWStrings.AssignTo(Dest: TPersistent);
var
  I: Integer;
begin
  if Dest is TStrings then
  begin
    TStrings(Dest).BeginUpdate;
    try
      TStrings(Dest).Clear;
      {$IFDEF RTL150_UP}
      TStrings(Dest).NameValueSeparator := WideCharToChar(NameValueSeparator);
      {$ENDIF RTL150_UP}
      {$IFDEF RTL140_UP}
      TStrings(Dest).QuoteChar := WideCharToChar(QuoteChar);
      TStrings(Dest).Delimiter := WideCharToChar(Delimiter);
      {$ENDIF RTL140_UP}
      for I := 0 to Count - 1 do
        TStrings(Dest).AddObject(GetP(I)^, Objects[I]);
    finally
      TStrings(Dest).EndUpdate;
    end;
  end
  else
    inherited AssignTo(Dest);
end;

procedure TWStrings.BeginUpdate;
begin
  if FUpdateCount = 0 then
    SetUpdateState(True);
  Inc(FUpdateCount);
end;

function TWStrings.CompareStrings(const S1, S2: WideString): Integer;
begin
  Result := WideCompareText(S1, S2);
end;

function TWStrings.CreateAnsiStringList: TStrings;
var
  I: Integer;
begin
  Result := TStringList.Create;
  try
    Result.BeginUpdate;
    for I := 0 to Count - 1 do
      Result.AddObject(GetP(I)^, Objects[I]);
    Result.EndUpdate;
  except
    Result.Free;
    raise;
  end;
end;

procedure TWStrings.DefineProperties(Filer: TFiler);

  function DoWrite: Boolean;
  begin
    if Filer.Ancestor <> nil then
    begin
      Result := True;
      if Filer.Ancestor is TWStrings then
        Result := not Equals(TWStrings(Filer.Ancestor))
    end
    else
      Result := Count > 0;
  end;

begin
  Filer.DefineProperty('Strings', ReadData, WriteData, DoWrite);
end;

procedure TWStrings.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount = 0 then
    SetUpdateState(False);
end;

function TWStrings.Equals(Strings: TStrings): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Strings.Count = Count then
  begin
    for I := 0 to Count - 1 do
      if Strings[I] <> PStrings[I]^ then
        Exit;
    Result := True;
  end;
end;

function TWStrings.Equals(Strings: TWStrings): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Strings.Count = Count then
  begin
    for I := 0 to Count - 1 do
      if Strings[I] <> PStrings[I]^ then
        Exit;
    Result := True;
  end;
end;

procedure TWStrings.Exchange(Index1, Index2: Integer);
var
  TempObject: TObject;
  TempString: WideString;
begin
  BeginUpdate;
  try
    TempString := PStrings[Index1]^;
    TempObject := Objects[Index1];
    PStrings[Index1]^ := PStrings[Index2]^;
    Objects[Index1] := Objects[Index2];
    PStrings[Index2]^ := TempString;
    Objects[Index2] := TempObject;
  finally
    EndUpdate;
  end;
end;

function TWStrings.ExtractName(const S: WideString): WideString;
var
  Index: Integer;
begin
  Result := S;
  Index := WidePos(NameValueSeparator, Result);
  if Index <> 0 then
    SetLength(Result, Index - 1)
  else
    SetLength(Result, 0);
end;

function TWStrings.Get(Index: Integer): WideString;
begin
  Result := GetP(Index)^;
end;

function TWStrings.GetCapacity: Integer;
begin
  Result := Count;
end;

function TWStrings.GetCommaText: WideString;
begin
  Result := GetDelimitedTextEx(',', '"');
end;

function TWStrings.GetDelimitedText: WideString;
begin
  Result := GetDelimitedTextEx(FDelimiter, FQuoteChar);
end;

function TWStrings.GetDelimitedTextEx(ADelimiter, AQuoteChar: WideChar): WideString;
var
  S: WideString;
  P: PWideChar;
  I, Num: Integer;
begin
  Num := GetCount;
  if (Num = 1) and (GetP(0)^ = '') then
    Result := AQuoteChar + '' + AQuoteChar // Compiler wants it this way
  else
  begin
    Result := '';
    for I := 0 to Count - 1 do
    begin
      S := GetP(I)^;
      P := PWideChar(S);
      while True do
      begin
        case P[0] of
          WideChar(0)..WideChar(32):
            Inc(P);
        else
          if (P[0] = AQuoteChar) or (P[0] = ADelimiter) then
            Inc(P)
          else
            Break;
        end;
      end;
      if P[0] <> WideChar(0) then
        S := WideQuotedStr(S, AQuoteChar);
      Result := Result + S + ADelimiter;
    end;
    System.Delete(Result, Length(Result), 1);
  end;
end;

function TWStrings.GetName(Index: Integer): WideString;
var
  I: Integer;
begin
  Result := GetP(Index)^;
  I := WidePos(FNameValueSeparator, Result);
  if I > 0 then
    SetLength(Result, I - 1);
end;

function TWStrings.GetObject(Index: Integer): TObject;
begin
  Result := nil;
end;

function TWStrings.GetText: PWideChar;
begin
  Result := StrNewW(GetTextStr);
end;

function TWStrings.GetTextStr: WideString;
var
  I: Integer;
  Len, LL: Integer;
  P: PWideChar;
  W: PWideString;
begin
  Len := 0;
  LL := Length(LineSeparator);
  for I := 0 to Count - 1 do
    Inc(Len, Length(GetP(I)^) + LL);
  SetLength(Result, Len);
  P := PWideChar(Result);
  for I := 0 to Count - 1 do
  begin
    W := GetP(I);
    Len := Length(W^);
    if Len > 0 then
    begin
      MoveWideChar(W^[1], P[0], Len);
      Inc(P, Len);
    end;
    if LL > 0 then
    begin
      MoveWideChar(FLineSeparator[1], P[0], LL);
      Inc(P, LL);
    end;
  end;
end;

function TWStrings.GetValue(const Name: WideString): WideString;
var
  Idx: Integer;
begin
  Idx := IndexOfName(Name);
  if Idx >= 0 then
    Result := GetValueFromIndex(Idx)
  else
    Result := '';
end;

function TWStrings.GetValueFromIndex(Index: Integer): WideString;
var
  I: Integer;
begin
  Result := GetP(Index)^;
  I := WidePos(FNameValueSeparator, Result);
  if I > 0 then
    System.Delete(Result, 1, I)
  else
    Result := '';
end;

function TWStrings.IndexOf(const S: WideString): Integer;
begin
  for Result := 0 to Count - 1 do
    if CompareStrings(GetP(Result)^, S) = 0 then
      Exit;
  Result := -1;
end;

function TWStrings.IndexOfName(const Name: WideString): Integer;
begin
  for Result := 0 to Count - 1 do
    if CompareStrings(Names[Result], Name) = 0 then
      Exit;
  Result := -1;
end;

function TWStrings.IndexOfObject(AObject: TObject): Integer;
begin
  for Result := 0 to Count - 1 do
    if Objects[Result] = AObject then
      Exit;
  Result := -1;
end;

procedure TWStrings.Insert(Index: Integer; const S: WideString);
begin
  InsertObject(Index, S, nil);
end;

procedure TWStrings.InsertObject(Index: Integer; const S: WideString;
  AObject: TObject);
begin
end;

procedure TWStrings.LoadFromFile(const FileName: AnsiString;
  WideFileOptions: TWideFileOptions = []);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream, WideFileOptions);
  finally
    Stream.Free;
  end;
end;

procedure TWStrings.LoadFromStream(Stream: TStream;
  WideFileOptions: TWideFileOptions = []);
var
  AnsiS: AnsiString;
  WideS: WideString;
  WC: WideChar;
begin
  BeginUpdate;
  try
    Clear;
    if foAnsiFile in WideFileOptions then
    begin
      Stream.Read(WC, SizeOf(WC));
      Stream.Seek(-SizeOf(WC), soFromCurrent);
      if (Hi(Word(WC)) <> 0) and (WC <> BOM_LSB_FIRST) and (WC <> BOM_MSB_FIRST) then
      begin
        SetLength(AnsiS, Stream.Size - Stream.Position);
        Stream.Read(AnsiS[1], Length(AnsiS));
        SetTextStr(AnsiS);
        Exit;
      end;
    end;

    Stream.Read(WC, SizeOf(WC));
    if (WC <> BOM_LSB_FIRST) and (WC <> BOM_MSB_FIRST) then
      Stream.Seek(-SizeOf(WC), soFromCurrent);
    SetLength(WideS, Stream.Size - Stream.Position);
    Stream.Read(WideS[1], Length(WideS) * SizeOf(WideChar));

    if WC = BOM_MSB_FIRST then
      SwapWordByteOrder(Pointer(WideS), Length(WideS));

    SetTextStr(WideS);
  finally
    EndUpdate;
  end;
end;

procedure TWStrings.Move(CurIndex, NewIndex: Integer);
var
  TempObject: TObject;
  TempString: WideString;
begin
  if CurIndex <> NewIndex then
  begin
    BeginUpdate;
    try
      TempString := GetP(CurIndex)^;
      TempObject := GetObject(CurIndex);
      Delete(CurIndex);
      InsertObject(NewIndex, TempString, TempObject);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TWStrings.ReadData(Reader: TReader);
begin
  BeginUpdate;
  try
    Clear;
    Reader.ReadListBegin;
    while not Reader.EndOfList do
      if Reader.NextValue in [vaLString, vaString] then
        Add(Reader.ReadString)
      else
        Add(Reader.ReadWideString);
    Reader.ReadListEnd;
  finally
    EndUpdate;
  end;
end;

procedure TWStrings.SaveToFile(const FileName: AnsiString;
  WideFileOptions: TWideFileOptions = []);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream, WideFileOptions);
  finally
    Stream.Free;
  end;
end;

procedure TWStrings.SaveToStream(Stream: TStream;
  WideFileOptions: TWideFileOptions = []);
var
  AnsiS: AnsiString;
  WideS: WideString;
  WC: WideChar;
begin
  if foAnsiFile in WideFileOptions then
  begin
    AnsiS := GetTextStr;
    Stream.Write(AnsiS[1], Length(AnsiS));
  end
  else
  begin
    if foUnicodeLB in WideFileOptions then
    begin
      WC := BOM_LSB_FIRST;
      Stream.Write(WC, SizeOf(WC));
    end;
    WideS := GetTextStr;
    Stream.Write(WideS[1], Length(WideS) * SizeOf(WideChar));
  end;
end;

procedure TWStrings.SetCapacity(NewCapacity: Integer);
begin
end;

procedure TWStrings.SetCommaText(const Value: WideString);
begin
  SetDelimitedTextEx(',', '"', Value);
end;

procedure TWStrings.SetDelimitedText(const Value: WideString);
begin
  SetDelimitedTextEx(Delimiter, QuoteChar, Value);
end;

procedure TWStrings.SetDelimitedTextEx(ADelimiter, AQuoteChar: WideChar;
  const Value: WideString);
var
  P, P1: PWideChar;
  S: WideString;

  procedure IgnoreWhiteSpace(var P: PWideChar);
  begin
    while True do
      case P^ of
        WideChar(1)..WideChar(32):
          Inc(P);
      else
        Break;
      end;
  end;

begin
  BeginUpdate;
  try
    Clear;
    P := PWideChar(Value);
    IgnoreWhiteSpace(P);
    while P[0] <> WideChar(0) do
    begin
      if P[0] = AQuoteChar then
        S := WideExtractQuotedStr(P, AQuoteChar)
      else
      begin
        P1 := P;
        while (P[0] > WideChar(32)) and (P[0] <> ADelimiter) do
          Inc(P);
        SetString(S, P1, P - P1);
      end;
      Add(S);

      IgnoreWhiteSpace(P);
      if P[0] = ADelimiter then
      begin
        Inc(P);
        IgnoreWhiteSpace(P);
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TWStrings.SetText(Text: PWideChar);
begin
  SetTextStr(Text);
end;

procedure TWStrings.SetTextStr(const Value: WideString);
var
  P, Start: PWideChar;
  S: WideString;
  Len: Integer;
begin
  BeginUpdate;
  try
    Clear;
    if Value <> '' then
    begin
      P := PWideChar(Value);
      if P <> nil then
      begin
        while P[0] <> WideChar(0) do
        begin
          Start := P;
          while True do
          begin
            case P[0] of
              WideChar(0), WideChar(10), WideChar(13):
                Break;
            end;
            Inc(P);
          end;
          Len := P - Start;
          if Len > 0 then
          begin
            SetString(S, Start, Len);
            AddObject(S, nil); // consumes most time
          end
          else
            AddObject('', nil);
          if P[0] = WideChar(13) then
            Inc(P);
          if P[0] = WideChar(10) then
            Inc(P);
        end;
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TWStrings.SetUpdateState(Updating: Boolean);
begin
end;

procedure TWStrings.SetValue(const Name, Value: WideString);
var
  Idx: Integer;
begin
  Idx := IndexOfName(Name);
  if Idx >= 0 then
    SetValueFromIndex(Idx, Value)
  else
  if Value <> '' then
    Add(Name + NameValueSeparator + Value);
end;

procedure TWStrings.SetValueFromIndex(Index: Integer; const Value: WideString);
var
  S: WideString;
  I: Integer;
begin
  if Value = '' then
    Delete(Index)
  else
  begin
    if Index < 0 then
      Index := Add('');
    S := GetP(Index)^;
    I := WidePos(NameValueSeparator, S);
    if I > 0 then
      System.Delete(S, I, MaxInt);
    S := S + NameValueSeparator + Value;
    Put(Index, S);
  end;
end;

procedure TWStrings.WriteData(Writer: TWriter);
var
  I: Integer;
begin
  Writer.WriteListBegin;
  for I := 0 to Count - 1 do
     Writer.WriteWideString(GetP(I)^);
  Writer.WriteListEnd;
end;

//=== { TWStringList } =======================================================

constructor TWStringList.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TWStringList.Destroy;
begin
  FOnChange := nil;
  FOnChanging := nil;
  Inc(FUpdateCount); // do not call unnecessary functions
  Clear;
  FList.Free;
  inherited Destroy;
end;

function TWStringList.AddObject(const S: WideString; AObject: TObject): Integer;
begin
  if not Sorted then
    Result := Count
  else
  if Find(S, Result) then
    case Duplicates of
      dupIgnore:
        Exit;
      dupError:
        raise EListError.CreateRes(@SDuplicateString);
    end;
  InsertObject(Result, S, AObject);
end;

procedure TWStringList.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TWStringList.Changing;
begin
  if Assigned(FOnChanging) then
    FOnChanging(Self);
end;

procedure TWStringList.Clear;
var
  I: Integer;
  Item: PWStringItem;
begin
  if FUpdateCount = 0 then
    Changing;
  for I := 0 to Count - 1 do
  begin
    Item := PWStringItem(FList[I]);
    Item.FString := '';
    FreeMem(Item);
  end;
  FList.Clear;
  if FUpdateCount = 0 then
    Changed;
end;

function TWStringList.CompareStrings(const S1, S2: WideString): Integer;
begin
  if CaseSensitive then
    Result := WideCompareStr(S1, S2)
  else
    Result := WideCompareText(S1, S2);
end;

threadvar
  CustomSortList: TWStringList;
  CustomSortCompare: TWStringListSortCompare;

function WStringListCustomSort(Item1, Item2: Pointer): Integer;
begin
  Result := CustomSortCompare(CustomSortList,
    CustomSortList.FList.IndexOf(Item1),
    CustomSortList.FList.IndexOf(Item2));
end;

procedure TWStringList.CustomSort(Compare: TWStringListSortCompare);
var
  TempList: TWStringList;
  TempCompare: TWStringListSortCompare;
begin
  TempList := CustomSortList;
  TempCompare := CustomSortCompare;
  CustomSortList := Self;
  CustomSortCompare := Compare;
  try
    Changing;
    FList.Sort(WStringListCustomSort);
    Changed;
  finally
    CustomSortList := TempList;
    CustomSortCompare := TempCompare;
  end;
end;

procedure TWStringList.Delete(Index: Integer);
var
  Item: PWStringItem;
begin
  if FUpdateCount = 0 then
    Changing;
  Item := PWStringItem(FList[Index]);
  FList.Delete(Index);
  Item.FString := '';
  FreeMem(Item);
  if FUpdateCount = 0 then
    Changed;
end;

procedure TWStringList.Exchange(Index1, Index2: Integer);
begin
  if FUpdateCount = 0 then
    Changing;
  FList.Exchange(Index1, Index2);
  if FUpdateCount = 0 then
    Changed;
end;

function TWStringList.Find(const S: WideString; var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  if Sorted then
  begin
    L := 0;
    H := Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      C := CompareStrings(GetItem(I).FString, S);
      if C < 0 then
        L := I + 1
      else
      begin
        H := I - 1;
        if C = 0 then
        begin
          Result := True;
          if Duplicates <> dupAccept then
            L := I;
        end;
      end;
    end;
    Index := L;
  end
  else
  begin
    Index := IndexOf(S);
    Result := Index <> -1;
  end;
end;

function TWStringList.GetCapacity: Integer;
begin
  Result := FList.Capacity;
end;

function TWStringList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TWStringList.GetItem(Index: Integer): PWStringItem;
begin
  Result := FList[Index];
end;

function TWStringList.GetObject(Index: Integer): TObject;
begin
  Result := GetItem(Index).FObject;
end;

function TWStringList.GetP(Index: Integer): PWideString;
begin
  Result := Addr(GetItem(Index).FString);
end;

function TWStringList.IndexOf(const S: WideString): Integer;
begin
  if Sorted then
  begin
    if not Find(S, Result) then
      Result := -1;
  end
  else
  begin
    for Result := 0 to Count - 1 do
      if CompareStrings(GetItem(Result).FString, S) = 0 then
        Exit;
    Result := -1;
  end;
end;

procedure TWStringList.InsertObject(Index: Integer; const S: WideString;
  AObject: TObject);
var
  P: PWStringItem;
begin
  if FUpdateCount = 0 then
    Changing;
  FList.Insert(Index, nil); // error check
  P := AllocMem(SizeOf(TWStringItem));
  FList[Index] := P;

  Put(Index, S);
  if AObject <> nil then
    PutObject(Index, AObject);
  if FUpdateCount = 0 then
    Changed;
end;

procedure TWStringList.Put(Index: Integer; const Value: WideString);
begin
  if FUpdateCount = 0 then
    Changing;
  GetItem(Index).FString := Value;
  if FUpdateCount = 0 then
    Changed;
end;

procedure TWStringList.PutObject(Index: Integer; AObject: TObject);
begin
  if FUpdateCount = 0 then
    Changing;
  GetItem(Index).FObject := AObject;
  if FUpdateCount = 0 then
    Changed;
end;

procedure TWStringList.SetCapacity(NewCapacity: Integer);
begin
  FList.Capacity := NewCapacity;
end;

procedure TWStringList.SetCaseSensitive(const Value: Boolean);
begin
  if Value <> FCaseSensitive then
  begin
    FCaseSensitive := Value;
    if Sorted then
    begin
      Sorted := False;
      Sorted := True; // re-sort
    end;
  end;
end;

procedure TWStringList.SetSorted(Value: Boolean);
begin
  if Value <> FSorted then
  begin
    FSorted := Value;
    if FSorted then
    begin
      FSorted := False;
      Sort;
      FSorted := True;
    end;
  end;
end;

procedure TWStringList.SetUpdateState(Updating: Boolean);
begin
  if Updating then
    Changing
  else
    Changed;
end;

function DefaultSort(List: TWStringList; Index1, Index2: Integer): Integer;
begin
  Result := List.CompareStrings(List.GetItem(Index1).FString, List.GetItem(Index2).FString);
end;

procedure TWStringList.Sort;
begin
  if not Sorted then
    CustomSort(DefaultSort);
end;

// History:

// $Log$
// Revision 1.11  2005/03/08 08:33:18  marquardt
// overhaul of exceptions and resourcestrings, minor style cleaning
//
// Revision 1.10  2005/03/01 15:37:40  marquardt
// addressing Mantis 0714, 0716, 0720, 0731, 0740 partly or completely
//
// Revision 1.9  2005/02/24 16:34:40  marquardt
// remove divider lines, add section lines (unfinished)
//
// Revision 1.8  2005/02/14 00:47:23  rrossmair
// - removed (redundant) comment in German language.
//
// Revision 1.7  2004/10/25 15:12:30  marquardt
// fix internal error
//
// Revision 1.6  2004/10/17 21:49:03  rrossmair
// added CVS Log entries
//
// Revision 1.5                       rossmair
// fixed D6, FPC compatibility
//
// Revision 1.4                       marquardt
// complete and fix PWideChar Str functions
//
// Revision 1.3                       marquardt
// PH cleaning of JclStrings
//
// Revision 1.2                       rrossmair
// replaced some conditional compilation symbols by more appropriate ones
//
end.