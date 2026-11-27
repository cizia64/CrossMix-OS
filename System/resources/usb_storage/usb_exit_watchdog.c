/* Fallback for the stock USB Storage UI when it fails to receive B.
 * EVIOCGKEY reads the current state even when another process grabs events.
 * No input event is consumed and only our direct sibling UI process is killed.
 */
#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define WORD_BITS (sizeof(unsigned long) * 8)
#define KEY_WORDS ((KEY_MAX + WORD_BITS) / WORD_BITS)
#define DEVICE "/dev/input/event3"
#define BUTTON_B 304

static void pause_ms(long ms) {
    struct timespec t = {ms / 1000, (ms % 1000) * 1000000L};
    while (nanosleep(&t, &t) < 0 && errno == EINTR) {}
}

static int test_bit(const unsigned long *bits, unsigned int bit) {
    return (bits[bit / WORD_BITS] >> (bit % WORD_BITS)) & 1UL;
}

/* PPid prevents touching a reused pid or another app with the same name. */
static int is_our_ui(pid_t pid, pid_t parent) {
    char path[80], line[256], name[64] = "";
    long ppid = -1;
    snprintf(path, sizeof(path), "/proc/%ld/status", (long)pid);
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "Name:", 5) == 0) sscanf(line + 5, "%63s", name);
        if (strncmp(line, "PPid:", 5) == 0) sscanf(line + 5, "%ld", &ppid);
    }
    fclose(f);
    return strcmp(name, "usb_storage") == 0 && ppid == (long)parent;
}

int main(int argc, char **argv) {
    char *end = NULL;
    if (argc != 2) { fprintf(stderr, "usage: %s usb_storage_pid\n", argv[0]); return 2; }
    errno = 0;
    long target = strtol(argv[1], &end, 10);
    if (errno || !end || *end || target <= 1) { fprintf(stderr, "invalid UI pid\n"); return 2; }
    pid_t pid = (pid_t)target, parent = getppid();
    if ((long)pid != target || !is_our_ui(pid, parent)) {
        fprintf(stderr, "UI process does not match parent and name\n"); return 1;
    }

    int fd = -1, armed = 0;
    while (is_our_ui(pid, parent)) {
        if (fd < 0) {
            fd = open(DEVICE, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
            if (fd < 0) {
                fprintf(stderr, "cannot open %s: %s; retrying\n", DEVICE, strerror(errno));
                pause_ms(1000); continue;
            }
            unsigned long supported[KEY_WORDS] = {0};
            if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(supported)), supported) < 0 || !test_bit(supported, BUTTON_B)) {
                fprintf(stderr, "%s does not report button B; retrying\n", DEVICE);
                close(fd); fd = -1; pause_ms(1000); continue;
            }
            fprintf(stderr, "monitoring %s for button B\n", DEVICE);
            armed = 0;
        }
        unsigned long down[KEY_WORDS] = {0};
        if (ioctl(fd, EVIOCGKEY(sizeof(down)), down) < 0) {
            fprintf(stderr, "cannot read button state: %s; retrying\n", strerror(errno));
            close(fd); fd = -1; armed = 0; pause_ms(1000); continue;
        }
        int pressed = test_bit(down, BUTTON_B);
        if (!pressed) armed = 1;
        if (armed && pressed && is_our_ui(pid, parent)) {
            fprintf(stderr, "B pressed; requesting USB Storage UI exit\n");
            if (kill(pid, SIGTERM) < 0 && errno != ESRCH) fprintf(stderr, "SIGTERM: %s\n", strerror(errno));
            pause_ms(1000);
            if (is_our_ui(pid, parent)) {
                fprintf(stderr, "UI still running; forcing UI exit\n");
                if (kill(pid, SIGKILL) < 0 && errno != ESRCH) fprintf(stderr, "SIGKILL: %s\n", strerror(errno));
            }
            break;
        }
        pause_ms(30);
    }
    if (fd >= 0) close(fd);
    return 0;
}
