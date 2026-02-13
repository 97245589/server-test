include "config.include"

cluster_port = 10030
gate_port = 10031
server_name = "login"
server_mark = server_name

thread = 3
if $DAEMON then
    logger = "run/" .. server_mark .. ".log"
    daemon = "run/" .. server_mark .. ".pid"
end