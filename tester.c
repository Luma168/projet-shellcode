#include <stdio.h>
#include <string.h>
#include <sys/mman.h>

// sudo apt install libc6-dev-i386
// gcc (-m32) -z execstack -fno-stack-protector (-fno-pie | -fpic) -z norelro testSC.c -o testSC

char shellcode[] = "\xeb\x1d\x5e\x48\x31\xff\x40\xfe\xc7\x48\x31";

void main() {
    const char *fname = "out.bin";
    FILE *f = fopen(fname, "rb");
    void *buf = NULL;
    size_t len = 0;

    if (f) {
        fseek(f, 0, SEEK_END);
        len = ftell(f);
        fseek(f, 0, SEEK_SET);
        buf = mmap(NULL, len, PROT_READ | PROT_WRITE | PROT_EXEC,
                   MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);
        if (buf) {
            fread(buf, 1, len, f);
            fclose(f);
            printf("Loaded %s (%zu bytes) and executing...\n", fname, len);
            ((void (*)(void)) buf)();
            return;
        }
        fclose(f);
    }

    /* Fallback: execute built-in shellcode */
    printf("Using builtin shellcode (len=%zu)\n", strlen(shellcode));
    void * a = mmap(0, strlen(shellcode), PROT_EXEC | PROT_READ |
                    PROT_WRITE, MAP_ANONYMOUS | MAP_SHARED, -1, 0);

    ((void (*)(void)) memcpy(a, shellcode, strlen(shellcode)))();
}