#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/input.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <errno.h>

#define PORT 55355
#define DEST "127.0.0.1"
#define FAST_FORWARD_MSG "FAST_FORWARD"

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s /dev/input/eventX\n", argv[0]);
        return 1;
    }

    const char *device = argv[1];
    int fd = open(device, O_RDONLY);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    struct input_event ev;

    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("socket");
        close(fd);
        return 1;
    }

    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    inet_aton(DEST, &addr.sin_addr);

    int last_value = -1;

    while (1) {
        ssize_t n = read(fd, &ev, sizeof(ev));
        if (n != sizeof(ev)) continue;

        if (ev.type == EV_ABS && ev.code == ABS_RZ) {
            if (ev.value != last_value && (ev.value == 0 || ev.value == 255)) {
                sendto(sock, FAST_FORWARD_MSG, strlen(FAST_FORWARD_MSG), 0,
                       (struct sockaddr *)&addr, sizeof(addr));
                last_value = ev.value;
            }
        }
    }

    close(sock);
    close(fd);
    return 0;
}
