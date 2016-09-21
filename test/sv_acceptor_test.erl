-module(sv_acceptor_test).

-behaviour(acceptor_pool).
-behaviour(acceptor).

-export([start_link/1]).

-export([init/1]).

-export([acceptor_init/3,
         acceptor_continue/3,
         acceptor_terminate/2]).

start_link(Queue) ->
    acceptor_pool:start_link(?MODULE, Queue).

init(Queue) ->
    Spec = #{id => ?MODULE,
             start => {sv_acceptor, {Queue, ?MODULE, []}, []}},
    {ok, {#{}, [Spec]}}.

acceptor_init(_, _, State) ->
    {ok, State}.

acceptor_continue(_, Socket, _) ->
    loop(Socket).

acceptor_terminate(_, _) ->
    ok.

loop(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Data} ->
            _ = gen_tcp:send(Socket, Data),
            loop(Socket);
        {error, Reason} ->
            error(Reason, [Socket])
    end.
