﻿
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>


#define N 100


__device__ double f(double* x) {
    return *x * *x;
}


__global__ void integralByMiddleQuad(double* c, const double* h, const double* a)
{
    __shared__ double csh[32];

    double x = *a + (double)(blockIdx.x * 32 + threadIdx.x) * *h;

    //printf("x = %f\n", x);

    csh[threadIdx.x] = f(&x);

    __syncthreads();

    if (blockIdx.x * 32 + threadIdx.x < N + 1 ) {
        //printf("NUM %d = threadash[%d] = %f  \n", blockIdx.x * 32 + threadIdx.x, threadIdx.x, csh[threadIdx.x]);
        c[blockIdx.x * 32 + threadIdx.x] = csh[threadIdx.x];
       // printf("c = %f\n", c[blockIdx.x * 32 + threadIdx.x]);
    }

}

int main()
{

    double a=3;
    double b=6;
    double h= (b - a) / N;
    double c[N+1];

 

    double* dev_a = 0;
    double* dev_h = 0;
    double* dev_c = 0;
    cudaError_t cudaStatus;

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, (N+1)*sizeof(double));

    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        return 1;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        return 2;
    }

    cudaStatus = cudaMalloc((void**)&dev_h, sizeof(double));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        return 3;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, &a, sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        return 4;
    }

    cudaStatus = cudaMemcpy(dev_h, &h, sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        return 5;
    }
    cudaStatus = cudaMemcpy(dev_c, c, (N+1)*sizeof(double), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        return 55;
    }

    // Launch a kernel on the GPU with one thread for each element.
    int blockSize;

    blockSize = N / 32 + 1;
    // Launch a kernel on the GPU with one thread for each element.
    integralByMiddleQuad << <blockSize, 32 >> > (dev_c, dev_h, dev_a);




    cudaStatus = cudaMemcpy(c, dev_c, (N+1) * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        return 6;
    }

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        return 7;
    }

    double sum = 0;
    for (int i = 0; i < N; ++i) {
        sum += (c[i] + c[i+1])/2;
    }
    sum /= N / (b-a);
    printf("integralByMiddleQuad = %f\n", sum);


    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        return 8;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, N * sizeof(double), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        return 9;
    }



    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_h);



    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 10;
    }



    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 11;
    }

    return 0;
}

