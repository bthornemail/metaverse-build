#include <stdio.h>
#include <string.h>

int validate(const char *json) {
    if (strstr(json, "valid:") != NULL) return 1;
    return 0;
}

int main() {
    char line[4096];
    while (fgets(line, sizeof(line), stdin)) {
        if (validate(line)) {
            printf("OK\n");
        } else {
            printf("HALT\n");
        }
        fflush(stdout);
    }
    return 0;
}
