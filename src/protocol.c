#include "protocol.h"

#include "net.h"

#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char SCDP_MAGIC[4] = {'S', 'C', 'D', 'P'};

int protocol_write_message(int fd, const char *message, size_t len) {
    if (len > SCDP_MAX_PAYLOAD) {
        fprintf(stderr, "scdp: message trop long (max %d octets)\n", SCDP_MAX_PAYLOAD);
        return -1;
    }

    uint8_t header[SCDP_HEADER_SIZE];
    memcpy(header, SCDP_MAGIC, 4);
    header[4] = SCDP_VERSION;

    uint32_t net_len = htonl((uint32_t)len);
    memcpy(header + 5, &net_len, 4);

    if (net_write_full(fd, header, sizeof(header)) < 0) {
        return -1;
    }
    if (len > 0 && net_write_full(fd, message, len) < 0) {
        return -1;
    }
    return 0;
}

int protocol_read_message(int fd, char **out, size_t *out_len) {
    uint8_t header[SCDP_HEADER_SIZE];
    if (net_read_full(fd, header, sizeof(header)) < 0) {
        return -1;
    }

    if (memcmp(header, SCDP_MAGIC, 4) != 0) {
        fprintf(stderr, "scdp: magic invalide\n");
        return -1;
    }

    if (header[4] != SCDP_VERSION) {
        fprintf(stderr, "scdp: version non supportée (%u)\n", header[4]);
        return -1;
    }

    uint32_t net_len;
    memcpy(&net_len, header + 5, 4);
    uint32_t len = ntohl(net_len);

    if (len > SCDP_MAX_PAYLOAD) {
        fprintf(stderr, "scdp: payload trop long (%u octets)\n", len);
        return -1;
    }

    char *buf = NULL;
    if (len > 0) {
        buf = malloc(len + 1);
        if (buf == NULL) {
            perror("malloc");
            return -1;
        }
        if (net_read_full(fd, buf, len) < 0) {
            free(buf);
            return -1;
        }
        buf[len] = '\0';
    }

    *out = buf;
    *out_len = len;
    return 0;
}

int protocol_send_ack(int fd) {
    uint8_t ack = SCDP_ACK;
    return net_write_full(fd, &ack, 1);
}

int protocol_read_ack(int fd) {
    uint8_t ack;
    if (net_read_full(fd, &ack, 1) < 0) {
        return -1;
    }
    if (ack != SCDP_ACK) {
        fprintf(stderr, "scdp: ACK invalide (0x%02x)\n", ack);
        return -1;
    }
    return 0;
}
