%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc emysql 返回值目前发现只有两种类型 1.int 2.binary, 初始化默认 int -> -1 binary -> <<>>
%%%
%%%
%%% add     验证非空字段，空字段选取默认值， 没有默认值integer -> -1 binary -> <<>>
%%% delete  删除目前只能根据主键/联合主键删除
%%% update  根据主键/联合主键更新，过滤掉默认值
%%% select  1.根据主键/联合主键查
%%%         2.组装select条件查询（返回100条匹配的数据）
%%% 复杂查询自己写sql语句
%%%
%%%
%%% Created : 16. 五月 2016 上午11:35
%%%-------------------------------------------------------------------
-module(emysql_to_html).

-compile(export_all).

to_module(Mod) ->
    {Y, M, D} = erlang:date(),
    {H, Mi, S} = erlang:time(),
    Time = <<(integer_to_binary(Y))/binary, "-", (integer_to_binary(M))/binary, "-", (integer_to_binary(D))/binary,
        " ", (integer_to_binary(H))/binary, ":", (integer_to_binary(Mi))/binary, ":", (integer_to_binary(S))/binary>>,

    <<"%%%-------------------------------------------------------------------
%%% @doc 自动生成，请不要手动编辑
%%%
%%% Created :"/utf8, Time/binary, "
%%%-------------------------------------------------------------------
-module(", Mod/binary, ").

-compile(export_all).

">>.

to_record(Tab, Record) ->
    Foldl =
        fun({K, V}, Acc) ->
            NewV =
                if
                    is_integer(V) -> integer_to_binary(V);
                    true ->
                        <<"<<\"", V/binary, "\">>">>
                end,
            if
                Acc == <<>> ->
                    <<"    ", K/binary, " = ", NewV/binary>>;
                true ->
                    <<Acc/binary, ",\n    ", K/binary, " = ", NewV/binary>>
            end
        end,
    NewRecord = lists:foldl(Foldl, <<>>, Record),

    <<"-record(", Tab/binary, ", {
", NewRecord/binary, "
}).


">>.

to_field(Fields) ->
    Fun =
        fun(I) ->
            Line = iolist_to_binary(binary:split(iolist_to_binary(io_lib:format("~p", [I])), <<"\n">>, [global, trim_all])),
            <<"%% ", Line/binary, "\n">>
        end,
    lists:map(Fun, Fields).

to_insert(Tab, Record) ->
    Fields = fun_arg(Record),

    Foldl =
        fun({K, V}, Values) ->
            NewV =
                if
                    is_integer(V) ->
                        <<"                \",(integer_to_binary(Record#", Tab/binary, ".", K/binary, "))/binary, \"">>;
                    V =:= <<"''">> ->
                        <<"                \",(Record#", Tab/binary, ".", K/binary, ")/binary, \"">>;
                    is_binary(V) ->
                        <<"                '\",(Record#", Tab/binary, ".", K/binary, ")/binary, \"'">>
                end,
            if
                Values == <<>> -> NewV;
                true -> <<Values/binary, ",\n", NewV/binary>>
            end
        end,
    NewValues = lists:foldl(Foldl, <<>>, Record),

    <<"


insert(Record) ->
    case insert(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

insert(Record, sql) ->
    case check_fields(Record) of
        {ok, _FieldData} ->
            <<\"insert into `pf_account` (", Fields/binary, ") value (
", NewValues/binary, "
                );\">>;
        _Err ->
            _Err
    end.


">>.

to_delete(Tab, []) ->
    <<"delete(_Record) -> io:format(\"table:", Tab/binary, "...no pri_key~n\"), {error, <<\"no_pri_key\">>}.

