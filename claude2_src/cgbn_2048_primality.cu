// CGBN 2048-bit Primality Tester - for up to 617 digit numbers
// Fixes: 309-digit overflow bug (needs 1027 bits, was using 1024)
#include <gmp.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <cuda.h>
#include "CGBN/include/cgbn/cgbn.h"

template<uint32_t tpi, uint32_t bits, uint32_t window_bits>
class mr_params_t {
  public:
  static const uint32_t TPB=0;
  static const uint32_t MAX_ROTATION=4;
  static const uint32_t SHM_LIMIT=0;
  static const bool     CONSTANT_TIME=false;
  static const uint32_t TPI=tpi;
  static const uint32_t BITS=bits;
  static const uint32_t WINDOW_BITS=window_bits;
};

template<class params>
class miller_rabin_t {
  public:
  static const uint32_t window_bits=params::WINDOW_BITS;

  typedef struct {
    cgbn_mem_t<params::BITS> candidate;
    uint32_t                 passed;
  } instance_t;

  typedef cgbn_context_t<params::TPI, params>    context_t;
  typedef cgbn_env_t<context_t, params::BITS>    env_t;
  typedef typename env_t::cgbn_t                 bn_t;
  typedef typename env_t::cgbn_local_t           bn_local_t;
  typedef typename env_t::cgbn_wide_t            bn_wide_t;

  context_t _context;
  env_t     _env;
  int32_t   _instance;

  __device__ __forceinline__ miller_rabin_t(cgbn_monitor_t monitor, cgbn_error_report_t *report, int32_t instance)
    : _context(monitor, report, (uint32_t)instance), _env(_context), _instance(instance) {}

  __device__ __forceinline__ void powm(bn_t &x, const bn_t &power, const bn_t &modulus) {
    bn_t       t;
    bn_local_t window[1<<window_bits];
    int32_t    index, position, offset;
    uint32_t   np0;

    cgbn_negate(_env, t, modulus);
    cgbn_store(_env, window+0, t);
    np0=cgbn_bn2mont(_env, x, x, modulus);
    cgbn_store(_env, window+1, x);
    cgbn_set(_env, t, x);

    #pragma nounroll
    for(index=2;index<(1<<window_bits);index++) {
      cgbn_mont_mul(_env, x, x, t, modulus, np0);
      cgbn_store(_env, window+index, x);
    }

    position=params::BITS - cgbn_clz(_env, power);
    offset=position % window_bits;
    if(offset==0) position=position-window_bits;
    else position=position-offset;
    index=cgbn_extract_bits_ui32(_env, power, position, window_bits);
    cgbn_load(_env, x, window+index);

    while(position>0) {
      #pragma nounroll
      for(int sqr_count=0;sqr_count<window_bits;sqr_count++)
        cgbn_mont_sqr(_env, x, x, modulus, np0);
      position=position-window_bits;
      index=cgbn_extract_bits_ui32(_env, power, position, window_bits);
      cgbn_load(_env, t, window+index);
      cgbn_mont_mul(_env, x, x, t, modulus, np0);
    }
    cgbn_mont2bn(_env, x, x, modulus, np0);
  }

  __device__ __forceinline__ uint32_t miller_rabin(const bn_t &candidate, uint32_t *primes, uint32_t prime_count) {
    int       k, trailing, count;
    bn_t      x, power, minus_one;
    bn_wide_t w;

    // Check if candidate is even (Montgomery requires odd modulus)
    if((cgbn_extract_bits_ui32(_env, candidate, 0, 1) & 1) == 0) {
      return 0;  // Even numbers are composite (except 2, handled separately)
    }

    cgbn_sub_ui32(_env, power, candidate, 1);
    trailing=cgbn_ctz(_env, power);
    cgbn_shift_right(_env, power, power, trailing);  // Use shift, not rotate

    for(k=0;k<prime_count;k++) {
      cgbn_set_ui32(_env, x, primes[k]);
      powm(x, power, candidate);
      cgbn_sub_ui32(_env, minus_one, candidate, 1);
      if(!cgbn_equals_ui32(_env, x, 1) && !cgbn_equals(_env, x, minus_one)) {
        if(trailing==1) return k;
        count=trailing;
        while(true) {
          cgbn_sqr_wide(_env, w, x);
          cgbn_rem_wide(_env, x, w, candidate);
          if(cgbn_equals(_env, x, minus_one)) break;
          if(--count==0 || cgbn_equals_ui32(_env, x, 1)) return k;
        }
      }
    }
    return prime_count;
  }
};

