#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "../user/user.h"
#include "kernel/fcntl.h"

int main(int argc,char **argv)
{
    uint mask = atoi(argv[1]);
    trace(mask);
    char **argv2 = argv;
    for(int i=2;i<=argc;i++)
    {
        argv2[i-2] = argv[i];
    }
    exec(argv2[0],argv2);
    exit(0);
}

// strace 2147483647 grep hello README