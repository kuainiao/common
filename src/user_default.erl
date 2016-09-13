%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 12. 六月 2016 下午3:09
%%%-------------------------------------------------------------------
-module(user_default).


-export([reload/0, reload/1, stop/0, s/0]).

reload() ->
    reload(no_app).

reload(AppName) ->
    ListDir =
        fun(Path) ->
            {ok, S} = file:list_dir(Path),
            S
        end,
    
    AppPath = case code:lib_dir(AppName, ebin) of
                  {error, _} -> "./ebin";
                  Path -> Path
              end,
    
    FileList = ListDir(AppPath),
    
    FunMap =
        fun(I) ->
            case lists:reverse(I) of
                "maeb." ++ R -> c:l(list_to_atom(lists:reverse(R)));
                R -> io:format("111:~p~n", [lists:reverse(R)])
            end
        end,
    lists:map(FunMap, FileList).


stop() ->
    snakes_app:stop().

s() ->
    snakes_app:start().