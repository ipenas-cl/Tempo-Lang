#include <stdio.h>
int main() {
    printf("¡Hola desde Tempo!\n");
    printf("Compilado desde: %s\n", getenv("TEMPO_SOURCE") ? getenv("TEMPO_SOURCE") : "unknown");
    return 0;
}
