%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 27. 四月 2016 下午2:05
%%%-------------------------------------------------------------------

-include("erl_lager_log.hrl").
-include("erl_common.hrl").
-include("erl_err_code.hrl").

-define(return_error(Err), erlang:throw({error, Err})).