">>;
to_delete(Tab, PRIList) ->
    Foldl = fun({Field, V}, {Fun, Where}) ->
        Can = fun_can(Tab, Field),
        SqlWhere = fun_where(Tab, Field, V),
        Fun2 = if
                   Fun == <<>> -> Can;
                   true -> <<Fun/binary, ",", Can/binary>>
               end,
        Where2 = if
                     Where == <<>> -> SqlWhere;
                     true -> <<Where/binary, " AND ", SqlWhere/binary>>
                 end,
        {Fun2, Where2}
            end,
    {NewFun, NewWhere} = lists:foldl(Foldl, {<<>>, <<>>}, PRIList),

    <<"delete(Record) ->
    case delete(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

delete(Record, sql) ->
    case erl_can:can([", NewFun/binary, "
    ]) of
        {ok, _} ->
            <<\"delete from pf_account where
            ", NewWhere/binary, ";\">>;
        _Err ->
            _Err
    end.

">>.

to_update(Tab, _, []) ->
    <<"update(_Record) -> io:format(\"table:", Tab/binary, "...no pri_key~n\"), {error, <<\"no_pri_key\">>}.

">>;
to_update(Tab, [], _PRIList) ->
    <<"update(_Record) -> io:format(\"table:", Tab/binary, "...all pri_key~n\"), {error, <<\"all_pri_key\">>}.

">>;
to_update(Tab, OtherList, PRIList) ->
    Foldl =
        fun({Field, V}, {Fun, Where}) ->
            Can = fun_can(Tab, Field),
            SqlWhere = fun_where(Tab, Field, V),
            Fun2 = if
                       Fun == <<>> -> Can;
                       true -> <<Fun/binary, ",", Can/binary>>
                   end,
            Where2 = if
                         Where == <<>> -> SqlWhere;
                         true -> <<Where/binary, " AND ", SqlWhere/binary>>
                     end,
            {Fun2, Where2}
        end,
    {NewFun, NewWhere} = lists:foldl(Foldl, {<<>>, <<>>}, PRIList),

    Foldl1 =
        fun({Field, V}, {Acc, Num}) ->
            {NewIndex, NewV} = if
                                   is_integer(V) ->
                                       {<<"integer_to_binary(Record#", Tab/binary, ".", Field/binary, ")">>, integer_to_binary(V)};
                                   true -> {<<"Record#", Tab/binary, ".", Field/binary>>, <<"<<\"", V/binary, "\">>">>}
                               end,

            NewAcc = if
                         Num == 1 -> <<"<<>>">>;
                         true -> <<"Acc", (integer_to_binary(Num - 1))/binary>>
                     end,

            {<<Acc/binary, "            Acc", (integer_to_binary(Num))/binary,
                " = Fun(", Field/binary, ", <<\"", Field/binary, "\">>, ", NewIndex/binary, ", ", NewV/binary, ", ", NewAcc/binary, "),\n">>,
                Num + 1}
        end,
    {ArgAcc, NewNum} = lists:foldl(Foldl1, {<<>>, 1}, OtherList),
    <<"update(Record) ->
    case update(Record, sql) of
        {error, Err} -> {error, Err};
        Sql -> erl_mysql:execute(Sql)
    end.

update(Record, sql) ->
    case erl_can:can([
", NewFun/binary, "
    ]) of
        {ok, _} ->
            Fun =
                fun(K, KBin, V, Default, Acc) ->
                    if
                        V =:= Default -> Acc;
                        true ->
                            case match_type(K, V) of
                                true ->
                                    <<Acc/binary, \", \", KBin/binary, \" = \", V/binary>>;
                                false -> Acc
                            end
                    end
                end,
", ArgAcc/binary, "
            <<\"update pf_account set \", Acc", (integer_to_binary(NewNum - 1))/binary, "/binary, \" where
   ", NewWhere/binary, ";\">>;
        _Err ->
            _Err
    end.

">>.


to_lookup(Tab, _, []) ->
    <<"lookup(_Record) -> io:format(\"table:", Tab/binary, "...no pri_key~n\"), {error, <<\"no_pri_key\">>}.

">>;

to_lookup(Tab, [], _) ->
    <<"lookup(_Record) -> io:format(\"table:", Tab/binary, "...all pri_key~n\"), {error, <<\"all_pri_key\">>}.

">>;

to_lookup(Tab, AccRecord, PRIList) ->
    Foldl =
        fun({Field, V}, {Fun, Where}) ->
            Can = fun_can(Tab, Field),
            SqlWhere = fun_where(Tab, Field, V),
            Fun2 = if
                       Fun == <<>> -> Can;
                       true -> <<Fun/binary, ",", Can/binary>>
                   end,
            Where2 = if
                         Where == <<>> -> SqlWhere;
                         true -> <<Where/binary, " AND ", SqlWhere/binary>>
                     end,
            {Fun2, Where2}
        end,
    {NewFun, NewWhere} = lists:foldl(Foldl, {<<>>, <<>>}, PRIList),

    NewFields = fun_arg(AccRecord),

    <<"lookup(Record) ->
    case lookup(Record, sql) of
        {error, _Err} -> {error, _Err};
        Sql -> erl_mysql:execute(Sql)
    end.

lookup(Record, sql) ->
    case erl_can:can([
", NewFun/binary, "
    ]) of
        {ok, _} ->
            <<\"select ", NewFields/binary, " from ", Tab/binary, "
            where
            ", NewWhere/binary, "
            ;\">>;

        _Err -> %% select all
            _Err
    end.

">>.


to_check_fields(Tab, Record) ->
    Can = lists:foldl(
        fun({K, _V}, Fields) ->
            if
                Fields =:= <<>> ->
                    <<"        fun() -> check_field(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>;
                true ->
                    <<Fields/binary, ",\n        fun() -> check_field(", Tab/binary, ", '", K/binary, "', Record#", Tab/binary, ".", K/binary, ") end">>
            end
        end, <<>>, Record),

    <<"check_fields(Record) ->
case erl_can:can([
", Can/binary, "
    ]) of
        {ok, FieldData} ->
            {ok, FieldData};
        ErrCode -> ErrCode
    end.


">>.

to_check_field() ->
    <<"check_field(Table, Field, Value) ->
    case is_match_null(Field, Value) of
        true ->
            case match_type(Field, Value) of
                true -> {ok, {Field, Value}};
                false ->
                    io:format(\"error record:~p..key:~p value:~p not match type~n\", [Table, Field, Value]),
                    {error, not_match_type}
            end;
        false ->
            io:format(\"error record:~p..key:~p value:~p not match null~n\", [Table, Field, Value]),
            {error, not_match_null}
    end.

match_type(K, V) ->
    case is_match_type(K, V) of
        true ->
            erl_mysql:illegal_character(V);
        false ->
            false
    end.

">>.


to_match_null(AccMatchNull) ->
    Fun =
        fun({K, V}) ->
            KArg = list_to_binary(string:to_upper(binary_to_list(K))),
            if
                (V =:= true) -> <<"\nis_match_null('", K/binary, "', _", KArg/binary, ") -> true;">>;
                is_integer(V) ->
                    <<"\nis_match_null('", K/binary, "', ", KArg/binary, ") -> ", KArg/binary, " =/= ", (integer_to_binary(V))/binary, ";">>;
                true ->
                    <<"\nis_match_null('", K/binary, "', ", KArg/binary, ") -> ", KArg/binary, " =/= ", V/binary, ";">>
            end
        end,
    <<
        (iolist_to_binary(lists:map(Fun, AccMatchNull)))/binary,
        "\nis_match_null(_K, _V) ->
    io:format(\"error no this field:~p~n\", [[_K, _V]]),
    false.

">>.


to_match_type(AccMatchType) ->
    Fun =
        fun(Data) ->
            case Data of
                {K, int} ->
                    KArg = list_to_binary(string:to_upper(binary_to_list(K))),
                    <<"\nis_match_type('", K/binary, "', ", KArg/binary, ") -> is_integer(", KArg/binary, ") andalso ", KArg/binary, " >= -2147483648 andalso ", KArg/binary, " =< 2147483648;">>;
                {K, binary} ->
                    KArg = list_to_binary(string:to_upper(binary_to_list(K))),
                    <<"\nis_match_type('", K/binary, "', ", KArg/binary, ") -> is_binary(", KArg/binary, ");">>;
                {K, binary, Len} ->
                    KArg = list_to_binary(string:to_upper(binary_to_list(K))),
                    <<"\nis_match_type('", K/binary, "', ", KArg/binary, ") -> is_binary(", KArg/binary, ") andalso byte_size(", KArg/binary, ") =< ", Len/binary, ";">>
            end
        end,
    <<
        (iolist_to_binary(lists:map(Fun, AccMatchType)))/binary,
        "\nis_match_type(_K, _V) ->
    io:format(\"error no this field:~p~n\", [[_K, _V]]),
    false.

">>.


fun_arg(AccRecord) ->
    lists:foldl(
        fun({K, _V}, Fields) ->
            if
                Fields =:= <<>> -> K;
                true -> <<Fields/binary, ",", K/binary>>
            end
        end, <<>>, AccRecord).

fun_can(Tab, Field) ->
    <<"\n        fun() -> check_field(", Tab/binary, ", '", Field/binary, "', Record#", Tab/binary, ".", Field/binary, ") end">>.

fun_where(Tab, Field, V) ->
    if
        is_integer(V) ->
            <<Field/binary, " = \",(integer_to_binary(Record#", Tab/binary, ".", Field/binary, "))/binary, \"">>;
        V =:= <<"''">> ->
            <<Field/binary, " = \",(Record#", Tab/binary, ".", Field/binary, ")/binary, \"">>;
        is_binary(V) ->
            <<Field/binary, " = '\",(Record#", Tab/binary, ".", Field/binary, ")/binary, \"'">>
    end.