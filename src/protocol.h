#ifndef SCDP_PROTOCOL_H
#define SCDP_PROTOCOL_H

#include <stddef.h>
#include <stdint.h>

#define SCDP_VERSION 1
#define SCDP_MAX_PAYLOAD (64 * 1024)
#define SCDP_ACK 0x06

#define SCDP_HEADER_SIZE 9

int protocol_write_message(int fd, const char *message, size_t len);
int protocol_read_message(int fd, char **out, size_t *out_len);
int protocol_send_ack(int fd);
int protocol_read_ack(int fd);

#endif
