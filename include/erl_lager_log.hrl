%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%
%%% Created : 26. 四月 2016 下午4:55
%%%-------------------------------------------------------------------

%% R16 suport color term
-define(color_none, "\e[m").
-define(color_red, "\e[1m\e[31m").
-define(color_yellow, "\e[1m\e[33m").
-define(color_green, "\e[0m\e[32m").
-define(color_black, "\e[0;30m").
-define(color_blue, "\e[0;34m").
-define(color_purple, "\e[0;35m").
-define(color_cyan, "\e[0;36m").
-define(color_white, "\e[0;37m").


%% background hilight
-define(bak_blk, "\e[40m").   %% Black - Background
-define(bak_red, "\e[41m").   %% Red
-define(bak_grn, "\e[42m").   %% Green
-define(bak_ylw, "\e[43m").   %% Yellow
-define(bak_blu, "\e[44m").   %% Blue
-define(bak_pur, "\e[45m").   %% Purple
-define(bak_cyn, "\e[46m").   %% Cyan
-define(bak_wht, "\e[47m").   %% White

-ifdef(env_product).

-define(WARN(D),        lager:warning(D)).
-define(WARN(F, D),     lager:warning(F, D)).
-define(INFO(D),        lager:info(D)).
-define(INFO(F, D),     lager:info(F, D)).
-define(ERROR(D),       lager:error(D)).
-define(ERROR(F, D),    lager:error(F, D)).


-else.

-define(INFO(MSG),          io:format(?color_green"~p [INFO] [~s:~b] "  MSG"~n"?color_none, [calendar:local_time(), ?FILE, ?LINE])).
-define(INFO(FMT, ARGS),    io:format(?color_green"~p [INFO] [~s:~b] "  FMT"~n"?color_none, [calendar:local_time(), ?FILE, ?LINE | ARGS])).
-define(WARN(MSG),          io:format(?color_yellow"~p [WARN] [~s:~b] "  MSG"~n"?color_none, [calendar:local_time(), ?FILE, ?LINE])).
-define(WARN(FMT, ARGS),    io:format(?color_yellow"~p [WARN] [~s:~b] "  FMT"~n"?color_none, [calendar:local_time(), ?FILE, ?LINE | ARGS])).
-define(ERROR(MSG),         io:format(?color_red"~p [ERROR] [~s:~B] "  MSG"~n"?color_none, [calendar:local_time(), ?FILE, ?LINE])).
-define(ERROR(FMT, ARGS),   io:format(lists:append([?color_red, "~p [ERROR] [~s:~B] ", FMT, "~n", ?color_none]), [calendar:local_time(), ?FILE, ?LINE | ARGS])).

-endif.