// 2048-bit: TPI=32, enough for 617-digit numbers
typedef mr_params_t<32, 2048, 5> params_2048;
typedef miller_rabin_t<params_2048>::instance_t instance_t;

template<class params>
__global__ void kernel_miller_rabin(cgbn_error_report_t *report,
                                    typename miller_rabin_t<params>::instance_t *instances,
                                    uint32_t instance_count, uint32_t *primes, uint32_t prime_count) {
  int32_t instance=(blockIdx.x*blockDim.x + threadIdx.x)/params::TPI;
  if(instance>=instance_count) return;

  typedef miller_rabin_t<params> local_mr_t;
  local_mr_t                mr(cgbn_report_monitor, report, instance);
  typename local_mr_t::bn_t candidate;

  cgbn_load(mr._env, candidate, &(instances[instance].candidate));
  instances[instance].passed = mr.miller_rabin(candidate, primes, prime_count);
}

#define CUDA_CHECK(call) { cudaError_t err = call; if(err != cudaSuccess) { fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(err)); exit(1); } }
#define CGBN_CHECK(report) { if(cgbn_error_report_check(report)) { fprintf(stderr, "CGBN error\n"); exit(1); } }

int main(int argc, char **argv) {
  if (argc < 3) {
    fprintf(stderr, "Usage: %s input.bin output.bin\n", argv[0]);
    fprintf(stderr, "  Input: 256-byte little-endian 2048-bit numbers\n");
    fprintf(stderr, "  Output: 1 byte per number (1=prime, 0=composite)\n");
    return 1;
  }

  uint32_t prime_count = 12;
  uint32_t primes[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37};

  FILE *fin = fopen(argv[1], "rb");
  if (!fin) { fprintf(stderr, "Cannot open %s\n", argv[1]); return 1; }
  fseek(fin, 0, SEEK_END);
  long fsize = ftell(fin);
  fseek(fin, 0, SEEK_SET);

  // 256 bytes = 2048 bits per number
  uint32_t instance_count = fsize / 256;
  if (instance_count < 32) {
    fprintf(stderr, "Need at least 32 numbers, got %u\n", instance_count);
    fclose(fin);
    return 1;
  }

  instance_t *instances = (instance_t *)malloc(sizeof(instance_t) * instance_count);
  for (uint32_t i = 0; i < instance_count; i++) {
    fread(instances[i].candidate._limbs, 4, 64, fin);  // 64 limbs x 4 bytes = 256 bytes
    instances[i].passed = 0;
  }
  fclose(fin);

  instance_t *gpu_instances;
  uint32_t *gpu_primes;
  cgbn_error_report_t *report;

  CUDA_CHECK(cudaMalloc(&gpu_instances, sizeof(instance_t) * instance_count));
  CUDA_CHECK(cudaMalloc(&gpu_primes, sizeof(uint32_t) * prime_count));
  CUDA_CHECK(cudaMemcpy(gpu_instances, instances, sizeof(instance_t) * instance_count, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(gpu_primes, primes, sizeof(uint32_t) * prime_count, cudaMemcpyHostToDevice));
  CUDA_CHECK(cgbn_error_report_alloc(&report));

  int TPB = 128, TPI = 32, IPB = TPB / TPI;

  kernel_miller_rabin<params_2048><<<(instance_count+IPB-1)/IPB, TPB>>>(report, gpu_instances, instance_count, gpu_primes, prime_count);
  CUDA_CHECK(cudaDeviceSynchronize());
  CGBN_CHECK(report);

  CUDA_CHECK(cudaMemcpy(instances, gpu_instances, sizeof(instance_t) * instance_count, cudaMemcpyDeviceToHost));

  FILE *fout = fopen(argv[2], "wb");
  if (!fout) { fprintf(stderr, "Cannot open %s\n", argv[2]); return 1; }

  for (uint32_t i = 0; i < instance_count; i++) {
    uint8_t is_prime = (instances[i].passed == prime_count) ? 1 : 0;
    fwrite(&is_prime, 1, 1, fout);
  }
  fclose(fout);

  fprintf(stderr, "Tested %u numbers\n", instance_count);

  free(instances);
  CUDA_CHECK(cudaFree(gpu_instances));
  CUDA_CHECK(cudaFree(gpu_primes));
  CUDA_CHECK(cgbn_error_report_free(report));
  return 0;
}
