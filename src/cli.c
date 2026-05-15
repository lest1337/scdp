#include "cli.h"

#include "recv.h"
#include "send.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void cli_print_usage(const char *prog) {
    fprintf(stderr,
            "Usage:\n"
            "  %s recv <port>\n"
            "  %s send <host> <port> <message>\n"
            "\n"
            "Exemples:\n"
            "  %s recv 9000\n"
            "  %s send 203.0.113.42 9000 \"Bonjour\"\n",
            prog, prog, prog, prog);
}

static int parse_port(const char *s, uint16_t *out) {
    char *end = NULL;
    unsigned long val = strtoul(s, &end, 10);
    if (end == s || *end != '\0' || val == 0 || val > 65535) {
        fprintf(stderr, "scdp: port invalide: %s\n", s);
        return -1;
    }
    *out = (uint16_t)val;
    return 0;
}

int cli_run(int argc, char **argv) {
    if (argc < 2) {
        cli_print_usage(argv[0]);
        return SCDP_EXIT_USAGE;
    }

    const char *cmd = argv[1];

    if (strcmp(cmd, "recv") == 0) {
        if (argc != 3) {
            cli_print_usage(argv[0]);
            return SCDP_EXIT_USAGE;
        }
        uint16_t port;
        if (parse_port(argv[2], &port) < 0) {
            return SCDP_EXIT_USAGE;
        }
        if (scdp_recv(port) < 0) {
            return SCDP_EXIT_ERROR;
        }
        return SCDP_EXIT_OK;
    }

    if (strcmp(cmd, "send") == 0) {
        if (argc < 5) {
            cli_print_usage(argv[0]);
            return SCDP_EXIT_USAGE;
        }
        const char *host = argv[2];
        uint16_t port;
        if (parse_port(argv[3], &port) < 0) {
            return SCDP_EXIT_USAGE;
        }

        size_t msg_len = 0;
        for (int i = 4; i < argc; i++) {
            if (i > 4) {
                msg_len++;
            }
            msg_len += strlen(argv[i]);
        }

        char *message = malloc(msg_len + 1);
        if (message == NULL) {
            perror("malloc");
            return SCDP_EXIT_ERROR;
        }

        message[0] = '\0';
        for (int i = 4; i < argc; i++) {
            if (i > 4) {
                strcat(message, " ");
            }
            strcat(message, argv[i]);
        }

        int rc = scdp_send(host, port, message);
        free(message);

        if (rc < 0) {
            return SCDP_EXIT_ERROR;
        }
        return SCDP_EXIT_OK;
    }

    fprintf(stderr, "scdp: commande inconnue: %s\n", cmd);
    cli_print_usage(argv[0]);
    return SCDP_EXIT_USAGE;
}
