# DuckDuckGoose

DuckDuckGoose declares a single node from a cluster the goose and all other nodes ducks. The election process to determine the goose is inspired by the Raft leader election strategy.

Redis is used to track the configuration of the cluster to determine the quorum. As nodes are spun up for the first time they add their name to the node list in Redis. They can also be purposefully removed from the cluster where they remove their name from the Redis list.

When a node starts, it checks to see if its name is in the Redis node list and adds it if necessary. It sets its status to be a duck and waits to hear a a heartbeat from a goose. If it receives a heartbeat from a goose it responds with an acknowledgement and resets its timeout. If it does not receive a heartbeat from a goose within a specified timeout, it starts an election and sends a message to all nodes from the Redis list requesting their vote.

If it receives a quorum of votes, it sets its status to be the goose and broadcasts a goose heartbeat to all the nodes. If it does not receive a quorum of votes or a hearbeat from an elected goose before its timeout, then it restarts the election process. However, if it is an elected goose then it waits to receive a quorum of acknowledgements to its hearbeats, and if it fails to do so within the timeout window, then it starts a new election process.

The status of any node can be checked at an http endpoint, for example `localhost:4001`.


## How to Run Locally

To run locally, first start a redis server with `redis-server`.

Then from the project directory run `mix deps.get`.

To start a node, open a terminal window and first set the http port for the server with `export DDG_HTTP_PORT=4001`. Then start the server with an sname so it is recognized as an erlang node on the local network, `iex --sname one -S mix`.

To start additional nodes, open a new terminal window and set a different port number, `export DDG_HTTP_PORT=4002`, and start the server with a different sname, `iex --sname two -S mix`.

Logging is setup to show when a node sends and receives heartbeats and acknowledgments.

To remove a node from the cluster, run `DuckDuckGoose.RedisClient.remove_node()` from its iex shell and then kill the server.
