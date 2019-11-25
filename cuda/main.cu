#include<stdio.h> 
#include<stdlib.h>

// Macro for checking errors in CUDA API calls
#define cudaErrorCheck(call)                                                              \
do{                                                                                       \
    cudaError_t cuErr = call;                                                             \
    if(cudaSuccess != cuErr){                                                             \
      printf("CUDA Error - %s:%d: '%s'\n", __FILE__, __LINE__, cudaGetErrorString(cuErr));\
      exit(0);                                                                            \
    }                                                                                     \
}while(0)

// Kernel
__global__ void convert_to_gray(unsigned char* color_array, unsigned char* gray_array, int x, int y)
{
  int id = blockDim.x * blockIdx.x + threadIdx.x;

	if(id < x*y) gray_array[id] = color_array[3*(id)+0]*0.21 + color_array[3*(id)+1]*0.72 + color_array[3*(id)+2]*0.07;
	
}	

// Main program
int main() 
{ 
	// Open input file
//	FILE* in_file = fopen("original_file.ppm","rb"); 
	FILE* in_file = fopen("hackathon.ppm","rb");
	if (in_file==NULL){ 
		printf("File does not exist.");
		return 0;
	} 

	// Read file format, # of pixels in x and y dim, max value for each channel
	char fmt[10];
	char max[10];
	int dimx;
	int dimy;

	fscanf(in_file, "%s", fmt);
	fscanf(in_file, "%d", &dimx);
	fscanf(in_file, "%d", &dimy);
	fscanf(in_file, "%s%*[\n]", max);

	// Allocate memory for array to hold RGB values for all pixels
	unsigned char *rgb_image = (unsigned char*)malloc(dimx*dimy*3*sizeof(unsigned char));

	// Read in pixel data from input file
	fread(rgb_image, dimx*dimy*3, sizeof(unsigned char), in_file);
	fclose(in_file);

	/* Calculate grayscale values based on RGB values and write output file --- */

	// Allocate memory for array to hold grayscale values for all pixels
	unsigned char *gray_image = (unsigned char*)malloc(dimx*dimy*sizeof(unsigned char));

	// Allocate GPU memory
	unsigned char *d_rgb_image, *d_gray_image;
	cudaErrorCheck( cudaMalloc(&d_rgb_image, dimx*dimy*3*sizeof(unsigned char)) );
	cudaErrorCheck( cudaMalloc(&d_gray_image, dimx*dimy*sizeof(unsigned char)) );

	cudaErrorCheck( cudaMemcpy(d_rgb_image, rgb_image, dimx*dimy*3*sizeof(unsigned char), cudaMemcpyHostToDevice) );

  // Set execution configuration parameters
  //    thr_per_blk: number of CUDA threads per grid block
  //    blk_in_grid: number of blocks in grid
  int thr_per_blk = 256;
  int blk_in_grid = ceil( float(dimx*dimy) / thr_per_blk );

  // Launch kernel
  convert_to_gray<<< blk_in_grid, thr_per_blk >>>(d_rgb_image, d_gray_image, dimx, dimy);

  // Check for errors in kernel launch (e.g. invalid execution configuration paramters)
  cudaError_t cuErrSync  = cudaGetLastError();

  // Check for errors on the GPU after control is returned to CPU
  cudaError_t cuErrAsync = cudaDeviceSynchronize();

  if (cuErrSync != cudaSuccess) { printf("CUDA Error - %s:%d: '%s'\n", __FILE__, __LINE__, cudaGetErrorString(cuErrSync)); exit(0); }
  if (cuErrAsync != cudaSuccess) { printf("CUDA Error - %s:%d: '%s'\n", __FILE__, __LINE__, cudaGetErrorString(cuErrAsync)); exit(0); }

	cudaErrorCheck( cudaMemcpy(gray_image, d_gray_image, dimx*dimy, cudaMemcpyDeviceToHost) );

  // Write pixels to PGM P5 formatted file
  FILE *out_file = fopen("output.pgm", "wb");
  fprintf(out_file, "P5\n%d %d\n%d\n", dimx, dimy, 255);
  fwrite(gray_image, sizeof(unsigned char), dimx*dimy, out_file);
  fclose(out_file);

	cudaErrorCheck( cudaFree(d_rgb_image) );
	cudaErrorCheck( cudaFree(d_gray_image) );

	free(rgb_image);
	free(gray_image);
 
  printf("\n---------------------------\n");
  printf("__SUCCESS__\n");
  printf("---------------------------\n");
  printf("dimx              = %d\n", dimx);
  printf("dimy              = %d\n", dimy);
  printf("Threads Per Block = %d\n", thr_per_blk);
  printf("Blocks In Grid    = %d\n", blk_in_grid);
  printf("---------------------------\n\n");
 
	return 0; 
} 
