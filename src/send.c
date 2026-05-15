#include "send.h"

#include "net.h"
#include "protocol.h"

#include <string.h>

int scdp_send(const char *host, uint16_t port, const char *message) {
    int fd = net_tcp_connect(host, port);
    if (fd < 0) {
        return -1;
    }

    size_t len = strlen(message);
    if (protocol_write_message(fd, message, len) < 0) {
        net_close(fd);
        return -1;
    }

    if (protocol_read_ack(fd) < 0) {
        net_close(fd);
        return -1;
    }

    net_close(fd);
    return 0;
}
