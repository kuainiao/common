%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc
%%%
%%% Created : 18. 七月 2016 上午9:17
%%%-------------------------------------------------------------------
-module(assert_can).

-include("erl_pub.hrl").

-export([
    exit_pro_dict/1,
    exit_process/1,
    exit_process/2
]).

%% @doc 存在进程字典
exit_pro_dict(Key) ->
    exit_pro_dict(Key, true).

exit_pro_dict(Key, true) ->
    case erlang:get(Key) of
        undefined -> ?return_err(?ERR_NOT_EXIT_PRO_DICT);
        V -> V
    end;

exit_pro_dict(Key, false) ->
    case erlang:get(Key) of
        undefined -> ok;
        _V -> ?return_err(?ERR_EXIT_PRO_DICT)
    end.


exit_process(Pid) ->
    exit_process(Pid, true).

exit_process(Pid, true) ->
    case is_pid(Pid) of
        true ->
            case is_process_alive(Pid) of
                true -> ok;
                false -> ?return_err(?ERR_NOT_EXIT_PROCESS)
            end
    end;

exit_process(Pid, false) ->
    case is_pid(Pid) of
        true ->
            case is_process_alive(Pid) of
                false -> ok;
                true -> ?return_err(?ERR_EXIT_PROCESS)
            end
    end.