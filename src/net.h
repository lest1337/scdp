#ifndef SCDP_NET_H
#define SCDP_NET_H

#include <stddef.h>
#include <stdint.h>

int net_read_full(int fd, void *buf, size_t len);
int net_write_full(int fd, const void *buf, size_t len);

int net_tcp_listen(uint16_t port);
int net_tcp_connect(const char *host, uint16_t port);
int net_tcp_accept(int listen_fd);

void net_close(int fd);

#endif
