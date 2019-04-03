unit u_simpleget;

{$I u_defines.inc}

interface

uses
  classes, libcurl, fpjson, jsonparser, jsonscanner;

type
  PStream = ^TStream;

// Get the content of url in the string data
function simpleGet(url: string; var data: string): boolean; overload;
// Get the content of url in the stream data
function simpleGet(url: string; data: TStream): boolean; overload;
// Get the content of url in the JSON data, supposed to be a nil instance.
function simpleGet(url: string; var data: TJSONData): boolean; overload;

implementation

var
  fCurlHandle: CURL = nil;

function curlHandle(): CURL;
begin
  if not assigned(fCurlHandle) then
  begin
    curl_global_init(CURL_GLOBAL_SSL or CURL_GLOBAL_ALL);
    fCurlHandle := curl_easy_init();
  end;
  result := fCurlHandle;
end;

function simpleGetClbckForStream(buffer:Pchar; size:PtrInt; nitems:PtrInt;
  appender: PStream): PtrInt; cdecl;
begin
  assert(appender <> nil);
  try
    result := appender^.write(buffer^, size * nitems);
  except
    result := 0;
  end;
end;

function simpleGetClbckForString(buffer:Pchar; size:PtrInt; nitems:PtrInt;
  appender: PString): PtrInt; cdecl;
begin
  assert(appender <> nil);
  result := size* nitems;
  try
    (appender^) += buffer;
  except
    result := 0;
  end;
end;

function simpleGet(url: string; var data: string): boolean; overload;
var
  c: CURLcode;
  h: CURL;
begin
  h := curlHandle();
  if not assigned(h) then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_USERAGENT, ['curl-fclweb']);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_URL, [PChar(url)]);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEDATA, [@data]);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, [@simpleGetClbckForString]);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_perform(h);
  result := c = CURLcode.CURLE_OK;
end;

function simpleGet(url: string; data: TStream): boolean; overload;
var
  c: CURLcode;
  h: CURL;
begin
  h := curlHandle();
  if not assigned(h) then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_USERAGENT, ['curl-fclweb']);
  if c <> CURLcode.CURLE_OK then
    exit(false);
  c := curl_easy_setopt(h, CURLOPT_URL, [PChar(url)]);
  if c <> CURLcode.CURLE_OK then
   exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEDATA, [@data]);
  if c <> CURLcode.CURLE_OK then
   exit(false);
  c := curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, [@simpleGetClbckForStream]);
  if c <> CURLcode.CURLE_OK then
   exit(false);
  c := curl_easy_perform(h);
  result := c = CURLcode.CURLE_OK;
end;

function simpleGet(url: string; var data: TJSONData): boolean; overload;
var
  s: string = '';
begin
  if not simpleGet(url, s) then
    exit(false);
  result := true;
  with TJSONParser.Create(s, [joUTF8, joIgnoreTrailingComma]) do
  try
    try
      data := Parse();
    except
      result := false;
    end;
  finally
    free;
  end;
end;

finalization
  if assigned(fCurlHandle) then
    curl_easy_cleanup(fCurlHandle);
end.

