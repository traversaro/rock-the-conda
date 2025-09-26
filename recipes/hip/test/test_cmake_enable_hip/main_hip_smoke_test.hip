// MIT License
//
// Copyright (c) 2015-2023 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Based on https://github.com/ROCm/rocm-examples/blob/6e8d80a683fc16fe92a8e0d8490286cff67c0582/HIP-Basic/hello_world/main.hip

#include <hip/hip_runtime.h>

#include <iostream>

constexpr int error_exit_code = -1;

/// \brief Checks if the provided error code is \p hipSuccess and if not,
/// prints an error message to the standard error output and terminates the program
/// with an error code.
#define HIP_CHECK(condition)                                                                \
    {                                                                                       \
        const hipError_t error = condition;                                                 \
        if(error != hipSuccess)                                                             \
        {                                                                                   \
            std::cerr << "An error encountered: \"" << hipGetErrorString(error) << "\" at " \
                      << __FILE__ << ':' << __LINE__ << std::endl;                          \
            std::exit(error_exit_code);                                                     \
        }                                                                                   \
    }


// Functions marked with __device__ are executed on the device and called from the device only.
__device__ unsigned int get_thread_idx()
{
    // Built-in threadIdx returns the 3D coordinate of the active work item in the block of threads.
    return threadIdx.x;
}

// Functions marked with __host__ are executed on the host and called from the host.
__host__ void print_hello_host()
{
    std::cout << "Hello world from host!" << std::endl;
}

// Functions marked with __device__ and __host__ are compiled both for host and device.
// These functions cannot use coordinate built-ins.
__device__ __host__ void print_hello()
{
    // Only printf is supported for printing from device code.
    printf("Hello world from device or host!\n");
}

// Functions marked with __global__ are executed on the device and called from the host only.
__global__ void helloworld_kernel()
{
    unsigned int thread_idx = get_thread_idx();
    // Built-in blockIdx returns the 3D coorindate of the active work item in the grid of blocks.
    unsigned int block_idx = blockIdx.x;

    print_hello();

    // Only printf is supported for printing from device code.
    printf("Hello world from device kernel block %u thread %u!\n", block_idx, thread_idx);
}

int main()
{
    print_hello_host();

    print_hello();

    // Launch the kernel.
    helloworld_kernel<<<dim3(2), // 3D grid specifying number of blocks to launch: (2, 1, 1)
                        dim3(2), // 3D grid specifying number of threads to launch: (2, 1, 1)
                        0, // number of bytes of additional shared memory to allocate
                        hipStreamDefault // stream where the kernel should execute: default stream
                        >>>();

    // Wait on all active streams on the current device.
    HIP_CHECK(hipDeviceSynchronize());
}
