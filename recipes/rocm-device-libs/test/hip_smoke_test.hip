#include <math.h>
extern "C" void k(float* x) {
  if (x) x[0] = sinf(0.5f);
}
