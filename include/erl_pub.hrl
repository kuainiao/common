%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 27. 四月 2016 下午2:05
%%%-------------------------------------------------------------------

-include("erl_lager_log.hrl").
-include("erl_common.hrl").
-include("erl_err_code.hrl").

-define(return_err(Err), erlang:throw({throw, Err})).
-define(assert(Fun, Ret, Err), if Fun =:= Ret -> ok; true -> erlang:throw({throw, Err}) end).

-define(mysql_dynamic_pool, dynamic_pool).
-define(mysql_static_pool,  static_pool).
-define(mysql_log_pool,     log_pool).
-define(mysql_gm_tool,      gm_pool).