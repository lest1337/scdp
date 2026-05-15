#ifndef SCDP_CLI_H
#define SCDP_CLI_H

#define SCDP_EXIT_OK 0
#define SCDP_EXIT_USAGE 1
#define SCDP_EXIT_ERROR 2

void cli_print_usage(const char *prog);
int cli_run(int argc, char **argv);

#endif
