#ifndef VERILATOR_EMSCRIPTEN_FIXES_H
#define VERILATOR_EMSCRIPTEN_FIXES_H

#include <utility> // Ensure std::exchange is declared

// Forward declare the vlstd namespace if it might not exist yet,
// though Verilator headers should define it.
namespace vlstd {}

// Bring std::exchange into the vlstd namespace.
// This should happen after Verilator might have defined `namespace vlstd = ::std;`
// or its own `vlstd` namespace. By putting it in a separate header that's
// force-included, we hope to apply this fix at the right point.
namespace vlstd {
    using ::std::exchange;
}

#endif // VERILATOR_EMSCRIPTEN_FIXES_H