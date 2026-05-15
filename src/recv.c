#include "recv.h"

#include "net.h"
#include "protocol.h"

#include <stdio.h>
#include <stdlib.h>

int scdp_recv(uint16_t port) {
    int listen_fd = net_tcp_listen(port);
    if (listen_fd < 0) {
        return -1;
    }

    fprintf(stderr, "scdp: en attente sur le port %u...\n", port);

    int conn_fd = net_tcp_accept(listen_fd);
    net_close(listen_fd);
    if (conn_fd < 0) {
        return -1;
    }

    char *message = NULL;
    size_t len = 0;
    if (protocol_read_message(conn_fd, &message, &len) < 0) {
        net_close(conn_fd);
        return -1;
    }

    if (len > 0) {
        fwrite(message, 1, len, stdout);
    }
    fputc('\n', stdout);
    fflush(stdout);

    free(message);

    if (protocol_send_ack(conn_fd) < 0) {
        net_close(conn_fd);
        return -1;
    }

    net_close(conn_fd);
    return 0;
}
