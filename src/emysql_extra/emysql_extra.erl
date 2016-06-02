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
-module(emysql_extra).

-compile(export_all).

-record(field, {
    field,      %
    type,
    collation,
    is_null,
    key,
    default, %如果是undefined
    extra,
    privileges,
    comment
}).

main() ->
    {ok, Pools} = application:get_env(emysql, pools),
    Fun = fun({_, Config}) ->
        {_, Database} = lists:keyfind(database, 1, Config),
        AllTable = erl_mysql:execute(<<"select TABLE_NAME from information_schema.`TABLES` where TABLE_SCHEMA = '", (list_to_binary(Database))/binary, "'">>),
        lists:map(fun([TableName]) -> table(TableName) end, AllTable)
          end,
    lists:map(Fun, Pools).


table(TableName) ->
    Fields = erl_mysql:execute(<<"SHOW FULL FIELDS  FROM `platform_info`.`", TableName/binary, "`;">>),
    Data = get(Fields, Fields, TableName, [], [], [], [], []),
    os:cmd("mkdir -p ./src/auto/mysql"),
    file:write_file(<<"./src/auto/mysql/", TableName/binary, ".erl">>, Data).


get([], Fields, TableName, AccPRI, AccOther, AccRecord, AccMatchNull, AccMatchType) ->
    NewRecord = lists:reverse(AccRecord),
    NewPRI = lists:reverse(AccPRI),
    [
        emysql_to_html:to_module(TableName),
        emysql_to_html:to_record(TableName, NewRecord),
        emysql_to_html:to_field(Fields),
        emysql_to_html:to_insert(TableName, NewRecord),
        emysql_to_html:to_delete(TableName, NewPRI),
        emysql_to_html:to_update(TableName, lists:reverse(AccOther), NewPRI),
        emysql_to_html:to_lookup(TableName, NewRecord, NewPRI),
        emysql_to_html:to_check_fields(TableName, NewRecord),
        emysql_to_html:to_check_field(),
        emysql_to_html:to_match_null(lists:reverse(AccMatchNull)),
        emysql_to_html:to_match_type(lists:reverse(AccMatchType))
    ];


get([[Field, DataType, _Encode, IsNull, Index, Default, _FieldType, _, _Anno] | Fields], Fields2, TableName, AccPRI, AccOther, AccRecord, AccMatchNull, AccMatchType) ->
    Record = check_record(Field, DataType, Default),
    MatchType = check_type(Field, DataType),

    NewAccMatchNull = if
                          IsNull =:= <<"YES">> -> [Record | AccMatchNull];
                          true ->
                              [{Field, true} | AccMatchNull]
                      end,
    {NewAccPRI, NewAccOther} = if
                                   Index =:= <<"PRI">> -> {[Record | AccPRI], AccOther};
                                   true -> {AccPRI, [Record | AccOther]}
                               end,
    get(Fields, Fields2, TableName, NewAccPRI, NewAccOther, [Record | AccRecord], NewAccMatchNull, [MatchType | AccMatchType]).



check_record(Field, DataType, Default) ->
    case binary:match(DataType, <<"int">>) of
        nomatch ->
            NewDefault = if
                             Default =:= undefined -> <<"''">>;
                             Default =:= <<>> -> <<"''">>;
                             true -> Default
                         end,
            {Field, NewDefault};
        _ ->
            NewDefault = if
                             Default =:= undefined -> 0;
                             true -> binary_to_integer(Default)
                         end,
            {Field, NewDefault}
    end.


%% 目前只识别常用的格式
%%int -2^31 (-2,147,483,648) 到 2^31 - 1 (2,147,483,647) 的整型数据
-define(ALL_TYPE, [<<"int">>, <<"char">>, <<"varchar">>, <<"binary">>]).
-spec check_type(Field :: binary(), DataType :: binary()) -> {binary(), int} | {binary(), binary} | {binary(), binary, integer()}.
check_type(Field, DataType) ->
    case binary:match(DataType, <<"int">>) of
        nomatch ->
            check_type(?ALL_TYPE, DataType, Field);
        _ ->
            {Field, int}
    end.

check_type([], _, Field) -> {Field, binary};
check_type([Type | Types], DataType, Field) ->
    case binary:match(DataType, Type) of
        {0, Len} ->
            {Field, binary, binary:part(DataType, Len + 1, byte_size(DataType) - Len - 2)};
        _ ->
            check_type(Types, DataType, Field)
    end.



