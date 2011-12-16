%% @doc
%% The log interface towards a Zerolog daemon.
%% @end
%% ----------------------------------------------------------------------
%% Copyright (c) 2011 Evolope
%% Authors: Bip Thelin <bip.thelin@evolope.se>
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% ----------------------------------------------------------------------

-module(alog_zerolog).
-author('Bip Thelin <bip.thelin@evolope.se>').
-behaviour(gen_alog).
-behaviour(gen_server).
-include_lib("alog.hrl").

%% API
-export([start_link/1]).

%% gen_alog callbacks
-export([start/1,
         stop/1,
         log/2,
         format/8]).
%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {context, socket}).

-define(DEF_SUP_REF, alog_sup).

-define(DEF_ADDR, ["tcp://localhost:2121"]).

%%% API
%% @doc Starts logger
-spec start_link(list()) -> pid().
start_link(Opts) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Opts], []).

%%% gen_alog callbacks
%% @private
-spec start(list()) -> ok.
start(Opts) ->
    SupRef = gen_alog:get_opt(sup_ref, Opts, ?DEF_SUP_REF),
    attach_to_supervisor(SupRef, Opts),
    ok.

%% @private
-spec stop(list()) -> ok.
stop(_) ->
    ok.

%% @private
-spec log(integer(), string()) -> ok.
log(ALoggerPrio, Msg) ->
    ZerologPrio = map_prio(ALoggerPrio),
    gen_server:cast(?MODULE, {log, ZerologPrio, Msg}),
    ok.

%% @private
%% @doc returns formated log message
-spec format(string(), [term()], integer(), list(),
             atom(), integer(), pid(),
             {non_neg_integer(), non_neg_integer(), non_neg_integer()}) -> iolist().
format(FormatString, Args, Level, Tag, Module, Line, Pid, TimeStamp) ->
    Msg = alog_common_formatter:format(FormatString, Args, Level,
                                       Tag, Module, Line, Pid, TimeStamp),
    lists:flatten(Msg).


%%% gen_server callbacks
%% @private
init([Opts]) ->
    Addr = gen_alog:get_opt(addr, Opts, ?DEF_ADDR),
	{ok, Context} = erlzmq:context(),
    {ok, Socket} = erlzmq:socket(Context, push),
    zerolog_connect(Socket, Addr),
	process_flag(trap_exit, true),
	{ok, #state{context=Context, socket=Socket}}.

%% @private
handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

%% @private
handle_cast({log, ZerologPrio, Msg},
            #state{context = _Context, socket = Socket} = State) ->
	Message = term_to_binary({ZerologPrio, Msg}),
	erlzmq:send(Socket, Message),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% @private
handle_info(_Msg, StateData) ->
    {noreply, StateData}.

%% @private
terminate(_Reason, #state{context = Context, socket = Socket} = _State) ->
	erlzmq:close(Socket),
    erlzmq:term(Context).

%% @private
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%% Internal functions
%% @private
zerolog_connect(_Socket, []) ->
	ok;
	
zerolog_connect(Socket, [H|T]) ->
	erlzmq:connect(Socket, H),
	zerolog_connect(Socket, T).

%% @private
%% @doc Maps alogger priorities to scribe priorities
-spec map_prio(integer()) -> string().
map_prio(?emergency) -> "emergency";
map_prio(?alert)     -> "alert";
map_prio(?critical)  -> "critical";
map_prio(?error)     -> "error";
map_prio(?warning)   -> "warning";
map_prio(?notice)    -> "notice";
map_prio(?info)      -> "info";
map_prio(?debug)     -> "debug".

%% @private
attach_to_supervisor(SupRef, Opts) ->
    Restart = permanent,
    Shutdown = 2000,
    ChildSpec = {?MODULE,
                 {?MODULE, start_link, [Opts]},
                 Restart,
                 Shutdown,
                 worker,
                 [?MODULE]},
    supervisor:start_child(SupRef, ChildSpec),
    ok.
