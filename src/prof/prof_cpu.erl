%%%-------------------------------------------------------------------
%%% @author yj
%%% @doc
%%%
%%% Created : 21. 十月 2016 下午2:59
%%%-------------------------------------------------------------------
-module(prof_cpu).

-compile(export_all).

-export([
    scheduler_usage/0,
    scheduler_stat/0
]).

-export([eprof/1, eprof_stop/0]).


% 统计下1s每个调度器CPU的实际利用率(因为有spin wait、调度工作, 可能usage 比top显示低很多)
scheduler_usage() ->
    scheduler_usage(30000).

scheduler_usage(RunMs) ->
    erlang:system_flag(scheduler_wall_time, true),
    Ts0 = lists:sort(erlang:statistics(scheduler_wall_time)),
    timer:sleep(RunMs),
    Ts1 = lists:sort(erlang:statistics(scheduler_wall_time)),
    erlang:system_flag(scheduler_wall_time, false),
    Cores = lists:map(fun({{I, A0, T0}, {I, A1, T1}}) ->
        {I, (A1 - A0) / (T1 - T0)} end, lists:zip(Ts0, Ts1)),
    {A, T} = lists:foldl(fun({{_, A0, T0}, {_, A1, T1}}, {Ai, Ti}) ->
        {Ai + (A1 - A0), Ti + (T1 - T0)} end, {0, 0}, lists:zip(Ts0, Ts1)),
    Total = A / T,
    io:format("~p~n", [[{total, Total} | Cores]]).


% 统计下1s内调度进程数量(含义：第一个数字执行进程数量，第二个数字迁移进程数量)
scheduler_stat() ->
    scheduler_stat(30000).

scheduler_stat(RunMs) ->
    erlang:system_flag(scheduling_statistics, enable),
    Ts0 = erlang:system_info(total_scheduling_statistics),
    timer:sleep(RunMs),
    Ts1 = erlang:system_info(total_scheduling_statistics),
    erlang:system_flag(scheduling_statistics, disable),
    lists:map(fun({{Key, In0, Out0}, {Key, In1, Out1}}) ->
        {Key, In1 - In0, Out1 - Out0} end, lists:zip(Ts0, Ts1)).


eprof(Pid) ->
    eprof:start(),
    eprof:profile([Pid]).

eprof_stop() ->
    eprof:stop_profiling(),
    eprof:analyze(),
    eprof:stop().


% 对整个节点内所有进程执行eprof, eprof 对线上业务有一定影响,慎用!
% 建议TimeoutSec<10s，且进程数< 1000，否则可能导致节点crash
% 结果:
% 输出每个方法实际执行时间（不会累计方法内其他mod调用执行时间）
% 只能得到mod - Fun 执行次数 执行耗时
eprof_all(TimeoutSec) ->
    eprof(processes() -- [whereis(eprof)], TimeoutSec).

eprof(Pids, TimeoutSec) ->
    eprof:start(),
    eprof:start_profiling(Pids),
    timer:sleep(TimeoutSec),
    eprof:stop_profiling(),
    eprof:analyze(total),
    eprof:stop().




% 对MFA 执行分析，会严重减缓运行，建议只对小量业务执行
% 结果:
% fprof 结果比较详细，能够输出热点调用路径
fprof(M, F, A) ->
    fprof:start(),
    fprof:apply(M, F, A),
    fprof:profile(),
    fprof:analyse(),
    fprof:stop().

fprof(Pid) ->
    fprof:trace([start, cpu_time, {file, "./fprof.trace"}, {procs, Pid}]),  %% 或者可以trace多个Pid，[PidSpec]
    timer:sleep(30000),
    fprof:trace([stop]),
    fprof:profile({file, "./fprof.trace"}),
    fprof:analyse([{dest, "fprof.analysis"}, {sort, own}, totals, no_callers]),
    fprof:stop().
%%    format_fprof_analyze().  %% 详细参数见： http://www.erlang.org/doc/man/fprof.html#analyse-2
