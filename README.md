sv_acceptor
===========

`safetyvalve` rate limited `acceptor_pool` acceptor. Wraps an `acceptor`
callback module to regulated accepting of new sockets. `sv_acceptor` is an
`acceptor` with arguments `{SVQueue, Module, Args}`, where `SVQueue` is the
`safetyvalve` queue. `Module` and `Args` are the `acceptor` callback module and
argument.
