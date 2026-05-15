#ifndef SCDP_SEND_H
#define SCDP_SEND_H

#include <stdint.h>

int scdp_send(const char *host, uint16_t port, const char *message);

#endif
