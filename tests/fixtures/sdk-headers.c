#include <TargetConditionals.h>
#include <stdio.h>

#if !TARGET_OS_OSX
#error Expected the selected Xcode's macOS SDK
#endif

int main(void) {
    return puts("C SDK headers and linkage work") < 0;
}
