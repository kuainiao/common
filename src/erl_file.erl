%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 29. 十二月 2016 上午11:39
%%%-------------------------------------------------------------------
-module(erl_file).

-export([get_path/1, position_path/2]).

%% @doc 只考虑linux路径下
get_path(FilePath) ->
    ModPath = string:tokens(code:which(?MODULE), "/"),
    {NewFilePath, N} = position_path(FilePath, 0),
    ModPathLen = length(ModPath),
    case os:type() of
        {win32, _} -> string:join(lists:sublist(ModPath, ModPathLen - 1 - N) ++ [NewFilePath], "/");
        _ -> "/" ++ string:join(lists:sublist(ModPath, ModPathLen - 1 - N) ++ [NewFilePath], "/")
    end.

%% (相对路径，../的层数)
-spec position_path(FilePath :: string(), N :: integer()) -> {FilePath :: string(), N :: integer()}.
position_path("../" ++ FilePath, N) -> position_path(FilePath, N + 1);
position_path(FilePath, N) -> {FilePath, N}.